import { pool } from '../../db/pool.js';
import { readFileSync } from 'fs';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';
import { apriori, csvToTransactions, generateComboSuggestions } from './apriori.js';

const __dirname = dirname(fileURLToPath(import.meta.url));

// ========== INVENTORY CRUD ==========

export async function getInventory(filters = {}) {
  let query = `
    SELECT item_id, item_name, category, effect_type, price, stock,
           thumbnail_url, description, is_active, created_at, updated_at
    FROM store_items
    WHERE created_by = $1
  `;
  const params = [filters.userId];
  let paramIdx = 2;

  if (filters.category) {
    query += ` AND category = $${paramIdx++}`;
    params.push(filters.category);
  }
  if (filters.search) {
    query += ` AND item_name ILIKE $${paramIdx++}`;
    params.push(`%${filters.search}%`);
  }

  query += ` ORDER BY created_at DESC`;
  const { rows } = await pool.query(query, params);
  return rows;
}

export async function getItemById(itemId) {
  const { rows } = await pool.query(
    'SELECT * FROM store_items WHERE item_id = $1',
    [itemId]
  );
  return rows[0] || null;
}

export async function createItem(data, file) {
  const assetUrl = file ? `/uploads/store/${file.filename}` : (data.thumbnailUrl || null);
  
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    // 1) Insert into store_items
    const { rows: itemRows } = await client.query(
      `INSERT INTO store_items (item_name, category, effect_type, price, stock, thumbnail_url, description, created_by)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
       RETURNING *`,
      [data.itemName, data.category, data.effectType || 'none', data.price, data.stock || 0,
       assetUrl, data.description || null, data.userId]
    );

    const newItem = itemRows[0];

    // 2) Sync to user inventory (designs table)
    // Mapping: category 'Sticker' -> type 'sticker', 'Model' -> type 'model'
    const designType = data.category.toLowerCase().includes('sticker') ? 'sticker' : 'model';
    
    await client.query(
      `INSERT INTO designs (user_id, name, type, image_url, config)
       VALUES ($1, $2, $3, $4, $5)`,
      [data.userId, data.itemName, designType, assetUrl, JSON.stringify({ source: 'store_creator', itemId: newItem.item_id })]
    );

    await client.query('COMMIT');
    return newItem;
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
}

export async function updateItem(itemId, data) {
  const fields = [];
  const params = [];
  let idx = 1;

  if (data.itemName !== undefined) { fields.push(`item_name = $${idx++}`); params.push(data.itemName); }
  if (data.category !== undefined) { fields.push(`category = $${idx++}`); params.push(data.category); }
  if (data.effectType !== undefined) { fields.push(`effect_type = $${idx++}`); params.push(data.effectType); }
  if (data.price !== undefined) { fields.push(`price = $${idx++}`); params.push(data.price); }
  if (data.stock !== undefined) { fields.push(`stock = $${idx++}`); params.push(data.stock); }
  if (data.thumbnailUrl !== undefined) { fields.push(`thumbnail_url = $${idx++}`); params.push(data.thumbnailUrl); }
  if (data.description !== undefined) { fields.push(`description = $${idx++}`); params.push(data.description); }
  if (data.isActive !== undefined) { fields.push(`is_active = $${idx++}`); params.push(data.isActive); }

  fields.push(`updated_at = NOW()`);

  if (fields.length === 1) return getItemById(itemId);

  params.push(itemId);
  const { rows } = await pool.query(
    `UPDATE store_items SET ${fields.join(', ')} WHERE item_id = $${idx} RETURNING *`,
    params
  );
  return rows[0] || null;
}

export async function deleteItem(itemId) {
  const { rowCount } = await pool.query(
    'DELETE FROM store_items WHERE item_id = $1',
    [itemId]
  );
  return rowCount > 0;
}

// ========== REVENUE & STATS ==========

export async function getRevenueStats(userId) {
  // Tổng doanh thu
  const totalResult = await pool.query(
    `SELECT COALESCE(SUM(total_amount), 0) as total_revenue,
            COUNT(*) as total_orders
     FROM store_transactions
     WHERE buyer_id IN (SELECT user_id FROM users)`,
  );

  // Doanh thu theo ngày (30 ngày gần nhất)
  const dailyResult = await pool.query(
    `SELECT DATE(created_at) as date,
            SUM(total_amount) as revenue,
            COUNT(*) as orders
     FROM store_transactions
     WHERE created_at >= NOW() - INTERVAL '30 days'
     GROUP BY DATE(created_at)
     ORDER BY date`
  );

  // Top sản phẩm bán chạy
  const topProducts = await pool.query(
    `SELECT item_name, category, price, stock,
            (SELECT COUNT(*) FROM store_transactions WHERE items::text ILIKE '%' || item_name || '%') as sold_count
     FROM store_items
     WHERE created_by = $1
     ORDER BY sold_count DESC
     LIMIT 10`,
    [userId]
  );

  // Doanh thu theo category
  const categoryRevenue = await pool.query(
    `SELECT category, COUNT(*) as item_count, SUM(price * stock) as potential_revenue
     FROM store_items
     WHERE created_by = $1
     GROUP BY category
     ORDER BY potential_revenue DESC`,
    [userId]
  );

  return {
    summary: totalResult.rows[0],
    daily: dailyResult.rows,
    topProducts: topProducts.rows,
    categoryBreakdown: categoryRevenue.rows
  };
}

// ========== APRIORI / COMBO ==========

export async function runApriori(minSupport = 0.1, minConfidence = 0.5) {
  // Lấy transactions từ DB
  const { rows: txnRows } = await pool.query(
    `SELECT transaction_id::text, items FROM store_transactions ORDER BY created_at`
  );

  let transactions;

  if (txnRows.length > 0) {
    // Parse JSONB items thành mảng tên sản phẩm
    transactions = txnRows.map((r) => {
      const items = typeof r.items === 'string' ? JSON.parse(r.items) : r.items;
      return items.map((i) => i.name || i.item_name || i);
    });
  } else {
    // Fallback: dùng dataset retail_sales.csv nếu DB trống
    const csvPath = join(__dirname, '..', '..', '..', '..', 'datasets', 'retail_sales.csv');
    try {
      const csvContent = readFileSync(csvPath, 'utf-8');
      const lines = csvContent.trim().split('\n');
      const headers = lines[0].split(',');
      const nameIdx = headers.indexOf('product_name');
      const txnIdx = headers.indexOf('transaction_id');

      const csvRows = lines.slice(1).map((line) => {
        const cols = line.split(',');
        return { transaction_id: cols[txnIdx], product_name: cols[nameIdx] };
      });

      transactions = csvToTransactions(csvRows);
    } catch {
      return { frequentItemsets: [], rules: [], combos: [] };
    }
  }

  const result = apriori(transactions, minSupport, minConfidence);
  const combos = generateComboSuggestions(result.rules);

  return {
    frequentItemsets: result.frequentItemsets,
    rules: result.rules,
    combos,
    transactionCount: transactions.length
  };
}

export async function getSavedCombos() {
  const { rows } = await pool.query(
    `SELECT * FROM store_combos ORDER BY lift DESC, confidence DESC`
  );
  return rows;
}

export async function saveCombo(comboData) {
  const { rows } = await pool.query(
    `INSERT INTO store_combos (items, support, confidence, lift, bundle_name, discount_percent, is_active)
     VALUES ($1, $2, $3, $4, $5, $6, $7)
     RETURNING *`,
    [
      JSON.stringify(comboData.items),
      comboData.support,
      comboData.confidence,
      comboData.lift,
      comboData.bundleName,
      comboData.discountPercent || 10,
      comboData.isActive || false
    ]
  );
  return rows[0];
}

// ========== DATASET LOADING ==========

export async function loadDatasetToInventory(userId) {
  const csvPath = join(__dirname, '..', '..', '..', '..', 'datasets', 'luckyly_store_inventory.csv');
  const csvContent = readFileSync(csvPath, 'utf-8');
  const lines = csvContent.trim().split('\n');
  const headers = lines[0].split(',');

  const items = lines.slice(1).map((line) => {
    const cols = line.split(',');
    const row = {};
    headers.forEach((h, i) => { row[h] = cols[i]; });
    return row;
  });

  const inserted = [];
  for (const item of items) {
    const existing = await pool.query(
      'SELECT 1 FROM store_items WHERE item_name = $1 AND created_by = $2',
      [item.item_name, userId]
    );

    if (existing.rowCount === 0) {
      const result = await pool.query(
        `INSERT INTO store_items (item_name, category, effect_type, price, stock, created_by)
         VALUES ($1, $2, $3, $4, $5, $6) RETURNING *`,
        [item.item_name, item.category, item.effect_type, parseFloat(item.price_vnd), parseInt(item.total_created), userId]
      );
      inserted.push(result.rows[0]);
    }
  }

  return { inserted: inserted.length, total: items.length };
}

// ========== OVERVIEW STATS ==========

export async function getOverviewStats(userId) {
  const itemCount = await pool.query(
    'SELECT COUNT(*) as count FROM store_items WHERE created_by = $1',
    [userId]
  );

  const categoryCount = await pool.query(
    'SELECT category, COUNT(*) as count FROM store_items WHERE created_by = $1 GROUP BY category',
    [userId]
  );

  const totalStock = await pool.query(
    'SELECT COALESCE(SUM(stock), 0) as total FROM store_items WHERE created_by = $1',
    [userId]
  );

  const recentItems = await pool.query(
    `SELECT item_id, item_name, category, price, stock, effect_type, created_at
     FROM store_items WHERE created_by = $1
     ORDER BY created_at DESC LIMIT 5`,
    [userId]
  );

  return {
    totalItems: parseInt(itemCount.rows[0].count),
    totalStock: parseInt(totalStock.rows[0].total),
    categories: categoryCount.rows,
    recentItems: recentItems.rows
  };
}
