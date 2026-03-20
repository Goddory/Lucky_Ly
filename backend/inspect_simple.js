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

async function run() {
    try {
        console.log('--- START INSPECTION (PAYOS ONLY) ---');
        
        const trans = await pool.query("SELECT * FROM transactions WHERE provider = 'payos' ORDER BY created_at DESC LIMIT 10");
        console.log(`Found ${trans.rowCount} PayOS transactions.`);
        
        trans.rows.forEach((t, i) => {
            console.log(`[${i}] ID: ${t.id}, ORDER_ID: ${t.order_id}, STATUS: ${t.status}, AMOUNT: ${t.amount}, USER: ${t.user_id}, CREATED: ${t.created_at}`);
        });

        process.exit(0);
    } catch (err) {
        console.error('ERROR:', err);
        process.exit(1);
    } finally {
        await pool.end();
    }
}

run();
