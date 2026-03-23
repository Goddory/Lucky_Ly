import app from './app.js';
import { env } from './config/env.js';
import { pool } from './db/pool.js';
import connectMongo from './database/mongo_client.js';
import './config/sqlite.js';

// Hàm khởi động ứng dụng: kiểm tra kết nối DB trước khi mở cổng HTTP.
async function start() {
  try {
    await pool.query('SELECT 1');
    console.log('✅ Connected to Neon PostgreSQL successfully');
    
    // Khởi tạo MongoDB (Không bắt buộc để chạy ứng dụng chính)
    try {
      const mongoResult = await connectMongo();
      if (mongoResult?.connected) {
        console.log('✅ Connected to MongoDB successfully');
      } else {
        console.error(`⚠️ MongoDB Connection Failed (Proceeding without Mongo): ${mongoResult?.reason || 'unknown reason'}`);
      }
    } catch (e) {
      console.error('⚠️ MongoDB Connection Failed (Proceeding without Mongo):', e?.message || e);
    }
    
    app.listen(env.port, '0.0.0.0', () => {
      console.log(`Auth API running on port ${env.port}`);
    });
  } catch (err) {
    console.error('Failed to start server:', err);
    process.exit(1);
  }
}

start();
