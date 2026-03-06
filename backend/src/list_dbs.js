
import pg from 'pg';
import dotenv from 'dotenv';
const { Pool } = pg;

dotenv.config();

// Connect to 'postgres' database to list other databases
const pool = new Pool({
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    host: process.env.DB_HOST,
    port: process.env.DB_PORT,
    database: 'postgres',
});

async function listDatabases() {
    try {
        const res = await pool.query('SELECT datname FROM pg_database WHERE datistemplate = false;');
        console.log('---DB_LIST_START---');
        console.log(JSON.stringify(res.rows));
        console.log('---DB_LIST_END---');
    } catch (err) {
        console.error('List DB error:', err.message);
    } finally {
        await pool.end();
    }
}

listDatabases();
