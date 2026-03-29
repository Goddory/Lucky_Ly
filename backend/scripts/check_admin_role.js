import { pool } from '../src/db/pool.js';
async function checkRole() {
  const result = await pool.query("SELECT role FROM users WHERE email = 'admin@gmail.com'");
  console.log('Role list for admin@gmail.com:', result.rows);
  process.exit(0);
}
checkRole();
