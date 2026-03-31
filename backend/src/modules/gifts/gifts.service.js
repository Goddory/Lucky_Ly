import { pool } from '../../db/pool.js';
import crypto from 'crypto';

export const createGift = async (senderId, giftData) => {
  const { receiverEmail, theme, modelId, stickers, message, cashAmount = 0 } = giftData;
  const numCash = Number(cashAmount);
  
  if (numCash > 0 && numCash < 1000) {
    const err = new Error('Số tiền gửi tối thiểu là 1.000đ');
    err.statusCode = 400;
    throw err;
  }

  const normalizedReceiverEmail = receiverEmail.trim().toLowerCase();
  const client = await pool.connect();
  
  try {
    await client.query('BEGIN');

    if (numCash > 0) {
      // 1) Verify and deduct from sender's wallet
      const walletRes = await client.query('SELECT balance FROM wallets WHERE user_id = $1 FOR UPDATE', [senderId]);
      if (walletRes.rowCount === 0) throw new Error('Không tìm thấy ví người gửi');
      const balance = Number(walletRes.rows[0].balance);
      
      if (balance < numCash) {
        const err = new Error('Số dư không đủ để gửi quà đính kèm tiền');
        err.statusCode = 400;
        throw err;
      }
      
      await client.query('UPDATE wallets SET balance = balance - $1 WHERE user_id = $2', [numCash, senderId]);
      
      // 2) Record transaction
      const orderId = `GIFT_SEND_${Date.now()}_${senderId.slice(0, 8)}`;
      await client.query(
        `INSERT INTO transactions (sender_id, amount, order_id, status, tx_type, note, provider)
         VALUES ($1, $2, $3, 'success', 'purchase', $4, 'wallet')`,
        [senderId, numCash, orderId, `Gửi quà kèm ${numCash.toLocaleString()}đ cho ${normalizedReceiverEmail}`]
      );
    }

    // 3) Create gift
    const query = `
      INSERT INTO gifts (sender_id, receiver_email, theme, model_id, stickers, message, status, cash_amount)
      VALUES ($1, $2, $3, $4, $5, $6, 'pending', $7)
      RETURNING *;
    `;
    const values = [senderId, normalizedReceiverEmail, theme, modelId, JSON.stringify(stickers || []), message, numCash];
    const { rows } = await client.query(query, values);
    
    await client.query('COMMIT');
    return rows[0];
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
};

export const createGiftLink = async (senderId, giftData) => {
  const { itemType, amount, maxReceivers, message } = giftData;

  if (!itemType) {
    const err = new Error('itemType is required');
    err.statusCode = 400;
    throw err;
  }

  const qrToken = crypto.randomUUID();
  const expiresAt = new Date(Date.now() + 24 * 60 * 60 * 1000);

  const { rows } = await pool.query(
    `INSERT INTO gifts (sender_id, item_type, amount, max_receivers, qr_token, expires_at, message)
     VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING *`,
    [senderId, itemType, amount || 1, maxReceivers || 1, qrToken, expiresAt, message || null]
  );

  const gift = rows[0];
  gift.deep_link = `luckyly://gift/claim/${qrToken}`;
  await pool.query(`UPDATE gifts SET deep_link = $1 WHERE id = $2`, [gift.deep_link, gift.id]);

  return { ...gift, deep_link: gift.deep_link };
};

export const claimGift = async (qrToken, receiverId) => {
  const giftResult = await pool.query(
    `SELECT * FROM gifts WHERE qr_token = $1 LIMIT 1`,
    [qrToken]
  );

  if (giftResult.rowCount === 0) {
    const err = new Error('Gift not found');
    err.statusCode = 404;
    throw err;
  }

  const gift = giftResult.rows[0];

  if (gift.is_cancelled) {
    const err = new Error('This gift has been cancelled by the sender');
    err.statusCode = 410;
    throw err;
  }

  if (new Date() > new Date(gift.expires_at)) {
    const err = new Error('This gift link has expired (24h)');
    err.statusCode = 410;
    throw err;
  }

  if (gift.sender_id === receiverId) {
    const err = new Error('You cannot claim your own gift');
    err.statusCode = 400;
    throw err;
  }

  if (gift.current_receivers >= gift.max_receivers) {
    const err = new Error('This gift has reached the maximum number of receivers');
    err.statusCode = 409;
    throw err;
  }

  const alreadyClaimed = await pool.query(
    `SELECT 1 FROM gift_receivers WHERE gift_id = $1 AND receiver_id = $2 LIMIT 1`,
    [gift.id, receiverId]
  );
  if (alreadyClaimed.rowCount > 0) {
    const err = new Error('You have already claimed this gift');
    err.statusCode = 409;
    throw err;
  }

  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    await client.query(
      `INSERT INTO gift_receivers (gift_id, receiver_id) VALUES ($1, $2)`,
      [gift.id, receiverId]
    );

    await client.query(
      `UPDATE gifts SET current_receivers = current_receivers + 1 WHERE id = $1`,
      [gift.id]
    );

    await client.query('COMMIT');
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }

  return { giftId: gift.id, itemType: gift.item_type, amount: gift.amount, senderId: gift.sender_id };
};

export const cancelGift = async (giftId, senderId) => {
  const { rows } = await pool.query(
    `UPDATE gifts SET is_cancelled = TRUE
     WHERE id = $1 AND sender_id = $2 AND is_cancelled = FALSE AND current_receivers = 0
     RETURNING *`,
    [giftId, senderId]
  );

  if (rows.length === 0) {
    const err = new Error('Gift not found, not yours, already cancelled, or already claimed');
    err.statusCode = 400;
    throw err;
  }

  return rows[0];
};

export const getGiftByToken = async (token) => {
  const { rows } = await pool.query(
    `SELECT g.*, u.username AS sender_name, u.avatar_url AS sender_avatar
     FROM gifts g
     JOIN users u ON g.sender_id = u.user_id
     WHERE g.qr_token = $1 LIMIT 1`,
    [token]
  );
  return rows[0] || null;
};

export const getReceivedGifts = async (userEmail) => {
  const query = `
    SELECT g.*, u.username AS sender_name, u.avatar_url AS sender_avatar
    FROM gifts g
    LEFT JOIN users u ON g.sender_id = u.user_id
    WHERE LOWER(g.receiver_email) = LOWER($1)
    ORDER BY g.created_at DESC;
  `;
  const { rows } = await pool.query(query, [userEmail]);
  return rows;
};

export const getSentGifts = async (senderId) => {
  const query = `
    SELECT g.*, u.email AS receiver_display
    FROM gifts g
    LEFT JOIN users u ON g.receiver_email = u.email
    WHERE g.sender_id = $1
    ORDER BY g.created_at DESC;
  `;
  const { rows } = await pool.query(query, [senderId]);
  return rows;
};

export const getGiftByIdForUser = async (id, userId, userEmail) => {
  const query = `
    SELECT g.*, u.username AS sender_name, u.avatar_url AS sender_avatar, u.full_name AS sender_full_name
    FROM gifts g
    LEFT JOIN users u ON g.sender_id = u.user_id
    WHERE g.id = $1
      AND (
        g.sender_id = $2
        OR LOWER(g.receiver_email) = LOWER($3)
      );
  `;
  const { rows } = await pool.query(query, [id, userId, userEmail]);
  return rows[0];
};

export const markAsOpened = async (id, userEmail) => {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    
    // 1) Find the gift and lock it
    const giftResult = await client.query(
      `SELECT * FROM gifts WHERE id = $1 AND LOWER(receiver_email) = LOWER($2) AND status = 'pending' FOR UPDATE`,
      [id, userEmail]
    );
    
    if (giftResult.rowCount === 0) {
      await client.query('ROLLBACK');
      return null;
    }
    
    const gift = giftResult.rows[0];
    const cashAmount = Number(gift.cash_amount || 0);
    
    // 2) If there's money, credit the receiver's wallet
    if (cashAmount > 0) {
      // Find receiverId from email
      const userRes = await client.query('SELECT user_id FROM users WHERE LOWER(email) = LOWER($1)', [userEmail]);
      if (userRes.rowCount > 0) {
        const receiverId = userRes.rows[0].user_id;
        
        // Upsert wallet
        await client.query(
          `INSERT INTO wallets (user_id, balance, currency, status) VALUES ($1, 0, 'VND', 'ACTIVE')
           ON CONFLICT (user_id) DO NOTHING`,
          [receiverId]
        );
        
        await client.query('UPDATE wallets SET balance = balance + $1 WHERE user_id = $2', [cashAmount, receiverId]);
        
        // Record transaction
        const orderId = `GIFT_RECV_${Date.now()}_${id}`;
        await client.query(
          `INSERT INTO transactions (sender_id, receiver_id, amount, order_id, status, tx_type, note, provider)
           VALUES ($1, $2, $3, $4, 'success', 'purchase', $5, 'wallet')`,
          [gift.sender_id, receiverId, cashAmount, orderId, `Nhận quà kèm ${cashAmount.toLocaleString()}đ`]
        );
      }
    }
    
    // 3) Mark as opened
    const { rows } = await client.query(
      `UPDATE gifts SET status = 'opened', opened_at = NOW() WHERE id = $1 RETURNING *`,
      [id]
    );
    
    await client.query('COMMIT');
    return rows[0];
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
};

export const countPendingGifts = async (userEmail) => {
  const query = `
    SELECT COUNT(*) AS count
    FROM gifts
    WHERE LOWER(receiver_email) = LOWER($1) AND status = 'pending';
  `;
  const { rows } = await pool.query(query, [userEmail]);
  return parseInt(rows[0].count, 10);
};
