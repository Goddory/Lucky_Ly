import pg from 'pg';
import dotenv from 'dotenv';
dotenv.config();

const pool = new pg.Pool({
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    host: process.env.DB_HOST,
    port: process.env.DB_PORT,
    database: process.env.DB_NAME,
    ssl: true
});

async function fixSchema() {
    try {
        // Đổi tên cột order_id thành order_code (nếu nó chưa được đổi)
        try {
            await pool.query("ALTER TABLE transactions RENAME COLUMN order_id TO order_code");
            console.log('✅ Đã đổi tên order_id -> order_code');
        } catch (e) {
            console.log('ℹ️ Cột order_code đã tồn tại hoặc không tìm thấy order_id');
        }

        // Thêm cột description nếu chưa có
        await pool.query("ALTER TABLE transactions ADD COLUMN IF NOT EXISTS description TEXT");
        console.log('✅ Đã thêm cột description');

        process.exit(0);
    } catch (err) {
        console.error('Lỗi khi sửa schema:', err.message);
        process.exit(1);
    } finally {
        await pool.end();
    }
}

fixSchema();
