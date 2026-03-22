import { pool } from '../../db/pool.js';

export const createGift = async (senderId, giftData) => {
  const { receiverEmail, theme, modelId, stickers, message } = giftData;
  const query = `
    INSERT INTO gifts (sender_id, receiver_email, theme, model_id, stickers, message, status)
    VALUES ($1, $2, $3, $4, $5, $6, 'pending')
    RETURNING *;
  `;
  const values = [senderId, receiverEmail, theme, modelId, JSON.stringify(stickers || []), message];
  const { rows } = await pool.query(query, values);
  return rows[0];
};

export const getReceivedGifts = async (userEmail) => {
  const query = `
    SELECT g.*, u.username AS sender_name, u.avatar_url AS sender_avatar
    FROM gifts g
    LEFT JOIN users u ON g.sender_id = u.user_id
    WHERE g.receiver_email = $1
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

export const getGiftById = async (id) => {
  const query = `
    SELECT g.*, u.username AS sender_name, u.avatar_url AS sender_avatar, u.full_name AS sender_full_name
    FROM gifts g
    LEFT JOIN users u ON g.sender_id = u.user_id
    WHERE g.id = $1;
  `;
  const { rows } = await pool.query(query, [id]);
  return rows[0];
};

export const markAsOpened = async (id, userEmail) => {
  const query = `
    UPDATE gifts
    SET status = 'opened', opened_at = NOW()
    WHERE id = $1 AND receiver_email = $2 AND status = 'pending'
    RETURNING *;
  `;
  const { rows } = await pool.query(query, [id, userEmail]);
  return rows[0];
};

export const countPendingGifts = async (userEmail) => {
  const query = `SELECT COUNT(*) AS count FROM gifts WHERE receiver_email = $1 AND status = 'pending';`;
  const { rows } = await pool.query(query, [userEmail]);
  return parseInt(rows[0].count, 10);
};
