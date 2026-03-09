
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

async function checkSchema() {
    try {
        const res = await pool.query(`
            SELECT table_name 
            FROM information_schema.tables 
            WHERE table_schema = 'public'
            AND table_name IN ('users', 'wallets', 'auth_refresh_tokens');
        `);
        console.log('---SCHEMA_START---');
        console.log(JSON.stringify(res.rows));
        console.log('---SCHEMA_END---');

        if (res.rows.length > 0) {
            const columns = await pool.query(`
                SELECT table_name, column_name, data_type 
                FROM information_schema.columns 
                WHERE table_name IN ('users', 'wallets');
            `);
            console.log('---COLUMNS_START---');
            console.log(JSON.stringify(columns.rows));
            console.log('---COLUMNS_END---');
        }
    } catch (err) {
        console.error('Schema check error:', err.message);
    } finally {
        await pool.end();
    }
}

checkSchema();
