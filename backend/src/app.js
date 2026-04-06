import cors from 'cors';
import express from 'express';
import helmet from 'helmet';
import rateLimit from 'express-rate-limit';
import cookieParser from 'cookie-parser';
import { mkdirSync } from 'fs';
import { ZodError } from 'zod';
import { env } from './config/env.js';
import { errorHandler, notFoundHandler } from './db/middlewares/errorHandler.js';
import { activityLogger } from './middleware/logger.js';
import authRoutes from './modules/auth/auth.routes.js';
import userRoutes from './modules/user/user.routes.js';
import designRoutes from './modules/designs/designs.routes.js';
import syncRoutes from './routes/sync.routes.js';
import paymentRoutes from './modules/payment/payment.routes.js';
import eventsRoutes from './modules/events/events.routes.js';
import statsRoutes from './modules/stats/stats.routes.js';
import themeRoutes from './modules/theme/theme.routes.js';
import giftsRoutes from './modules/gifts/gifts.routes.js';
import storeRoutes from './modules/store/store.routes.js';
import friendsRoutes from './modules/friends/friends.routes.js';
import chatRoutes from './modules/chat/chat.routes.js';
import promotionsRoutes from './modules/promotions/promotions.routes.js';
import studentVerificationRoutes from './modules/student-verification/student-verification.routes.js';

const app = express();

// Ensure upload directories exist
mkdirSync('uploads/store', { recursive: true });

app.use((req, res, next) => {
  console.log(`[${new Date().toISOString()}] ${req.method} ${req.url}`);
  console.log(`DEBUG: Auth Header: ${req.headers.authorization}`);
  console.log(`DEBUG: All Cookies: ${JSON.stringify(req.cookies || {})}`);
  next();
});

app.set('trust proxy', 1);
// app.use(helmet());
app.use(
  cors({
    origin: (origin, callback) => {
      // Allow all origins for development
      callback(null, true);
    },
    methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization', 'Accept'],
    credentials: true,
    optionsSuccessStatus: 200
  })
);
app.use(express.json({ limit: '100kb' }));
app.use(cookieParser());

// Global console logger for all activities
app.use(activityLogger);

const globalLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 200,
  standardHeaders: true,
  legacyHeaders: false,
  message: { message: 'Too many requests, please try again later.' }
});
app.use(globalLimiter);

app.get('/api/health', (req, res) => {
  res.status(200).json({ status: 'ok' });
});

app.use('/uploads', express.static('uploads'));
app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/designs', designRoutes);
app.use('/api/sync', syncRoutes);
app.use('/api/payment', paymentRoutes);
app.use('/api/events', eventsRoutes);
app.use('/api/stats', statsRoutes);
app.use('/api/theme', themeRoutes);
app.use('/api/gifts', giftsRoutes);
app.use('/api/friends', friendsRoutes);
app.use('/api/chat', chatRoutes);
app.use('/api/store', storeRoutes);
app.use('/api/promotions', promotionsRoutes);
app.use('/api/student-verification', studentVerificationRoutes);

app.use(notFoundHandler);

// Middleware bắt lỗi validate từ Zod và chuẩn hóa định dạng lỗi trả về client.
app.use((err, req, res, next) => {
  if (err instanceof ZodError) {
    return res.status(400).json({
      message: 'Validation failed',
      errors: err.issues.map((issue) => ({
        field: issue.path.join('.'),
        message: issue.message
      }))
    });
  }

  return errorHandler(err, req, res, next);
});

export default app;
