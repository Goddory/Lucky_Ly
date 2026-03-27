import { pool } from './src/db/pool.js';

async function checkTables() {
  const client = await pool.connect();
  try {
    const res = await client.query(`
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_schema = 'public'
    `);
    console.log('Các bảng hiện có trong Database:');
    res.rows.forEach(row => console.log(`- ${row.table_name}`));
  } catch (err) {
    console.error('Lỗi khi kiểm tra bảng:', err.message);
  } finally {
    client.release();
    await pool.end();
    process.exit(0);
  }
}

checkTables();
