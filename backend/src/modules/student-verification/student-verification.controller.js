import { pool } from '../../db/pool.js';

// GET /api/student-verification — List verifications with optional status filter
export async function listVerificationsHandler(req, res, next) {
  try {
    const { status } = req.query;
    let query = `
      SELECT sv.*, u.username, u.email 
      FROM student_verifications sv
      JOIN users u ON u.user_id = sv.user_id
    `;
    const params = [];

    if (status && ['pending', 'approved', 'rejected'].includes(status)) {
      query += ' WHERE sv.status = $1';
      params.push(status);
    }

    query += ' ORDER BY sv.created_at DESC LIMIT 200';

    const result = await pool.query(query, params);
    res.json(result.rows);
  } catch (err) {
    next(err);
  }
}

// POST /api/student-verification — Submit student card (user-facing)
export async function submitVerificationHandler(req, res, next) {
  try {
    const userId = req.user.userId;
    const { card_image_url, school_name } = req.body;

    if (!card_image_url) {
      return res.status(400).json({ message: 'card_image_url required' });
    }

    // Check existing pending
    const existing = await pool.query(
      "SELECT id FROM student_verifications WHERE user_id = $1 AND status = 'pending'",
      [userId]
    );

    if (existing.rows.length) {
      return res.status(409).json({ message: 'You already have a pending verification' });
    }

    const result = await pool.query(`
      INSERT INTO student_verifications (user_id, card_image_url, school_name)
      VALUES ($1, $2, $3)
      RETURNING *
    `, [userId, card_image_url, school_name || null]);

    res.status(201).json(result.rows[0]);
  } catch (err) {
    next(err);
  }
}

// PUT /api/student-verification/:id/review — Approve/reject (admin)
export async function reviewVerificationHandler(req, res, next) {
  try {
    const { id } = req.params;
    const { status } = req.body;
    const reviewerId = req.user.userId;

    if (!['approved', 'rejected'].includes(status)) {
      return res.status(400).json({ message: 'status must be approved or rejected' });
    }

    const result = await pool.query(`
      UPDATE student_verifications
      SET status = $1, reviewed_by = $2, reviewed_at = NOW()
      WHERE id = $3
      RETURNING *
    `, [status, reviewerId, id]);

    if (!result.rows.length) {
      return res.status(404).json({ message: 'Verification not found' });
    }

    // If approved, update user's student_id field
    if (status === 'approved') {
      const sv = result.rows[0];
      await pool.query(
        "UPDATE users SET student_id = $1 WHERE user_id = $2",
        [`SV-${sv.school_name || 'VERIFIED'}`, sv.user_id]
      );
    }

    res.json(result.rows[0]);
  } catch (err) {
    next(err);
  }
}
