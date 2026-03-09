
import pg from 'pg';
import dotenv from 'dotenv';
const { Pool } = pg;

dotenv.config();

const pool = new Pool({
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    host: process.env.DB_HOST,
    port: process.env.DB_PORT,
    database: process.env.DB_NAME,
});

async function checkNullable() {
    try {
        const res = await pool.query(`
            SELECT column_name, is_nullable, column_default 
            FROM information_schema.columns 
            WHERE table_name = 'wallets';
        `);
        console.log('---WALLETS_CONSTRAINTS_START---');
        console.log(JSON.stringify(res.rows));
        console.log('---WALLETS_CONSTRAINTS_END---');
    } catch (err) {
        console.error('Check nullable error:', err.message);
    } finally {
        await pool.end();
    }
}

checkNullable();
