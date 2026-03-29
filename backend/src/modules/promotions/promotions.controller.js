import { pool } from '../../db/pool.js';
import { readFileSync, existsSync } from 'fs';
import { join } from 'path';
import crypto from 'crypto';

// GET /api/promotions/stats — Dashboard stats
export async function getStatsHandler(req, res, next) {
  try {
    const [promoRes, voucherRes, studentRes, usedRes] = await Promise.all([
      pool.query("SELECT COUNT(*) as total FROM promotions"),
      pool.query("SELECT COUNT(*) as total FROM vouchers"),
      pool.query("SELECT status, COUNT(*) as cnt FROM student_verifications GROUP BY status"),
      pool.query("SELECT COUNT(*) as total FROM promotion_usage")
    ]);

    const studentStats = {};
    for (const row of studentRes.rows) {
      studentStats[row.status] = parseInt(row.cnt);
    }

    res.json({
      totalPromotions: parseInt(promoRes.rows[0]?.total ?? 0),
      totalVouchers: parseInt(voucherRes.rows[0]?.total ?? 0),
      totalUsed: parseInt(usedRes.rows[0]?.total ?? 0),
      studentVerifications: {
        pending: studentStats.pending || 0,
        approved: studentStats.approved || 0,
        rejected: studentStats.rejected || 0
      }
    });
  } catch (err) {
    next(err);
  }
}

// GET /api/promotions — List promotions
export async function listPromotionsHandler(req, res, next) {
  try {
    const result = await pool.query(`
      SELECT p.*, 
        (SELECT COUNT(*) FROM vouchers v WHERE v.promotion_id = p.id) as voucher_count,
        (SELECT COUNT(*) FROM promotion_usage pu 
         JOIN vouchers v2 ON v2.id = pu.voucher_id 
         WHERE v2.promotion_id = p.id) as used_count
      FROM promotions p
      ORDER BY p.created_at DESC
      LIMIT 100
    `);
    res.json(result.rows);
  } catch (err) {
    next(err);
  }
}

// POST /api/promotions — Create promotion + auto-gen vouchers
export async function createPromotionHandler(req, res, next) {
  const client = await pool.connect();
  try {
    const { title, discount_type, discount_value, target_group, voucher_count, starts_at, expires_at } = req.body;

    if (!title || !discount_type || !discount_value) {
      return res.status(400).json({ message: 'title, discount_type, discount_value required' });
    }

    await client.query('BEGIN');

    const promoRes = await client.query(`
      INSERT INTO promotions (name, target_audience, discount_type, discount_value, starts_at, expires_at)
      VALUES ($1, $2, $3, $4, $5, $6)
      RETURNING *
    `, [title, target_group || 'All', discount_type, discount_value, starts_at || new Date(), expires_at]);

    const promotion = promoRes.rows[0];
    const count = Math.min(parseInt(voucher_count) || 10, 500);
    const vouchers = [];

    for (let i = 0; i < count; i++) {
      const code = `LUCKY-${crypto.randomBytes(4).toString('hex').toUpperCase()}`;
      const vRes = await client.query(`
        INSERT INTO vouchers (promotion_id, code)
        VALUES ($1, $2)
        RETURNING *
      `, [promotion.id, code]);
      vouchers.push(vRes.rows[0]);
    }

    await client.query('COMMIT');

    res.status(201).json({ promotion, vouchers_generated: vouchers.length });
  } catch (err) {
    await client.query('ROLLBACK');
    next(err);
  } finally {
    client.release();
  }
}

// PUT /api/promotions/:id — Update promotion
export async function updatePromotionHandler(req, res, next) {
  try {
    const { id } = req.params;
    const { title, discount_type, discount_value, target_group, starts_at, expires_at } = req.body;

    const result = await pool.query(`
      UPDATE promotions 
      SET name = COALESCE($1, name), 
          discount_type = COALESCE($2, discount_type), 
          discount_value = COALESCE($3, discount_value),
          target_audience = COALESCE($4, target_audience),
          starts_at = COALESCE($5, starts_at), 
          expires_at = COALESCE($6, expires_at)
      WHERE id = $7
      RETURNING *
    `, [title, discount_type, discount_value, target_group, starts_at, expires_at, id]);

    if (!result.rows.length) {
      return res.status(404).json({ message: 'Promotion not found' });
    }

    res.json(result.rows[0]);
  } catch (err) {
    next(err);
  }
}

// DELETE /api/promotions/:id — Delete promotion
export async function deletePromotionHandler(req, res, next) {
  try {
    const { id } = req.params;
    const result = await pool.query('DELETE FROM promotions WHERE id = $1 RETURNING id', [id]);

    if (!result.rows.length) {
      return res.status(404).json({ message: 'Promotion not found' });
    }

    res.json({ message: 'Deleted', id: parseInt(id) });
  } catch (err) {
    next(err);
  }
}

// GET /api/promotions/segments — Pre-computed cluster results
export async function getSegmentsHandler(req, res, next) {
  try {
    const filePath = join(process.cwd(), '..', 'scripts', 'cluster_results.json');

    if (!existsSync(filePath)) {
      return res.json({
        clusters: [
          { id: 0, name: 'Student Budget', count: 0, avg_spending: 0, churn_risk: 0 },
          { id: 1, name: 'Active Spender', count: 0, avg_spending: 0, churn_risk: 0 },
          { id: 2, name: 'Casual User', count: 0, avg_spending: 0, churn_risk: 0 }
        ],
        churn_users: [],
        total_churn: 0,
        message: 'Run clustering_analysis.py to generate segment data'
      });
    }

    const data = JSON.parse(readFileSync(filePath, 'utf-8'));
    res.json(data);
  } catch (err) {
    next(err);
  }
}
