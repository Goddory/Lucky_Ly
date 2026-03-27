import * as authUtils from '../utils/authUtils.js';
import { pool } from '../db/pool.js';

export const authenticateToken = async (req, res, next) => {
    const authHeader = req.headers.authorization;
    const bearerToken = authHeader && authHeader.startsWith('Bearer ')
        ? authHeader.split(' ')[1]
        : null;

    const cookieToken = req.cookies?.accessToken ?? null;
    const token = bearerToken || cookieToken;

    if (!token) {
        console.log('DEBUG: No token found in cookies or authorization header');
        return res.status(401).json({ message: 'Access denied. No token provided.' });
    }

    try {
        console.log('DEBUG: Verifying token...');
        const decoded = authUtils.verifyAccessToken(token);
        const userId = decoded.userId ?? decoded.sub;

        if (!userId) {
            return res.status(403).json({ message: 'Invalid token payload.' });
        }

        // Fetch role from DB
        const { rows } = await pool.query(
            'SELECT role FROM users WHERE user_id = $1 LIMIT 1',
            [userId]
        );

        req.user = {
            ...decoded,
            userId,
            sub: userId,
            email: decoded.email ?? null,
            username: decoded.username ?? null,
            role: rows[0]?.role ?? 'user'
        };

        next();
    } catch (error) {
        console.error('DEBUG: Token verification failed:', error.message);
        res.status(403).json({ message: 'Invalid or expired token.' });
    }
};

