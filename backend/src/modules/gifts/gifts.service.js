import { pool } from '../../db/pool.js';
import crypto from 'crypto';

const GIFT_CLAIM_WINDOW_HOURS = 24;
const GIFT_CLAIM_WINDOW_MS = GIFT_CLAIM_WINDOW_HOURS * 60 * 60 * 1000;

let schemaEnsurePromise = null;

export const ensureGiftCashflowSchema = async () => {
  if (!schemaEnsurePromise) {
    schemaEnsurePromise = pool.query(`
      ALTER TABLE gifts ADD COLUMN IF NOT EXISTS cash_amount NUMERIC(18,2) NOT NULL DEFAULT 0;
      ALTER TABLE gifts ADD COLUMN IF NOT EXISTS opened_at TIMESTAMPTZ;
      ALTER TABLE gifts ADD COLUMN IF NOT EXISTS claimed_at TIMESTAMPTZ;
      ALTER TABLE gifts ADD COLUMN IF NOT EXISTS refunded_at TIMESTAMPTZ;
      ALTER TABLE gifts ADD COLUMN IF NOT EXISTS receiver_email VARCHAR(255);
      ALTER TABLE gifts ADD COLUMN IF NOT EXISTS theme VARCHAR(20);
      ALTER TABLE gifts ADD COLUMN IF NOT EXISTS model_id VARCHAR(100);
      ALTER TABLE gifts ADD COLUMN IF NOT EXISTS stickers JSONB DEFAULT '[]';
      ALTER TABLE gifts ADD COLUMN IF NOT EXISTS message TEXT;
    `).catch((error) => {
      schemaEnsurePromise = null;
      throw error;
    });
  }

  await schemaEnsurePromise;
};

const getGiftCashAmount = (gift) => Number(gift?.cash_amount || 0);

const parseOpenedAt = (gift) => {
  if (!gift?.opened_at) return null;
  const openedAt = new Date(gift.opened_at);
  return Number.isNaN(openedAt.getTime()) ? null : openedAt;
};

const isClaimWindowExpired = (gift) => {
  const openedAt = parseOpenedAt(gift);
  if (!openedAt) return false;
  return (Date.now() - openedAt.getTime()) >= GIFT_CLAIM_WINDOW_MS;
};

const ensureWalletExists = async (client, userId) => {
  await client.query(
    `INSERT INTO wallets (user_id, balance, currency, status) VALUES ($1, 0, 'VND', 'ACTIVE')
     ON CONFLICT (user_id) DO NOTHING`,
    [userId]
  );
};

const recordGiftTransaction = async (client, {
  senderId,
  receiverId = null,
  amount,
  txType,
  note,
  orderPrefix,
  giftId,
}) => {
  const orderId = `${orderPrefix}_${Date.now()}_${giftId}`;
  await client.query(
    `INSERT INTO transactions (sender_id, receiver_id, amount, order_id, status, tx_type, note, provider)
     VALUES ($1, $2, $3, $4, 'success', $5, $6, 'wallet')`,
    [senderId, receiverId, amount, orderId, txType, note]
  );
};

const refundGiftAmountLocked = async (client, gift) => {
  if (gift.claimed_at || gift.refunded_at) return gift;

  const cashAmount = getGiftCashAmount(gift);
  if (cashAmount <= 0) return gift;

  await ensureWalletExists(client, gift.sender_id);
  await client.query('UPDATE wallets SET balance = balance + $1 WHERE user_id = $2', [cashAmount, gift.sender_id]);

  await recordGiftTransaction(client, {
    senderId: gift.sender_id,
    receiverId: null,
    amount: cashAmount,
    txType: 'gift_refund',
    note: `Hoàn tiền quà #${gift.id} sau ${GIFT_CLAIM_WINDOW_HOURS}h không nhận`,
    orderPrefix: 'GIFT_REFUND',
    giftId: gift.id,
  });

  const { rows } = await client.query(
    `UPDATE gifts
     SET refunded_at = NOW()
     WHERE id = $1
     RETURNING *`,
    [gift.id]
  );

  return rows[0];
};

export const createGift = async (senderId, giftData) => {
  await ensureGiftCashflowSchema();

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
      await recordGiftTransaction(client, {
        senderId,
        receiverId: null,
        amount: numCash,
        txType: 'gift_sent',
        note: `Gửi quà kèm ${numCash.toLocaleString('vi-VN')}đ cho ${normalizedReceiverEmail}`,
        orderPrefix: 'GIFT_SEND',
        giftId: Date.now(),
      });
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
  await ensureGiftCashflowSchema();

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
  await ensureGiftCashflowSchema();

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
  await ensureGiftCashflowSchema();

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
  await ensureGiftCashflowSchema();

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
  await ensureGiftCashflowSchema();

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
  await ensureGiftCashflowSchema();

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
  await ensureGiftCashflowSchema();

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
  await ensureGiftCashflowSchema();

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
    
    // 2) Mark as opened only (money is claimed by explicit receive action)
    const { rows } = await client.query(
      `UPDATE gifts
       SET status = 'opened', opened_at = COALESCE(opened_at, NOW())
       WHERE id = $1
       RETURNING *`,
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

export const receiveGiftCash = async (id, userEmail) => {
  await ensureGiftCashflowSchema();

  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    const giftResult = await client.query(
      `SELECT *
       FROM gifts
       WHERE id = $1
         AND LOWER(receiver_email) = LOWER($2)
       FOR UPDATE`,
      [id, userEmail]
    );

    if (giftResult.rowCount === 0) {
      await client.query('ROLLBACK');
      return null;
    }

    let gift = giftResult.rows[0];
    const cashAmount = getGiftCashAmount(gift);

    if (gift.status === 'pending') {
      const err = new Error('Vui lòng mở quà trước khi nhận tiền');
      err.statusCode = 409;
      throw err;
    }

    if (cashAmount <= 0) {
      await client.query('COMMIT');
      return { gift, action: 'no_cash' };
    }

    if (gift.claimed_at) {
      await client.query('COMMIT');
      return { gift, action: 'already_claimed' };
    }

    if (gift.refunded_at) {
      const err = new Error('Tiền trong quà đã được hoàn về người gửi');
      err.statusCode = 410;
      throw err;
    }

    if (isClaimWindowExpired(gift)) {
      gift = await refundGiftAmountLocked(client, gift);
      await client.query('COMMIT');
      return { gift, action: 'refunded' };
    }

    const receiverResult = await client.query(
      'SELECT user_id FROM users WHERE LOWER(email) = LOWER($1) LIMIT 1',
      [userEmail]
    );

    if (receiverResult.rowCount === 0) {
      const err = new Error('Không tìm thấy tài khoản người nhận');
      err.statusCode = 404;
      throw err;
    }

    const receiverId = receiverResult.rows[0].user_id;
    await ensureWalletExists(client, receiverId);
    await client.query('UPDATE wallets SET balance = balance + $1 WHERE user_id = $2', [cashAmount, receiverId]);

    await recordGiftTransaction(client, {
      senderId: receiverId,
      receiverId: gift.sender_id,
      amount: cashAmount,
      txType: 'gift_receive',
      note: `Nhận ${cashAmount.toLocaleString('vi-VN')}đ từ quà #${gift.id}`,
      orderPrefix: 'GIFT_RECEIVE',
      giftId: gift.id,
    });

    const { rows } = await client.query(
      `UPDATE gifts
       SET claimed_at = NOW()
       WHERE id = $1
       RETURNING *`,
      [gift.id]
    );

    await client.query('COMMIT');
    return { gift: rows[0], action: 'claimed' };
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
};

export const countPendingGifts = async (userEmail) => {
  await ensureGiftCashflowSchema();

  const query = `
    SELECT COUNT(*) AS count
    FROM gifts
    WHERE LOWER(receiver_email) = LOWER($1) AND status = 'pending';
  `;
  const { rows } = await pool.query(query, [userEmail]);
  return parseInt(rows[0].count, 10);
};

export const processExpiredGiftRefunds = async (limit = 100) => {
  await ensureGiftCashflowSchema();

  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    const { rows: expiringGifts } = await client.query(
      `SELECT *
       FROM gifts
       WHERE status = 'opened'
         AND cash_amount > 0
         AND claimed_at IS NULL
         AND refunded_at IS NULL
         AND opened_at IS NOT NULL
         AND opened_at <= NOW() - INTERVAL '${GIFT_CLAIM_WINDOW_HOURS} hours'
       ORDER BY opened_at ASC
       LIMIT $1
       FOR UPDATE SKIP LOCKED`,
      [limit]
    );

    for (const gift of expiringGifts) {
      await refundGiftAmountLocked(client, gift);
    }

    await client.query('COMMIT');
    return expiringGifts.length;
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
};

export const listRefundedGiftsMonitor = async ({
  requesterId,
  requesterRole,
  scope = 'mine',
  limit = 20,
  offset = 0,
}) => {
  await ensureGiftCashflowSchema();

  const canViewAll = ['admin', 'marketing_admin'].includes((requesterRole || '').toLowerCase());
  const effectiveScope = scope === 'all' && canViewAll ? 'all' : 'mine';

  const filterSql = effectiveScope === 'all'
    ? ''
    : 'AND g.sender_id = $1';

  const params = effectiveScope === 'all'
    ? [limit, offset]
    : [requesterId, limit, offset];

  const countParams = effectiveScope === 'all' ? [] : [requesterId];

  const countQuery = `
    SELECT COUNT(*)::int AS total
    FROM gifts g
    WHERE g.refunded_at IS NOT NULL
      AND g.claimed_at IS NULL
      ${filterSql}
  `;

  const listQuery = `
    SELECT
      g.id,
      g.sender_id,
      g.receiver_email,
      g.cash_amount,
      g.status,
      g.opened_at,
      g.refunded_at,
      g.created_at,
      u.username AS sender_name,
      u.email AS sender_account
    FROM gifts g
    LEFT JOIN users u ON g.sender_id = u.user_id
    WHERE g.refunded_at IS NOT NULL
      AND g.claimed_at IS NULL
      ${filterSql}
    ORDER BY g.refunded_at DESC
    LIMIT $${effectiveScope === 'all' ? 1 : 2}
    OFFSET $${effectiveScope === 'all' ? 2 : 3}
  `;

  const summaryQuery = `
    SELECT
      COUNT(*) FILTER (WHERE refunded_at IS NOT NULL AND claimed_at IS NULL)::int AS total_refunded,
      COUNT(*) FILTER (
        WHERE refunded_at IS NOT NULL
          AND claimed_at IS NULL
          AND refunded_at >= NOW() - INTERVAL '24 hours'
      )::int AS refunded_last_24h,
      MAX(refunded_at) AS last_refunded_at
    FROM gifts g
    WHERE g.refunded_at IS NOT NULL
      AND g.claimed_at IS NULL
      ${filterSql}
  `;

  const [{ rows: countRows }, { rows }, { rows: summaryRows }] = await Promise.all([
    pool.query(countQuery, countParams),
    pool.query(listQuery, params),
    pool.query(summaryQuery, countParams),
  ]);

  const total = Number(countRows[0]?.total || 0);
  const summary = summaryRows[0] || {
    total_refunded: 0,
    refunded_last_24h: 0,
    last_refunded_at: null,
  };

  return {
    data: rows,
    total,
    summary: {
      totalRefunded: Number(summary.total_refunded || 0),
      refundedLast24h: Number(summary.refunded_last_24h || 0),
      lastRefundedAt: summary.last_refunded_at,
    },
    scope: effectiveScope,
    canViewAll,
  };
};
