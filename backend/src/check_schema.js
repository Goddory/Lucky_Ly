import { pool } from './db/pool.js';

async function checkSchema() {
  try {
    const res = await pool.query(`
      SELECT column_name, data_type 
      FROM information_schema.columns 
      WHERE table_name = 'users'
    `);
    console.log('Users table columns:');
    res.rows.forEach(row => console.log(`- ${row.column_name}: ${row.data_type}`));
    
    const walletRes = await pool.query(`
      SELECT column_name, data_type 
      FROM information_schema.columns 
      WHERE table_name = 'wallets'
    `);
    console.log('\nWallets table columns:');
    walletRes.rows.forEach(row => console.log(`- ${row.column_name}: ${row.data_type}`));

  } catch (err) {
    console.error(err);
  } finally {
    process.exit();
  }
}

checkSchema();
