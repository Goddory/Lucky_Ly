import { query } from '../config/db.js';
import * as authUtils from '../utils/authUtils.js';
import { z } from 'zod';

const registerSchema = z.object({
    username: z.string().min(3).max(50),
    email: z.string().email(),
    password: z.string().min(6),
    full_name: z.string().min(1).max(150),
});

const loginSchema = z.object({
    identifier: z.string(), // can be email or username
    password: z.string(),
});

export const register = async (req, res) => {
    try {
        console.log('Register request body:', req.body);
        const validatedData = registerSchema.parse(req.body);
        const { username, email, password, full_name } = validatedData;

        // Check if user exists
        const userExists = await query(
            'SELECT 1 FROM users WHERE username = $1 OR email = $2',
            [username, email]
        );

        if (userExists.rows.length > 0) {
            return res.status(400).json({ message: 'Username or Email already exists' });
        }

        const hashedPassword = await authUtils.hashPassword(password);

        const newUser = await query(
            'INSERT INTO users (username, email, password_hash, full_name) VALUES ($1, $2, $3, $4) RETURNING user_id, username, email',
            [username, email, hashedPassword, full_name]
        );

        // Create wallet for new user
        await query('INSERT INTO wallets (user_id) VALUES ($1)', [newUser.rows[0].user_id]);

        res.status(201).json({
            message: 'User registered successfully',
            user: newUser.rows[0],
        });
    } catch (error) {
        if (error instanceof z.ZodError) {
            return res.status(400).json({ errors: error.errors });
        }
        console.error('Register error:', error);
        import('fs').then(fs => {
            fs.appendFileSync('register_error.log', `\n--- ERROR at ${new Date().toISOString()} ---\n${error.stack || error}\n`);
        });
        res.status(500).json({ message: 'Internal server error' });
    }
};

export const login = async (req, res) => {
    try {
        const { identifier, password } = loginSchema.parse(req.body);

        const userResult = await query(
            'SELECT * FROM users WHERE username = $1 OR email = $2',
            [identifier, identifier]
        );

        if (userResult.rows.length === 0) {
            return res.status(401).json({ message: 'Invalid credentials' });
        }

        const user = userResult.rows[0];
        const isPasswordValid = await authUtils.comparePassword(password, user.password_hash);

        if (!isPasswordValid) {
            return res.status(401).json({ message: 'Invalid credentials' });
        }

        const accessToken = authUtils.generateAccessToken(user.user_id);
        const refreshToken = authUtils.generateRefreshToken(user.user_id);

        // Store refresh token in DB
        const expiresAt = new Date();
        expiresAt.setDate(expiresAt.getDate() + 7);

        await query(
            'INSERT INTO auth_refresh_tokens (user_id, token_hash, expires_at) VALUES ($1, $2, $3)',
            [user.user_id, refreshToken, expiresAt] // Normally we should hash the refresh token too
        );

        res.cookie('accessToken', accessToken, {
            httpOnly: true,
            secure: process.env.NODE_ENV === 'production',
            sameSite: 'strict',
            maxAge: 15 * 60 * 1000, // 15 mins
        });

        res.json({
            message: 'Login successful',
            user: {
                userId: user.user_id,
                username: user.username,
                email: user.email,
                fullName: user.full_name,
            },
            refreshToken // Still return refresh token for client to store (optional if using cookies for everything)
        });
    } catch (error) {
        if (error instanceof z.ZodError) {
            return res.status(400).json({ errors: error.errors });
        }
        console.error('Login error:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
};

export const logout = async (req, res) => {
    const { refreshToken } = req.body;
    if (refreshToken) {
        await query('DELETE FROM auth_refresh_tokens WHERE token_hash = $1', [refreshToken]);
    }
    res.clearCookie('accessToken');
    res.json({ message: 'Logged out successfully' });
};
