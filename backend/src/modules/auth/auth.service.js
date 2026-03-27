import bcrypt from 'bcrypt';
import crypto from 'crypto';
import jwt from 'jsonwebtoken';
import { OAuth2Client } from 'google-auth-library';
import { pool } from '../../db/pool.js';
import { env } from '../../config/env.js';
import { sendPasswordResetEmail } from '../../utils/mailer.js';

const googleClient = new OAuth2Client();

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

function normalizeSessionMeta(sessionMeta = {}) {
  const clean = (value) => {
    const normalized = String(value ?? '').trim();
    return normalized.length > 0 ? normalized : null;
  };

  return {
    deviceId: clean(sessionMeta.deviceId),
    deviceName: clean(sessionMeta.deviceName),
    platform: clean(sessionMeta.platform),
    userAgent: clean(sessionMeta.userAgent),
    ipAddress: clean(sessionMeta.ipAddress)
  };
}

// Lưu refresh token đã băm vào DB kèm thời hạn hiệu lực.
async function persistRefreshToken(client, userId, plainRefreshToken, sessionMeta = {}) {
  const meta = normalizeSessionMeta(sessionMeta);
  const tokenHash = hashToken(plainRefreshToken);
  const query = `
    INSERT INTO auth_refresh_tokens (
      user_id,
      token_hash,
      device_id,
      device_name,
      platform,
      user_agent,
      ip_address,
      last_used_at,
      expires_at
    )
    VALUES ($1, $2, $3, $4, $5, $6, $7, NOW(), NOW() + ($8 || ' days')::interval)
  `;
  await client.query(query, [
    userId,
    tokenHash,
    meta.deviceId,
    meta.deviceName,
    meta.platform,
    meta.userAgent,
    meta.ipAddress,
    String(env.refreshTokenTtlDays)
  ]);
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
      RETURNING user_id, username, email, full_name, avatar_url, role, created_at
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
    await persistRefreshToken(client, user.user_id, refreshToken, payload);

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
    SELECT user_id, username, email, full_name, avatar_url, password_hash, is_active, role
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

  if (user.is_active === false) {
    const error = new Error('Tài khoản của bạn đã bị khóa. Vui lòng liên hệ hỗ trợ.');
    error.statusCode = 403;
    throw error;
  }

  if (!user.password_hash) {
    const error = new Error('This account uses social login. Please sign in with Facebook or Google.');
    error.statusCode = 400;
    throw error;
  }

  const isPasswordValid = await bcrypt.compare(payload.password, user.password_hash);
  if (!isPasswordValid) {
    throw invalidError;
  }

  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const refreshToken = generateRefreshToken();
    await persistRefreshToken(client, user.user_id, refreshToken, payload);
    await client.query('COMMIT');

    return {
      user: {
        user_id: user.user_id,
        username: user.username,
        email: user.email,
        full_name: user.full_name,
        avatar_url: user.avatar_url,
        role: user.role ?? 'user'
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

// Nghiệp vụ đăng nhập bằng Facebook: tìm hoặc tạo user, cấp token.
export async function loginFacebookUser(payload) {
  const { facebookId, email, name, avatarUrl } = payload;
  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    // Tìm user: Ưu tiên facebook_id, sau đó tìm theo email (nếu có email)
    let userQuery = `
      SELECT user_id, username, email, full_name, avatar_url, facebook_id, is_active, role
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

    if (user && user.is_active === false) {
      const error = new Error('Tài khoản của bạn đã bị khóa. Vui lòng liên hệ hỗ trợ.');
      error.statusCode = 403;
      throw error;
    }

    // Cập nhật facebook_id nếu tìm thấy user qua email nhưng chưa có facebook_id
    if (user && !user.facebook_id) {
      await client.query(
        'UPDATE users SET facebook_id = $1 WHERE user_id = $2',
        [facebookId, user.user_id]
      );
      user.facebook_id = facebookId;
    }

    if (!user) {
      // Đăng ký mới nếu chưa có
      const cleanName = name.replace(/\s+/g, '').toLowerCase().substring(0, 10);
      const newUsername = `fb_${cleanName}_${facebookId.substring(0, 5)}`;

      const insertUserQuery = `
        INSERT INTO users (username, email, full_name, avatar_url, facebook_id, auth_provider)
        VALUES ($1, $2, $3, $4, $5, 'facebook')
        RETURNING user_id, username, email, full_name, avatar_url, facebook_id, role, created_at
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
    await persistRefreshToken(client, user.user_id, refreshToken, payload);
    await client.query('COMMIT');

    return {
      user: {
        user_id: user.user_id,
        username: user.username,
        email: user.email,
        full_name: user.full_name,
        avatar_url: user.avatar_url,
        role: user.role ?? 'user'
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
export async function rotateRefreshToken(currentRefreshToken, sessionMeta = {}) {
  const tokenHash = hashToken(currentRefreshToken);
  const meta = normalizeSessionMeta(sessionMeta);
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
      INSERT INTO auth_refresh_tokens (
        user_id,
        token_hash,
        device_id,
        device_name,
        platform,
        user_agent,
        ip_address,
        last_used_at,
        expires_at
      )
      VALUES ($1, $2, $3, $4, $5, $6, $7, NOW(), NOW() + ($8 || ' days')::interval)
      RETURNING token_id
      `,
      [
        tokenRow.user_id,
        newHash,
        meta.deviceId,
        meta.deviceName,
        meta.platform,
        meta.userAgent,
        meta.ipAddress,
        String(env.refreshTokenTtlDays)
      ]
    );

    await client.query(
      `
      UPDATE auth_refresh_tokens
      SET revoked_at = NOW(), replaced_by = $2, last_used_at = NOW()
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
export async function revokeRefreshToken(refreshToken, userId = null) {
  const tokenHash = hashToken(refreshToken);
  const whereUserFilter = userId ? 'AND user_id = $2' : '';
  const params = userId ? [tokenHash, userId] : [tokenHash];
  const result = await pool.query(
    `
    UPDATE auth_refresh_tokens
    SET revoked_at = NOW(), last_used_at = NOW()
    WHERE token_hash = $1 AND revoked_at IS NULL ${whereUserFilter}
    `,
    params
  );

  return result.rowCount > 0;
}

// Nghiệp vụ đăng nhập Google: xác minh token, tìm hoặc tạo user, cấp token.
export async function loginWithGoogle(payload) {
  const { idToken, accessToken } = payload;
  let email, name, picture, googleUid;

  if (idToken) {
    // Mobile flow: verify idToken với Google
    const ticket = await googleClient.verifyIdToken({
      idToken,
      audience: env.googleClientId
    });
    const payload = ticket.getPayload();
    email = payload.email;
    name = payload.name;
    picture = payload.picture;
    googleUid = payload.sub;
  } else if (accessToken) {
    // Web flow: dùng accessToken gọi Google userinfo API
    const res = await fetch('https://www.googleapis.com/oauth2/v3/userinfo', {
      headers: { Authorization: `Bearer ${accessToken}` }
    });
    if (!res.ok) {
      const error = new Error('Invalid Google access token');
      error.statusCode = 401;
      throw error;
    }
    const payload = await res.json();
    email = payload.email;
    name = payload.name;
    picture = payload.picture;
    googleUid = payload.sub;
  }

  if (!email) {
    const error = new Error('Google account has no email');
    error.statusCode = 400;
    throw error;
  }

  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    const existing = await client.query(
      'SELECT user_id, username, email, full_name, avatar_url, is_active, role FROM users WHERE email = $1 LIMIT 1',
      [email.toLowerCase()]
    );

    let user;

    if (existing.rowCount > 0) {
      user = existing.rows[0];
      
      if (user.is_active === false) {
        const error = new Error('Tài khoản của bạn đã bị khóa. Vui lòng liên hệ hỗ trợ.');
        error.statusCode = 403;
        throw error;
      }
      await client.query(
        `UPDATE users SET auth_provider = 'google', provider_uid = $1,
         avatar_url = COALESCE(avatar_url, $2)
         WHERE user_id = $3`,
        [googleUid, picture, user.user_id]
      );
      // Sync avatar_url so the response includes the Google picture
      if (!user.avatar_url && picture) {
        user.avatar_url = picture;
      }
    } else {
      const username = `g_${email.split('@')[0]}_${Date.now().toString(36)}`;
      const insertResult = await client.query(
        `INSERT INTO users (username, email, full_name, avatar_url, auth_provider, provider_uid)
         VALUES ($1, $2, $3, $4, 'google', $5)
         RETURNING user_id, username, email, full_name, avatar_url, role, created_at`,
        [username, email.toLowerCase(), name || email.split('@')[0], picture, googleUid]
      );
      user = insertResult.rows[0];

      await client.query(
        "INSERT INTO wallets (user_id, balance, currency, status) VALUES ($1, 0, $2, $3)",
        [user.user_id, 'VND', 'ACTIVE']
      );
    }

    const refreshToken = generateRefreshToken();
    await persistRefreshToken(client, user.user_id, refreshToken, payload);

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

// Liệt kê các phiên đăng nhập đang hoạt động theo thiết bị của user.
export async function listActiveSessions(userId) {
  const { rows } = await pool.query(
    `
    SELECT token_id, device_id, device_name, platform, user_agent, ip_address, created_at, last_used_at, expires_at
    FROM auth_refresh_tokens
    WHERE user_id = $1 AND revoked_at IS NULL AND expires_at > NOW()
    ORDER BY last_used_at DESC, created_at DESC
    `,
    [userId]
  );

  return rows;
}

// Thu hồi toàn bộ phiên hoạt động của user.
export async function revokeAllRefreshTokens(userId) {
  const { rowCount } = await pool.query(
    `
    UPDATE auth_refresh_tokens
    SET revoked_at = NOW(), last_used_at = NOW()
    WHERE user_id = $1 AND revoked_at IS NULL
    `,
    [userId]
  );

  return rowCount;
}

// Thu hồi một phiên theo token_id (chỉ trong phạm vi user hiện tại).
export async function revokeSessionByTokenId(userId, tokenId) {
  const { rowCount } = await pool.query(
    `
    UPDATE auth_refresh_tokens
    SET revoked_at = NOW(), last_used_at = NOW()
    WHERE user_id = $1 AND token_id = $2 AND revoked_at IS NULL
    `,
    [userId, tokenId]
  );

  return rowCount > 0;
}

// ============================================
// FORGOT PASSWORD
// ============================================

// Yêu cầu đổi mật khẩu: Sinh OTP 6 chữ số, lưu vào DB và gửi email.
export async function requestPasswordReset(email) {
  const result = await pool.query(
    'SELECT user_id, full_name, auth_provider FROM users WHERE email = $1 LIMIT 1',
    [email.toLowerCase()]
  );
  
  if (result.rowCount === 0) {
    // Để bảo mật, không trả về lỗi rõ ràng nếu email không tồn tại.
    return;
  }
  const user = result.rows[0];

  if (user.auth_provider !== 'local') {
    const error = new Error('This account uses social login.');
    error.statusCode = 400;
    throw error;
  }

  // Generate 6-digit OTP
  const otpCode = Math.floor(100000 + Math.random() * 900000).toString();
  const otpHash = await bcrypt.hash(otpCode, 10);

  // Lưu OTP hash vào database với hiệu lực 15 phút
  await pool.query(
    `INSERT INTO password_reset_otps (user_id, otp_hash, expires_at) 
     VALUES ($1, $2, NOW() + interval '15 minutes')`,
    [user.user_id, otpHash]
  );

  // Gửi OTP qua email
  await sendPasswordResetEmail(email.toLowerCase(), otpCode, user.full_name);
}

// Xác thực OTP
export async function verifyPasswordResetOtp(email, otp) {
  const userResult = await pool.query(
    'SELECT user_id FROM users WHERE email = $1 AND auth_provider = $2 LIMIT 1',
    [email.toLowerCase(), 'local']
  );
  if (userResult.rowCount === 0) {
    const error = new Error('Invalid or expired OTP');
    error.statusCode = 400;
    throw error;
  }
  const userId = userResult.rows[0].user_id;

  // Lấy các OTP đang chờ
  const otpResult = await pool.query(
    `SELECT id, otp_hash FROM password_reset_otps 
     WHERE user_id = $1 AND expires_at > NOW() AND status = 'PENDING'
     ORDER BY created_at DESC`,
    [userId]
  );

  if (otpResult.rowCount === 0) {
    const error = new Error('Invalid or expired OTP');
    error.statusCode = 400;
    throw error;
  }

  // Compare OTP
  let validOtpId = null;
  for (const row of otpResult.rows) {
    const isValid = await bcrypt.compare(otp, row.otp_hash);
    if (isValid) {
      validOtpId = row.id;
      break;
    }
  }

  if (!validOtpId) {
    const error = new Error('Invalid or expired OTP');
    error.statusCode = 400;
    throw error;
  }

  // Mark status as VERIFIED
  await pool.query(
    "UPDATE password_reset_otps SET status = 'VERIFIED' WHERE id = $1",
    [validOtpId]
  );
}

// Đổi mật khẩu sau khi có OTP xác thực
export async function resetPasswordWithOtp(email, otp, newPassword) {
  const userResult = await pool.query(
    'SELECT user_id FROM users WHERE email = $1 AND auth_provider = $2 LIMIT 1',
    [email.toLowerCase(), 'local']
  );
  if (userResult.rowCount === 0) {
    const error = new Error('Invalid request');
    error.statusCode = 400;
    throw error;
  }
  const userId = userResult.rows[0].user_id;

  // Verify OTP is still valid AND status = 'VERIFIED'
  const otpResult = await pool.query(
    `SELECT id, otp_hash FROM password_reset_otps 
     WHERE user_id = $1 AND expires_at > NOW() AND status = 'VERIFIED'
     ORDER BY created_at DESC`,
    [userId]
  );

  if (otpResult.rowCount === 0) {
    const error = new Error('No verified OTP session found. Please request a new OTP.');
    error.statusCode = 400;
    throw error;
  }

  let finalOtpId = null;
  for (const row of otpResult.rows) {
    const isValid = await bcrypt.compare(otp, row.otp_hash);
    if (isValid) {
      finalOtpId = row.id;
      break;
    }
  }

  if (!finalOtpId) {
    const error = new Error('Invalid OTP');
    error.statusCode = 400;
    throw error;
  }

  const newPasswordHash = await bcrypt.hash(newPassword, env.bcryptRounds);

  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    // Update new password
    await client.query(
      'UPDATE users SET password_hash = $1 WHERE user_id = $2',
      [newPasswordHash, userId]
    );

    // Xóa record OTP (đã hoàn thành)
    await client.query(
      'DELETE FROM password_reset_otps WHERE user_id = $1',
      [userId]
    );

    // Xóa tất cả các session cũ
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
