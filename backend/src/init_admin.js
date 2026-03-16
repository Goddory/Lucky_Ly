import { pool } from './db/pool.js';
import bcrypt from 'bcrypt';
import { env } from './config/env.js';

async function initAdmin() {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    const email = 'admin@gmail.com';
    const username = 'admin';
    const fullName = 'System Administrator';
    const password = 'Luckyly@2016';
    const role = 'ADMIN';

    // Check if exists
    const existing = await client.query('SELECT user_id FROM users WHERE email = $1', [email]);
    if (existing.rows.length > 0) {
      console.log('Admin user already exists. Updating role to ADMIN...');
      await client.query('UPDATE users SET role = $1 WHERE email = $2', [role, email]);
    } else {
      console.log('Creating admin user...');
      const passwordHash = await bcrypt.hash(password, 10);
      const insertUserRes = await client.query(
        `INSERT INTO users (username, password_hash, email, full_name, role) 
         VALUES ($1, $2, $3, $4, $5) 
         RETURNING user_id`,
        [username, passwordHash, email, fullName, role]
      );
      
      const userId = insertUserRes.rows[0].user_id;
      
      // Create wallet
      console.log('Creating admin wallet...');
      await client.query(
        'INSERT INTO wallets (user_id, balance, currency, status) VALUES ($1, 0, $2, $3)',
        [userId, 'VND', 'ACTIVE']
      );
    }

    await client.query('COMMIT');
    console.log('✅ Admin initialization successful!');
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('❌ Error initializing admin:', err);
  } finally {
    client.release();
    process.exit();
  }
}

initAdmin();
