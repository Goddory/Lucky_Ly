import cors from 'cors';
import express from 'express';
import path from 'path';
import { fileURLToPath } from 'url';
import helmet from 'helmet';
import rateLimit from 'express-rate-limit';
import { ZodError } from 'zod';
import { env } from './config/env.js';
import { errorHandler, notFoundHandler } from './db/middlewares/errorHandler.js';
import { activityLogger } from './middleware/logger.js';
import authRoutes from './modules/auth/auth.routes.js';
import userRoutes from './modules/user/user.routes.js';
import designRoutes from './modules/designs/designs.routes.js';
import syncRoutes from './routes/sync.routes.js';
import eventsRoutes from './modules/events/events.routes.js';
import statsRoutes from './modules/stats/stats.routes.js';
import themeRoutes from './modules/theme/theme.routes.js';
import giftsRoutes from './modules/gifts/gifts.routes.js';

const app = express();

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

app.set('trust proxy', 1);
app.use(helmet({
  crossOriginResourcePolicy: false,
}));
app.use(
  cors({
    origin: '*', // Cho phép mọi nguồn (đặc biệt là WebView localhost)
    credentials: false
  })
);

// Phục vụ statics từ assets folder của Flutter app
app.use('/assets', express.static(path.join(__dirname, '../lucky_ly_mobile/assets')));
app.use(express.json({ limit: '100kb' }));

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

app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/designs', designRoutes);
app.use('/api/sync', syncRoutes);
app.use('/api/events', eventsRoutes);
app.use('/api/stats', statsRoutes);
app.use('/api/theme', themeRoutes);
app.use('/api/gifts', giftsRoutes);

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
