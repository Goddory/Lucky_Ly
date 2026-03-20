import pg from 'pg';
import dotenv from 'dotenv';
dotenv.config();

const pool = new pg.Pool({
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    host: process.env.DB_HOST,
    port: process.env.DB_PORT,
    database: process.env.DB_NAME,
    ssl: { rejectUnauthorized: false }
});

async function inspectTable() {
    try {
        console.log('--- TRANSACTIONS COLUMNS ---');
        const res = await pool.query(`
            SELECT column_name, data_type
            FROM information_schema.columns 
            WHERE table_name = 'transactions'
            ORDER BY ordinal_position
        `);
        console.log(JSON.stringify(res.rows, null, 2));

        console.log('--- WALLETS COLUMNS ---');
        const resWallet = await pool.query(`
            SELECT column_name, data_type
            FROM information_schema.columns 
            WHERE table_name = 'wallets'
            ORDER BY ordinal_position
        `);
        console.log(JSON.stringify(resWallet.rows, null, 2));
        
        const latestTrans = await pool.query('SELECT * FROM transactions ORDER BY created_at DESC LIMIT 10');
        console.log('--- LATEST TRANSACTIONS ---');
        console.log(JSON.stringify(latestTrans.rows, null, 2));

        process.exit(0);
    } catch (err) {
        console.error('Lỗi khi truy vấn:', err.message);
        process.exit(1);
    } finally {
        await pool.end();
    }
}

inspectTable();
