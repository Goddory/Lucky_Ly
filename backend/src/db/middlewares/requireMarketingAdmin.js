import { pool } from '../pool.js';

// Allow both 'admin' and 'marketing_admin' roles to access marketing endpoints.
export async function requireMarketingAdmin(req, res, next) {
  try {
    const userId = req.user?.userId;

    if (!userId) {
      return res.status(401).json({ message: 'Access denied. Missing user context.' });
    }

    const result = await pool.query('SELECT role FROM users WHERE user_id = $1 LIMIT 1', [userId]);
    const role = String(result.rows[0]?.role ?? '').trim().toLowerCase();

    if (role !== 'admin' && role !== 'marketing_admin') {
      return res.status(403).json({ message: 'Marketing admin access required.' });
    }

    req.user = { ...req.user, role };
    return next();
  } catch (err) {
    return next(err);
  }
}
