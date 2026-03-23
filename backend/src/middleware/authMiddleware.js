import * as authUtils from '../utils/authUtils.js';

export const authenticateToken = (req, res, next) => {
    const authHeader = req.headers.authorization;
    const bearerToken = authHeader && authHeader.startsWith('Bearer ')
        ? authHeader.split(' ')[1]
        : null;

    const cookieToken = req.cookies?.accessToken ?? null;
    const token = bearerToken || cookieToken;

    if (!token) {
        return res.status(401).json({ message: 'Access denied. No token provided.' });
    }

    try {
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
        res.status(403).json({ message: 'Invalid or expired token.' });
    }
};
