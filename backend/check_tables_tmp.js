import { pool } from './src/db/pool.js';

async function checkTables() {
  const tables = ['users', 'transactions', 'wallets'];
  for (const table of tables) {
    try {
      const res = await pool.query(`SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_name = $1)`, [table]);
      console.log(`Table '${table}' exists: ${res.rows[0].exists}`);
    } catch (e) {
      console.error(`Error checking table '${table}':`, e.message);
    }
  }
  process.exit(0);
}

checkTables();
