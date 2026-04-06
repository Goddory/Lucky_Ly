import { pool } from '../../db/pool.js';
import * as XLSX from 'xlsx';
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

export async function getMarketItems(filters = {}) {
  let query = `
    SELECT item_id, item_name, category, effect_type, price, stock,
           thumbnail_url, description, is_active, created_at
    FROM store_items
    WHERE stock > 0
  `;
  const params = [];
  let paramIdx = 1;

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

export async function buyItem(userId, itemId) {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    // 1) Get item using lock
    const itemRes = await client.query('SELECT * FROM store_items WHERE item_id = $1 FOR UPDATE', [itemId]);
    if (itemRes.rowCount === 0) throw new Error('Item not found');
    const item = itemRes.rows[0];

    if (item.stock <= 0) throw new Error('Sản phẩm đã hết hàng');
    
    // 2) Get user wallet, create if not tracking
    await client.query(
      `INSERT INTO wallets (user_id, balance, currency, status)
       VALUES ($1, 0, 'VND', 'ACTIVE')
       ON CONFLICT (user_id) DO NOTHING`,
      [userId]
    );

    const walletRes = await client.query('SELECT balance FROM wallets WHERE user_id = $1 FOR UPDATE', [userId]);
    const balance = Number(walletRes.rows[0]?.balance ?? 0);

    if (balance < item.price) {
      throw new Error(`Số dư không đủ. Bạn cần ${item.price.toLocaleString('vi-VN')}đ để mua vật phẩm này.`);
    }

    // 3) Deduct balance
    await client.query(
      'UPDATE wallets SET balance = balance - $1 WHERE user_id = $2',
      [item.price, userId]
    );

    // 4) Reduce stock
    await client.query('UPDATE store_items SET stock = stock - 1 WHERE item_id = $1', [itemId]);

    // 5) Record transaction history
    const orderId = `BUY_${Date.now()}`;
    await client.query(
      `INSERT INTO transactions (sender_id, receiver_id, order_id, amount, provider, status, tx_type, note)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`,
      [userId, item.created_by, orderId, item.price, 'wallet', 'success', 'purchase', `Mua ${item.item_name}`]
    );

    // 6) Add item to user's designs/inventory
    const designType = item.category.toLowerCase().includes('sticker') ? 'sticker' : 'model';
    await client.query(
      `INSERT INTO designs (user_id, name, type, image_url, config)
       VALUES ($1, $2, $3, $4, $5)`,
      [userId, item.item_name, designType, item.thumbnail_url, JSON.stringify({ source: 'store_purchase', itemId: item.item_id })]
    );

    // 7) Add to store revenue logic
    await client.query(
      `INSERT INTO store_transactions (buyer_id, total_amount, items) VALUES ($1, $2, $3)`,
      [userId, item.price, JSON.stringify([{ id: item.item_id, name: item.item_name, price: item.price }])]
    );

    // Transfer money to creator's wallet
    await client.query(
      `INSERT INTO wallets (user_id, balance, currency, status)
       VALUES ($1, 0, 'VND', 'ACTIVE')
       ON CONFLICT (user_id) DO NOTHING`,
      [item.created_by]
    );
    await client.query(
      'UPDATE wallets SET balance = balance + $1 WHERE user_id = $2',
      [item.price, item.created_by]
    );

    await client.query('COMMIT');
    return { success: true, item, orderId };
  } catch (err) {
    await client.query('ROLLBACK');
    return { success: false, message: err.message };
  } finally {
    client.release();
  }
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
    const csvPath = join(__dirname, '..', '..', '..', '..', 'datasets', 'Store Dataset', 'retail_sales.csv');
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
  const csvPath = join(__dirname, '..', '..', '..', '..', 'datasets', 'Store Dataset', 'luckyly_store_inventory.csv');
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

  const revenueStats = await pool.query(
    `SELECT COALESCE(SUM(total_amount), 0) as total_revenue,
            COUNT(*) as total_orders
     FROM store_transactions`
  );

  const comboCount = await pool.query('SELECT COUNT(*) as count FROM store_combos');

  return {
    totalItems: parseInt(itemCount.rows[0].count),
    totalStock: parseInt(totalStock.rows[0].total),
    categories: categoryCount.rows,
    recentItems: recentItems.rows,
    totalRevenue: parseFloat(revenueStats.rows[0].total_revenue || 0),
    totalOrders: parseInt(revenueStats.rows[0].total_orders || 0),
    totalCombos: parseInt(comboCount.rows[0].count || 0)
  };
}

export async function importFromExcel(userId, filePath) {
  const workbook = XLSX.readFile(filePath);
  const sheetName = workbook.SheetNames[0];
  const sheet = workbook.Sheets[sheetName];
  const data = XLSX.utils.sheet_to_json(sheet);

  const errors = [];
  let successCount = 0;

  for (const row of data) {
    try {
      const itemName = row['Tên vật phẩm'] || row['item_name'] || row['itemName'];
      const category = row['Danh mục'] || row['category'] || 'Sticker';
      const price = parseFloat(row['Giá'] || row['price'] || 0);
      const stock = parseInt(row['Số lượng'] || row['stock'] || 0);
      const description = row['Mô tả'] || row['description'] || '';

      if (!itemName) {
        errors.push(`Bỏ qua hàng không có tên vật phẩm: ${JSON.stringify(row)}`);
        continue;
      }

      await createItem({
        itemName,
        category,
        price,
        stock,
        description,
        userId
      });
      successCount++;
    } catch (err) {
      errors.push(`Lỗi nhập hàng "${row['Tên vật phẩm'] || 'Unknown'}": ${err.message}`);
    }
  }

  return { count: successCount, errors };
}

// ========== CART SYSTEM ==========

export async function getCart(userId) {
  const query = `
    SELECT c.user_id, c.item_id, c.quantity, c.created_at,
           i.item_name, i.category, i.price, i.thumbnail_url, i.stock
    FROM store_carts c
    JOIN store_items i ON c.item_id = i.item_id
    WHERE c.user_id = $1
    ORDER BY c.created_at DESC
  `;
  const { rows } = await pool.query(query, [userId]);
  return rows;
}

export async function addToCart(userId, itemId) {
  // Check if item exists and in stock
  const { rows: itemRows } = await pool.query('SELECT stock FROM store_items WHERE item_id = $1', [itemId]);
  if (itemRows.length === 0) throw new Error('Vật phẩm không tồn tại');
  if (itemRows[0].stock <= 0) throw new Error('Vật phẩm đã hết hàng');

  const { rows } = await pool.query(
    `INSERT INTO store_carts (user_id, item_id, quantity)
     VALUES ($1, $2, 1)
     ON CONFLICT (user_id, item_id) DO NOTHING
     RETURNING *`,
    [userId, itemId]
  );
  return rows[0] || { message: 'Đã có trong giỏ hàng' };
}

export async function removeFromCart(userId, itemId) {
  await pool.query('DELETE FROM store_carts WHERE user_id = $1 AND item_id = $2', [userId, itemId]);
  return true;
}

const OPEN_AUDIENCES = new Set(['all', 'user', 'users', 'normal', 'general', 'public']);
const STUDENT_AUDIENCES = new Set(['student', 'students', 'sv', 'sinh vien', 'sinhvien']);

function normalizeAudience(value) {
  return String(value ?? 'all').trim().toLowerCase();
}

function resolveDiscountAmount(totalAmount, discountType, discountValue) {
  const normalizedType = String(discountType ?? '').trim().toLowerCase();
  const parsedValue = Number(discountValue ?? 0);

  if (!Number.isFinite(parsedValue) || parsedValue <= 0 || totalAmount <= 0) {
    return 0;
  }

  const rawDiscount = normalizedType === 'percent'
    ? (totalAmount * parsedValue) / 100
    : parsedValue;

  const roundedDiscount = Math.round(rawDiscount);
  return Math.max(0, Math.min(totalAmount, roundedDiscount));
}

async function resolveVoucherForCheckout(client, { userId, voucherCode, totalAmount }) {
  const normalizedCode = String(voucherCode ?? '').trim();
  if (!normalizedCode) {
    return null;
  }

  const userResult = await client.query(
    'SELECT student_id FROM users WHERE user_id = $1 LIMIT 1',
    [userId],
  );

  if (!userResult.rows.length) {
    throw new Error('Không tìm thấy người dùng để áp mã giảm giá.');
  }

  const isStudentVerified = Boolean(
    userResult.rows[0].student_id && String(userResult.rows[0].student_id).trim(),
  );

  const voucherResult = await client.query(
    `SELECT
        v.id AS voucher_id,
        v.code,
        v.current_uses,
        v.max_uses,
        p.id AS promotion_id,
        p.name AS promotion_name,
        p.target_audience,
        p.discount_type,
        p.discount_value
     FROM vouchers v
     JOIN promotions p ON p.id = v.promotion_id
     WHERE UPPER(v.code) = UPPER($1)
       AND v.current_uses < v.max_uses
       AND (p.starts_at IS NULL OR p.starts_at <= NOW())
       AND (p.expires_at IS NULL OR p.expires_at >= NOW())
     FOR UPDATE`,
    [normalizedCode],
  );

  if (!voucherResult.rows.length) {
    throw new Error('Mã giảm giá không hợp lệ hoặc đã hết lượt sử dụng.');
  }

  const voucher = voucherResult.rows[0];
  const audience = normalizeAudience(voucher.target_audience);
  if (STUDENT_AUDIENCES.has(audience) && !isStudentVerified) {
    throw new Error('Mã giảm giá này chỉ dành cho tài khoản sinh viên đã xác thực.');
  }
  if (!OPEN_AUDIENCES.has(audience) && !STUDENT_AUDIENCES.has(audience)) {
    throw new Error('Mã giảm giá không áp dụng cho tài khoản hiện tại.');
  }

  const discountAmount = resolveDiscountAmount(
    totalAmount,
    voucher.discount_type,
    voucher.discount_value,
  );

  if (discountAmount <= 0) {
    throw new Error('Mã giảm giá không hợp lệ cho đơn hàng hiện tại.');
  }

  return {
    voucherId: voucher.voucher_id,
    code: voucher.code,
    promotionId: voucher.promotion_id,
    promotionName: voucher.promotion_name,
    discountType: voucher.discount_type,
    discountValue: Number(voucher.discount_value ?? 0),
    discountAmount,
  };
}

export async function checkoutCart(userId, itemIds, voucherCode) {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    const normalizedItemIds = Array.isArray(itemIds)
      ? [...new Set(itemIds.map((itemId) => String(itemId).trim()).filter(Boolean))]
      : [];

    if (!normalizedItemIds.length) {
      throw new Error('Vui lòng chọn ít nhất 1 sản phẩm để thanh toán.');
    }
    
    // Lock all purchasing items
    const { rows: items } = await client.query(
      'SELECT * FROM store_items WHERE item_id = ANY($1) FOR UPDATE',
      [normalizedItemIds]
    );

    if (items.length !== normalizedItemIds.length) {
      throw new Error('Một số vật phẩm không còn tồn tại hoặc không hợp lệ.');
    }

    let totalAmount = 0;
    for (const item of items) {
      if (item.stock <= 0) {
        throw new Error(`Sản phẩm ${item.item_name} đã hết hàng.`);
      }
      totalAmount += Number(item.price);
    }

    const voucher = await resolveVoucherForCheckout(client, {
      userId,
      voucherCode,
      totalAmount,
    });

    const discountAmount = voucher?.discountAmount ?? 0;
    const finalAmount = Math.max(0, totalAmount - discountAmount);

    // Lock user wallet and check
    await client.query(
      `INSERT INTO wallets (user_id, balance, currency, status) VALUES ($1, 0, 'VND', 'ACTIVE') ON CONFLICT (user_id) DO NOTHING`,
      [userId]
    );
    const { rows: walletRows } = await client.query('SELECT balance FROM wallets WHERE user_id = $1 FOR UPDATE', [userId]);
    const balance = Number(walletRows[0]?.balance ?? 0);

    if (balance < finalAmount) {
      throw new Error(`Số dư không đủ. Cần ${finalAmount.toLocaleString('vi-VN')}đ.`);
    }

    // Deduct user wallet overall
    await client.query('UPDATE wallets SET balance = balance - $1 WHERE user_id = $2', [finalAmount, userId]);

    let remainingPayableAmount = finalAmount;
    const payableAmounts = items.map((item, index) => {
      if (!voucher || totalAmount <= 0) {
        return Number(item.price);
      }

      if (index === items.length - 1) {
        return Math.max(0, remainingPayableAmount);
      }

      const proportionalAmount = Math.round((finalAmount * Number(item.price)) / totalAmount);
      const safeAmount = Math.max(0, proportionalAmount);
      remainingPayableAmount -= safeAmount;
      return safeAmount;
    });

    // Process each item individually to separate rows in transaction history
    for (let index = 0; index < items.length; index++) {
      const item = items[index];
      const payablePrice = payableAmounts[index];

      // Reduce stock
      await client.query('UPDATE store_items SET stock = stock - 1 WHERE item_id = $1', [item.item_id]);

      // Record transaction history for buyer
      const orderId = `CART_${Date.now()}_${String(item.item_id).substring(0, 4)}`;
      const noteSuffix = voucher ? ` (Áp mã ${voucher.code})` : '';
      await client.query(
        `INSERT INTO transactions (sender_id, receiver_id, order_id, amount, provider, status, tx_type, note)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`,
        [userId, item.created_by, orderId, payablePrice, 'wallet', 'success', 'purchase', `Mua ${item.item_name}${noteSuffix}`]
      );

      // Detailed store metrics entry
      await client.query(
        `INSERT INTO store_transactions (buyer_id, total_amount, items) VALUES ($1, $2, $3)`,
        [
          userId,
          payablePrice,
          JSON.stringify([
            {
              id: item.item_id,
              name: item.item_name,
              original_price: Number(item.price),
              payable_price: payablePrice,
            },
          ]),
        ]
      );

      // Sync item mapping to inventory workspace
      const lcCat = item.category.toLowerCase();
      const designType = (lcCat.includes('thiệp') || lcCat.includes('sticker') || lcCat.includes('hiệu ứng') || lcCat.includes('trang trí')) ? 'sticker' : 'model';
      await client.query(
        `INSERT INTO designs (user_id, name, type, image_url, config) VALUES ($1, $2, $3, $4, $5)`,
        [userId, item.item_name, designType, item.thumbnail_url, JSON.stringify({ source: 'cart_checkout', itemId: item.item_id })]
      );

      // Credit to creator bucket
      await client.query(
        `INSERT INTO wallets (user_id, balance, currency, status) VALUES ($1, 0, 'VND', 'ACTIVE') ON CONFLICT (user_id) DO NOTHING`,
        [item.created_by]
      );
      await client.query('UPDATE wallets SET balance = balance + $1 WHERE user_id = $2', [payablePrice, item.created_by]);
    }

    if (voucher) {
      const updateVoucherResult = await client.query(
        `UPDATE vouchers
         SET current_uses = current_uses + 1
         WHERE id = $1
           AND current_uses < max_uses`,
        [voucher.voucherId],
      );

      if (updateVoucherResult.rowCount === 0) {
        throw new Error('Mã giảm giá đã hết lượt sử dụng.');
      }
    }

    // Clear bought items from cart
    await client.query('DELETE FROM store_carts WHERE user_id = $1 AND item_id = ANY($2)', [userId, normalizedItemIds]);

    await client.query('COMMIT');
    return {
      success: true,
      totalAmount,
      discountAmount,
      finalAmount,
      totalItems: items.length,
      appliedVoucher: voucher
        ? {
            code: voucher.code,
            promotionName: voucher.promotionName,
            discountType: voucher.discountType,
            discountValue: voucher.discountValue,
          }
        : null,
    };
  } catch (err) {
    await client.query('ROLLBACK');
    return { success: false, message: err.message };
  } finally {
    client.release();
  }
}
