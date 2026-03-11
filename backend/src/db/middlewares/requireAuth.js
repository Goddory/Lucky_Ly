import jwt from 'jsonwebtoken';
import { env } from '../../config/env.js';

// Middleware xác thực JWT từ header Authorization: Bearer <token>
export function requireAuth(req, res, next) {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ message: 'Access denied. No token provided.' });
  }

  const token = authHeader.split(' ')[1];

  try {
    const decoded = jwt.verify(token, env.jwt.accessSecret);
    req.user = { userId: decoded.sub, username: decoded.username, email: decoded.email };
    next();
  } catch (err) {
    return res.status(401).json({ message: 'Invalid or expired token.' });
  }
}
