/**
 * Script tạo tài khoản store_creator: lylylylyly@gmail.com / lylylylyly
 * Chạy: node backend/seed_store_creator.js
 */
import 'dotenv/config';
import bcrypt from 'bcrypt';
import pg from 'pg';

const { Pool } = pg;

const pool = new Pool({
  host: process.env.DB_HOST,
  port: Number(process.env.DB_PORT),
  database: process.env.DB_NAME,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  ssl: process.env.DB_SSL === 'true' ? { rejectUnauthorized: false } : false
});

async function seed() {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    const email = 'lylylylyly@gmail.com';
    const password = 'Lylylylyly123!';
    const username = 'store_lylyly';
    const fullName = 'Lucky Ly Store Creator';

    // Check existing
    const existing = await client.query(
      'SELECT user_id FROM users WHERE email = $1 OR username = $2',
      [email, username]
    );

    if (existing.rowCount > 0) {
      // Update role to store_creator
      await client.query(
        "UPDATE users SET role = 'store_creator' WHERE email = $1 OR username = $2",
        [email, username]
      );
      console.log('✅ Updated existing user role to store_creator');
      console.log(`   User ID: ${existing.rows[0].user_id}`);
    } else {
      const passwordHash = await bcrypt.hash(password, 12);
      const result = await client.query(
        `INSERT INTO users (username, password_hash, email, full_name, role)
         VALUES ($1, $2, $3, $4, 'store_creator')
         RETURNING user_id, username, email, role`,
        [username, passwordHash, email, fullName]
      );

      // Create wallet
      await client.query(
        "INSERT INTO wallets (user_id, balance, currency, status) VALUES ($1, 0, 'VND', 'ACTIVE')",
        [result.rows[0].user_id]
      );

      console.log('✅ Created store_creator account:');
      console.log(`   Email: ${email}`);
      console.log(`   Password: ${password}`);
      console.log(`   Username: ${username}`);
      console.log(`   Role: store_creator`);
      console.log(`   User ID: ${result.rows[0].user_id}`);
    }

    await client.query('COMMIT');
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('❌ Error:', err.message);
  } finally {
    client.release();
    await pool.end();
  }
}

seed();
