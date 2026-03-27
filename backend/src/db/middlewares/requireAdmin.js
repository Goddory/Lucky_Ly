import { pool } from '../pool.js';

// Require authenticated user to have admin role in database.
export async function requireAdmin(req, res, next) {
  try {
    const userId = req.user?.userId;

    if (!userId) {
      return res.status(401).json({ message: 'Access denied. Missing user context.' });
    }

    const result = await pool.query('SELECT role FROM users WHERE user_id = $1 LIMIT 1', [userId]);
    const role = String(result.rows[0]?.role ?? '').trim().toLowerCase();

    if (role !== 'admin') {
      return res.status(403).json({ message: 'Forbidden' });
    }

    req.user = { ...req.user, role };
    return next();
  } catch (err) {
    return next(err);
  }
}