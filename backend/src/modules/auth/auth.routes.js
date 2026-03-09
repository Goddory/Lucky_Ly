import { Router } from 'express';
import rateLimit from 'express-rate-limit';
import { facebookLogin, googleLogin, login, logout, refresh, register } from './auth.controller.js';

// Giới hạn tần suất gọi API auth để giảm brute-force/password guessing.
const authRateLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 10,
  standardHeaders: true,
  legacyHeaders: false,
  message: { message: 'Too many auth requests, please try again later.' }
});

// Router gom các endpoint xác thực người dùng.
const router = Router();

router.post('/register', authRateLimiter, register);
router.post('/login', authRateLimiter, login);
router.post('/facebook-login', authRateLimiter, facebookLogin);
router.post('/google', authRateLimiter, googleLogin);
router.post('/refresh', authRateLimiter, refresh);
router.post('/logout', authRateLimiter, logout);

export default router;
