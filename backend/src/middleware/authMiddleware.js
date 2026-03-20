import * as authUtils from '../utils/authUtils.js';

export const authenticateToken = (req, res, next) => {
    const token = req.cookies?.accessToken || (req.headers.authorization && req.headers.authorization.startsWith('Bearer ') ? req.headers.authorization.split(' ')[1] : null);

    if (!token) {
        console.log('DEBUG: No token found in cookies or authorization header');
        return res.status(401).json({ message: 'Access denied. No token provided.' });
    }

    try {
        console.log('DEBUG: Verifying token...');
        const decoded = authUtils.verifyAccessToken(token);
        console.log('DEBUG: Token verified. Decoded:', JSON.stringify(decoded));
        // Correcting the ID extraction to check for 'sub' as used by authService.buildAccessToken
        const userId = decoded.sub || decoded.userId || decoded.id;
        console.log('DEBUG: Extracted userId:', userId);
        req.user = { id: userId, ...decoded };
        next();
    } catch (error) {
        console.error('DEBUG: Token verification failed:', error.message);
        res.status(403).json({ message: 'Invalid or expired token.' });
    }
};
