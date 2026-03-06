
import pg from 'pg';
import dotenv from 'dotenv';
const { Pool } = pg;

dotenv.config({ path: '../.env' });

async function testConnection() {
    const configs = [
        { user: process.env.DB_USER, password: process.env.DB_PASSWORD },
        { user: 'postgres', password: '' },
        { user: 'postgres', password: 'password' },
        { user: 'postgres', password: '123' },
    ];

    for (const config of configs) {
        console.log(`Testing with user: ${config.user}, password: ${config.password ? '****' : '(empty)'}`);
        const pool = new Pool({
            user: config.user,
            password: config.password,
            host: process.env.DB_HOST || 'localhost',
            port: process.env.DB_PORT || 5432,
            database: process.env.DB_NAME || 'lucky_ly',
        });

        try {
            const client = await pool.connect();
            console.log('SUCCESS: Connected to database!');
            client.release();
            await pool.end();
            return config;
        } catch (err) {
            console.log(`FAILED: ${err.message}`);
            await pool.end();
        }
    }
    return null;
}

testConnection().then(config => {
    if (config) {
        console.log('---RESULT_START---');
        console.log(JSON.stringify(config));
        console.log('---RESULT_END---');
    } else {
        console.log('---RESULT_NONE---');
    }
});
