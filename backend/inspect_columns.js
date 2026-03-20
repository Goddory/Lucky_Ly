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

async function inspectColumns() {
    try {
        const res = await pool.query("SELECT column_name FROM information_schema.columns WHERE table_name = 'transactions' ORDER BY ordinal_position");
        console.log('--- DANH SÁCH CỘT THỰC TẾ TRONG BẢNG TRANSACTIONS ---');
        res.rows.forEach(row => console.log(' - ' + row.column_name));
        process.exit(0);
    } catch (err) {
        console.error('Lỗi khi truy vấn:', err.message);
        process.exit(1);
    } finally {
        await pool.end();
    }
}

inspectColumns();
