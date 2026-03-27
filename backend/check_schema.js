import { pool } from './src/db/pool.js';

async function check() {
  try {
    const res = await pool.query(`
      SELECT column_name, is_nullable, column_default, data_type 
      FROM information_schema.columns 
      WHERE table_name = 'transactions'
    `);
    res.rows.forEach(row => {
      console.log(`${row.column_name}: nullable=${row.is_nullable}, default=${row.column_default}, type=${row.data_type}`);
    });
  } catch (err) {
    console.error(err);
  } finally {
    process.exit();
  }
}

check();
