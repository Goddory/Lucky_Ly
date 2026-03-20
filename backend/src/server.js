import app from './app.js';
import { env } from './config/env.js';
import { pool } from './db/pool.js';
import connectMongo from './database/mongo_client.js';
import mongoose from 'mongoose';

// Bắt lỗi toàn cục để tránh crash server
process.on('unhandledRejection', (reason, promise) => {
    console.error('Unhandled Rejection at:', promise, 'reason:', reason);
});

process.on('uncaughtException', (err) => {
    console.error('Uncaught Exception:', err);
});

mongoose.connection.on('error', (err) => {
    console.error('Mongoose connection error:', err);
});

// Hàm khởi động ứng dụng: kiểm tra kết nối DB trước khi mở cổng HTTP.
async function start() {
  try {
    await pool.query('SELECT 1');
    console.log('✅ Connected to Neon PostgreSQL successfully');
    
    // Khởi tạo MongoDB (Tạm thời tắt để phục vụ thanh toán k bị crash)
    /*
    try {
      await connectMongo();
    } catch(e) {
      console.error('❌ MongoDB Connection Error:', e);
    }
    */
    
    app.listen(env.port, () => {
      console.log(`Auth API running on port ${env.port}`);
    });
  } catch (err) {
    console.error('Failed to connect to primary PostgreSQL:', err);
    process.exit(1);
  }
}

start();
