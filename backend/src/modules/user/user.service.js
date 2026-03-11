import { pool } from '../../db/pool.js';

// Lấy profile user hiện tại từ DB.
export async function getUserProfile(userId) {
  const result = await pool.query(
    `SELECT user_id, username, email, full_name, avatar_url, auth_provider, created_at
     FROM users WHERE user_id = $1 LIMIT 1`,
    [userId]
  );

  if (result.rowCount === 0) {
    const error = new Error('User not found');
    error.statusCode = 404;
    throw error;
  }

  return result.rows[0];
}

// Cập nhật thông tin profile user.
export async function updateUserProfile(userId, payload) {
  const fields = [];
  const values = [];
  let paramIndex = 1;

  if (payload.fullName !== undefined) {
    fields.push(`full_name = $${paramIndex++}`);
    values.push(payload.fullName);
  }

  if (payload.email !== undefined) {
    // Check email uniqueness
    const emailCheck = await pool.query(
      'SELECT user_id FROM users WHERE email = $1 AND user_id != $2 LIMIT 1',
      [payload.email.toLowerCase(), userId]
    );
    if (emailCheck.rowCount > 0) {
      const error = new Error('Email already in use');
      error.statusCode = 409;
      throw error;
    }
    fields.push(`email = $${paramIndex++}`);
    values.push(payload.email.toLowerCase());
  }

  if (payload.avatarUrl !== undefined) {
    fields.push(`avatar_url = $${paramIndex++}`);
    values.push(payload.avatarUrl);
  }

  if (fields.length === 0) {
    return getUserProfile(userId);
  }

  values.push(userId);

  const result = await pool.query(
    `UPDATE users SET ${fields.join(', ')} WHERE user_id = $${paramIndex}
     RETURNING user_id, username, email, full_name, avatar_url, auth_provider, created_at`,
    values
  );

  if (result.rowCount === 0) {
    const error = new Error('User not found');
    error.statusCode = 404;
    throw error;
  }

  return result.rows[0];
}
