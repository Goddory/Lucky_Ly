import jwt from 'jsonwebtoken';
import { env } from '../../config/env.js';
import { pool } from '../pool.js';

// Middleware xác thực JWT — đọc Bearer token hoặc cookie,
// sau đó query DB để gắn role vào req.user (nhất quán với authenticateToken).
export async function requireAuth(req, res, next) {
  const authHeader = req.headers.authorization;
  const bearerToken = authHeader?.startsWith('Bearer ') ? authHeader.split(' ')[1] : null;
  const cookieToken = req.cookies?.accessToken ?? null;
  const token = bearerToken || cookieToken;

  if (!token) {
    return res.status(401).json({ message: 'Access denied. No token provided.' });
  }

  try {
    const decoded = jwt.verify(token, env.jwt.accessSecret);
    const userId = decoded.sub ?? decoded.userId;

    if (!userId) {
      return res.status(401).json({ message: 'Invalid token payload.' });
    }

    const { rows } = await pool.query(
      'SELECT role FROM users WHERE user_id = $1 LIMIT 1',
      [userId]
    );

    req.user = {
      userId,
      username: decoded.username ?? null,
      email: decoded.email ?? null,
      role: rows[0]?.role ?? 'user',
    };

    return next();
  } catch (err) {
    return res.status(401).json({ message: 'Invalid or expired token.' });
  }
}
