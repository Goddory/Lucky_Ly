import pg from 'pg';
import dotenv from 'dotenv';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
dotenv.config({ path: path.join(__dirname, '../.env') });

const { Pool } = pg;

const pool = new Pool({
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    host: process.env.DB_HOST,
    port: process.env.DB_PORT,
    database: process.env.DB_NAME,
    ssl: process.env.DB_SSL === 'true' ? { rejectUnauthorized: false } : false
});

async function runMigration() {
    const migrationPath = path.join(__dirname, '../../database/migration_admin_setup.sql');
    const sql = fs.readFileSync(migrationPath, 'utf8');
    
    console.log('Running migration...');
    const client = await pool.connect();
    try {
        await client.query('BEGIN');
        await client.query(sql);
        await client.query('COMMIT');
        console.log('Migration successful!');
    } catch (err) {
        await client.query('ROLLBACK');
        console.error('Migration failed:', err.message);
        process.exit(1);
    } finally {
        client.release();
        await pool.end();
    }
}

runMigration();
