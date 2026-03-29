import { pool } from '../src/db/pool.js';
import bcrypt from 'bcrypt';
import { env } from '../src/config/env.js';

async function createAdmin() {
  const client = await pool.connect();
  try {
    console.log('Connecting to database...');
    
    const email = 'marketing@luckyly.com';
    const username = 'marketing_admin';
    const password = 'Password123!';
    const role = 'marketing_admin';

    // Hash the password
    const passwordHash = await bcrypt.hash(password, env.bcryptRounds || 10);

    const check = await client.query('SELECT user_id FROM users WHERE email = $1', [email]);
    if (check.rowCount > 0) {
      console.log('Account already exists! Updating role and password...');
      await client.query(
        'UPDATE users SET role = $1, password_hash = $2 WHERE email = $3',
        [role, passwordHash, email]
      );
      console.log('Account updated successfully!');
      return;
    }

    // Insert new user
    const insertRes = await client.query(`
      INSERT INTO users (username, password_hash, email, full_name, role)
      VALUES ($1, $2, $3, $4, $5)
      RETURNING user_id, username, email, role
    `, [username, passwordHash, email, 'Marketing Admin', role]);

    const user = insertRes.rows[0];

    // Create wallet for the user
    await client.query('INSERT INTO wallets (user_id, balance, currency, status) VALUES ($1, 0, $2, $3)', [
      user.user_id,
      'VND',
      'ACTIVE'
    ]);

    console.log('✅ Marketing Admin account created successfully:');
    console.log(`- Username/Email: ${email}`);
    console.log(`- Password: ${password}`);
    console.log(`- Role: ${role}`);
    
  } catch (err) {
    console.error('❌ Error creating account:', err);
  } finally {
    client.release();
    pool.end();
  }
}

createAdmin();
