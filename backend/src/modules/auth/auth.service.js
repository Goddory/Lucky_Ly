import bcrypt from 'bcrypt';
import crypto from 'crypto';
import jwt from 'jsonwebtoken';
import { pool } from '../../db/pool.js';
import { env } from '../../config/env.js';

// Băm refresh token bằng SHA-256 trước khi lưu DB để tránh lộ token gốc.
function hashToken(token) {
  return crypto.createHash('sha256').update(token).digest('hex');
}

// Sinh refresh token ngẫu nhiên có entropy cao.
function generateRefreshToken() {
  return crypto.randomBytes(48).toString('base64url');
}

// Tạo JWT access token ngắn hạn chứa định danh người dùng.
function buildAccessToken(user) {
  return jwt.sign(
    {
      sub: user.user_id,
      username: user.username,
      email: user.email
    },
    env.jwt.accessSecret,
    { expiresIn: env.jwt.accessExpiresIn }
  );
}

// Lưu refresh token đã băm vào DB kèm thời hạn hiệu lực.
async function persistRefreshToken(client, userId, plainRefreshToken) {
  const tokenHash = hashToken(plainRefreshToken);
  const query = `
    INSERT INTO auth_refresh_tokens (user_id, token_hash, expires_at)
    VALUES ($1, $2, NOW() + ($3 || ' days')::interval)
  `;
  await client.query(query, [userId, tokenHash, String(env.refreshTokenTtlDays)]);
}

// Nghiệp vụ đăng ký: tạo user, tạo ví mặc định và cấp bộ token đầu tiên trong transaction.
export async function registerUser(payload) {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    const username = payload.username.trim();
    const email = payload.email.trim().toLowerCase();
    const fullName = payload.fullName.trim();
    const avatarUrl = payload.avatarUrl || null;

    const existing = await client.query(
      'SELECT 1 FROM users WHERE username = $1 OR email = $2 LIMIT 1',
      [username, email]
    );

    if (existing.rowCount > 0) {
      const error = new Error('Username or email already exists');
      error.statusCode = 409;
      throw error;
    }

    const passwordHash = await bcrypt.hash(payload.password, env.bcryptRounds);

    const insertUserQuery = `
      INSERT INTO users (username, password_hash, email, full_name, avatar_url)
      VALUES ($1, $2, $3, $4, $5)
      RETURNING user_id, username, email, full_name, avatar_url, created_at
    `;

    const userResult = await client.query(insertUserQuery, [
      username,
      passwordHash,
      email,
      fullName,
      avatarUrl
    ]);

    const user = userResult.rows[0];

    await client.query('INSERT INTO wallets (user_id, balance, currency, status) VALUES ($1, 0, $2, $3)', [
      user.user_id,
      'VND',
      'ACTIVE'
    ]);

    const refreshToken = generateRefreshToken();
    await persistRefreshToken(client, user.user_id, refreshToken);

    await client.query('COMMIT');

    return {
      user,
      accessToken: buildAccessToken(user),
      refreshToken
    };
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
}

// Nghiệp vụ đăng nhập: xác thực thông tin đăng nhập, cấp mới access/refresh token.
export async function loginUser(payload) {
  const loginValue = payload.login.trim();
  const query = `
    SELECT user_id, username, email, full_name, avatar_url, password_hash
    FROM users
    WHERE username = $1 OR email = $2
    LIMIT 1
  `;

  const result = await pool.query(query, [loginValue, loginValue.toLowerCase()]);
  const user = result.rows[0];

  const invalidError = new Error('Invalid credentials');
  invalidError.statusCode = 401;

  if (!user) {
    throw invalidError;
  }

  const isPasswordValid = await bcrypt.compare(payload.password, user.password_hash);
  if (!isPasswordValid) {
    throw invalidError;
  }

  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const refreshToken = generateRefreshToken();
    await persistRefreshToken(client, user.user_id, refreshToken);
    await client.query('COMMIT');

    return {
      user: {
        user_id: user.user_id,
        username: user.username,
        email: user.email,
        full_name: user.full_name,
        avatar_url: user.avatar_url
      },
      accessToken: buildAccessToken(user),
      refreshToken
    };
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
}

// Nghiệp vụ đăng nhập bằng Facebook
export async function loginFacebookUser(payload) {
  const { facebookId, email, name, avatarUrl } = payload;
  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    // Tìm user: Ưu tiên facebook_id, sau đó tìm theo email (nếu có email)
    let userQuery = `
      SELECT user_id, username, email, full_name, avatar_url, facebook_id
      FROM users
      WHERE facebook_id = $1
    `;
    let queryParams = [facebookId];

    if (email && email.trim() !== '') {
      userQuery += ` OR email = $2`;
      queryParams.push(email.trim().toLowerCase());
    }
    userQuery += ` LIMIT 1`;

    const result = await client.query(userQuery, queryParams);
    let user = result.rows[0];

    // Cập nhật facebook_id nếu tòm thấy user qua email nhưng chưa có facebook_id
    if (user && !user.facebook_id) {
      await client.query(
        'UPDATE users SET facebook_id = $1 WHERE user_id = $2',
        [facebookId, user.user_id]
      );
      user.facebook_id = facebookId;
    }

    if (!user) {
      // Đăng ký mới nếu chưa có
      // Tạo username ngẫu nhiên từ name
      const cleanName = name.replace(/\s+/g, '').toLowerCase().substring(0, 10);
      let newUsername = `fb_${cleanName}_${facebookId.substring(0, 5)}`;

      const insertUserQuery = `
        INSERT INTO users (username, email, full_name, avatar_url, facebook_id)
        VALUES ($1, $2, $3, $4, $5)
        RETURNING user_id, username, email, full_name, avatar_url, facebook_id, created_at
      `;
      const finalEmail = (email && email.trim() !== '') ? email.trim().toLowerCase() : null;

      const userResult = await client.query(insertUserQuery, [
        newUsername, finalEmail, name.trim(), avatarUrl || null, facebookId
      ]);
      user = userResult.rows[0];

      await client.query('INSERT INTO wallets (user_id, balance, currency, status) VALUES ($1, 0, $2, $3)', [
        user.user_id, 'VND', 'ACTIVE'
      ]);
    }

    const refreshToken = generateRefreshToken();
    await persistRefreshToken(client, user.user_id, refreshToken);
    await client.query('COMMIT');

    return {
      user: {
        user_id: user.user_id,
        username: user.username,
        email: user.email,
        full_name: user.full_name,
        avatar_url: user.avatar_url
      },
      accessToken: buildAccessToken(user),
      refreshToken
    };
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
}

// Nghiệp vụ refresh token rotation: kiểm tra token cũ, thu hồi và thay bằng token mới.
export async function rotateRefreshToken(currentRefreshToken) {
  const tokenHash = hashToken(currentRefreshToken);
  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    const tokenResult = await client.query(
      `
      SELECT rt.token_id, rt.user_id, rt.expires_at, rt.revoked_at, u.username, u.email
      FROM auth_refresh_tokens rt
      INNER JOIN users u ON u.user_id = rt.user_id
      WHERE rt.token_hash = $1
      LIMIT 1
      `,
      [tokenHash]
    );

    if (tokenResult.rowCount === 0) {
      const error = new Error('Invalid refresh token');
      error.statusCode = 401;
      throw error;
    }

    const tokenRow = tokenResult.rows[0];

    if (tokenRow.revoked_at || new Date(tokenRow.expires_at) <= new Date()) {
      const error = new Error('Refresh token expired or revoked');
      error.statusCode = 401;
      throw error;
    }

    const newRefreshToken = generateRefreshToken();
    const newHash = hashToken(newRefreshToken);

    const newTokenResult = await client.query(
      `
      INSERT INTO auth_refresh_tokens (user_id, token_hash, expires_at)
      VALUES ($1, $2, NOW() + ($3 || ' days')::interval)
      RETURNING token_id
      `,
      [tokenRow.user_id, newHash, String(env.refreshTokenTtlDays)]
    );

    await client.query(
      `
      UPDATE auth_refresh_tokens
      SET revoked_at = NOW(), replaced_by = $2
      WHERE token_id = $1
      `,
      [tokenRow.token_id, newTokenResult.rows[0].token_id]
    );

    await client.query('COMMIT');

    return {
      accessToken: jwt.sign(
        { sub: tokenRow.user_id, username: tokenRow.username, email: tokenRow.email },
        env.jwt.accessSecret,
        { expiresIn: env.jwt.accessExpiresIn }
      ),
      refreshToken: newRefreshToken
    };
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
}

// Thu hồi refresh token khi logout hoặc khi cần vô hiệu hóa phiên.
export async function revokeRefreshToken(refreshToken) {
  const tokenHash = hashToken(refreshToken);
  const result = await pool.query(
    `
    UPDATE auth_refresh_tokens
    SET revoked_at = NOW()
    WHERE token_hash = $1 AND revoked_at IS NULL
    `,
    [tokenHash]
  );

  return result.rowCount > 0;
}
