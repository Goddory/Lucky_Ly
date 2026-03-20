import pg from 'pg';
const pool = new pg.Pool({ user: 'postgres', host: 'localhost', database: 'luckly', password: 'manhle2425@', port: 5432 });

async function run() {
    try {
        await pool.query(`
            CREATE TABLE IF NOT EXISTS events (
                id SERIAL PRIMARY KEY,
                user_id INTEGER,
                title VARCHAR(255) NOT NULL,
                date TIMESTAMP WITH TIME ZONE NOT NULL,
                type VARCHAR(50) DEFAULT 'personal_note',
                note TEXT,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );
        `);
        console.log("Events table created successfully.");
    } catch (e) {
        console.error(e);
    } finally {
        pool.end();
    }
}

run();
