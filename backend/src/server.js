import app from './app.js';
import { env } from './config/env.js';
import { pool } from './db/pool.js';

// Hàm khởi động ứng dụng: kiểm tra kết nối DB trước khi mở cổng HTTP.
async function start() {
  try {
    await pool.query('SELECT 1');
    app.listen(env.port, () => {
      console.log(`Auth API running on port ${env.port}`);
    });
  } catch (err) {
    console.error('Failed to start server:', err);
    process.exit(1);
  }
}

start();
