import { pool } from './src/db/pool.js';

async function fix() {
  try {
    await pool.query('ALTER TABLE transactions ADD COLUMN IF NOT EXISTS provider VARCHAR(20) DEFAULT \'vnpay\'');
    console.log("Column provider added successfully");
  } catch(e) {
    console.error(e);
  } finally {
    process.exit(0);
  }
}

fix();
