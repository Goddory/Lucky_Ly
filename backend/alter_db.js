import pg from 'pg';
const pool = new pg.Pool({ user: 'postgres', host: 'localhost', database: 'luckly', password: 'manhle2425@', port: 5432 });

async function run() {
    try {
        await pool.query("ALTER TABLE users ADD COLUMN IF NOT EXISTS facebook_id VARCHAR(255) UNIQUE;");
        await pool.query("ALTER TABLE users ALTER COLUMN password_hash DROP NOT NULL;");
        console.log("Database altered successfully.");
    } catch (e) {
        console.error(e);
    } finally {
        pool.end();
    }
}

run();
