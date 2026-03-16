import { pool } from './db/pool.js';

async function debugUserSearch() {
  const email = 'phankhanhnam22@gmail.com';
  try {
    console.log(`Checking for user: ${email}`);
    const res = await pool.query('SELECT user_id, email, username, role FROM users WHERE email = $1', [email]);
    if (res.rowCount === 0) {
      console.log('❌ User NOT found in database.');
      
      const allUsers = await pool.query('SELECT email FROM users LIMIT 5');
      console.log('Recent users in DB:', allUsers.rows.map(r => r.email));
    } else {
      console.log('✅ User found:', res.rows[0]);
    }

    // Test the search logic used in admin.service.js
    const searchPattern = `%${email}%`;
    const searchRes = await pool.query(`
        SELECT u.user_id, u.username, u.email
        FROM users u
        WHERE u.email ILIKE $1 OR u.username ILIKE $1 OR u.full_name ILIKE $1
    `, [searchPattern]);
    console.log('Search results with pattern:', searchRes.rows);

  } catch (err) {
    console.error('Database Error:', err);
  } finally {
    process.exit();
  }
}

debugUserSearch();
