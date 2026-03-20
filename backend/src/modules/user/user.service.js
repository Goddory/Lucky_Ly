import bcrypt from 'bcrypt';
import { pool } from '../../db/pool.js';
import { env } from '../../config/env.js';

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

// Đổi mật khẩu: kiểm tra mật khẩu cũ, hash mật khẩu mới, cập nhật DB và thu hồi refresh token
export async function changeUserPassword(userId, currentPassword, newPassword) {
  const userResult = await pool.query(
    'SELECT password_hash, auth_provider FROM users WHERE user_id = $1 LIMIT 1',
    [userId]
  );

  if (userResult.rowCount === 0) {
    const error = new Error('User not found');
    error.statusCode = 404;
    throw error;
  }

  const user = userResult.rows[0];

  if (user.auth_provider !== 'local' || !user.password_hash) {
    const error = new Error('Cannot change password for social login accounts');
    error.statusCode = 400;
    throw error;
  }

  const isPasswordValid = await bcrypt.compare(currentPassword, user.password_hash);
  if (!isPasswordValid) {
    const error = new Error('Current password is incorrect');
    error.statusCode = 401;
    throw error;
  }

  const newPasswordHash = await bcrypt.hash(newPassword, env.bcryptRounds);

  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    // Update password
    await client.query(
      'UPDATE users SET password_hash = $1 WHERE user_id = $2',
      [newPasswordHash, userId]
    );

    // Revoke all existing active refresh tokens to force re-login on other devices
    await client.query(
      'UPDATE auth_refresh_tokens SET revoked_at = NOW() WHERE user_id = $1 AND revoked_at IS NULL',
      [userId]
    );

    await client.query('COMMIT');
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
}

// Lấy danh sách tất cả users (Dành cho Admin)
export async function getAllUsersService() {
  const result = await pool.query(
    `SELECT user_id as id, username, email, full_name as name, avatar_url, auth_provider, created_at, is_active as "isActive", role
     FROM users ORDER BY created_at DESC`
  );
  return result.rows;
}

// Khóa/Mở Khóa tài khoản
export async function toggleUserStatusService(userId, isActive) {
  const result = await pool.query(
    `UPDATE users SET is_active = $1 WHERE user_id = $2 AND role != 'admin' RETURNING user_id, is_active`,
    [isActive, userId]
  );
  
  if (result.rowCount === 0) {
    const error = new Error('User not found or cannot modify an admin account');
    error.statusCode = 400;
    throw error;
  }

  if (isActive === false) {
    await pool.query(
      'UPDATE auth_refresh_tokens SET revoked_at = NOW() WHERE user_id = $1 AND revoked_at IS NULL',
      [userId]
    );
  }

  return result.rows[0];
}
