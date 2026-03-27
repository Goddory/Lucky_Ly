import * as authUtils from '../utils/authUtils.js';

export const authenticateToken = (req, res, next) => {
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
        req.user = {
            ...decoded,
            userId: decoded.userId ?? decoded.sub,
            email: decoded.email ?? null,
            username: decoded.username ?? null
        };

        if (!req.user.userId) {
            return res.status(403).json({ message: 'Invalid token payload.' });
        }

        next();
    } catch (error) {
        console.error('DEBUG: Token verification failed:', error.message);
        res.status(403).json({ message: 'Invalid or expired token.' });
    }
};
