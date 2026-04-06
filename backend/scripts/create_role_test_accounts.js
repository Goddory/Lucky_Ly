import 'dotenv/config';
import bcrypt from 'bcrypt';
import pg from 'pg';

const { Pool } = pg;

const pool = new Pool({
  host: process.env.DB_HOST,
  port: Number(process.env.DB_PORT || 5432),
  database: process.env.DB_NAME,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  ssl: process.env.DB_SSL === 'true' ? { rejectUnauthorized: false } : false,
});

const testAccounts = [
  {
    role: 'admin',
    email: 'admin.test@luckyly.com',
    username: 'admin_test',
    fullName: 'LuckyLy Admin Test',
    password: 'Admin123!',
  },
  {
    role: 'user',
    email: 'user.test@luckyly.com',
    username: 'user_test',
    fullName: 'LuckyLy User Test',
    password: 'User123!',
  },
  {
    role: 'marketing_admin',
    email: 'marketing.test@luckyly.com',
    username: 'marketing_test',
    fullName: 'LuckyLy Marketing Test',
    password: 'Marketing123!',
  },
  {
    role: 'store_creator',
    email: 'store.test@luckyly.com',
    username: 'store_test',
    fullName: 'LuckyLy Store Creator Test',
    password: 'Store123!',
  },
];

async function upsertTestAccount(client, account, bcryptRounds) {
  const passwordHash = await bcrypt.hash(account.password, bcryptRounds);

  const existing = await client.query(
    `SELECT user_id FROM users WHERE email = $1 OR username = $2 LIMIT 1`,
    [account.email, account.username],
  );

  let userId;

  if (existing.rowCount > 0) {
    userId = existing.rows[0].user_id;

    await client.query(
      `UPDATE users
       SET email = $1,
           username = $2,
           full_name = $3,
           role = $4,
           password_hash = $5,
           is_active = TRUE
       WHERE user_id = $6`,
      [
        account.email,
        account.username,
        account.fullName,
        account.role,
        passwordHash,
        userId,
      ],
    );
  } else {
    const inserted = await client.query(
      `INSERT INTO users (username, password_hash, email, full_name, role, is_active)
       VALUES ($1, $2, $3, $4, $5, TRUE)
       RETURNING user_id`,
      [
        account.username,
        passwordHash,
        account.email,
        account.fullName,
        account.role,
      ],
    );

    userId = inserted.rows[0].user_id;
  }

  await client.query(
    `INSERT INTO wallets (user_id, balance, currency, status)
     SELECT $1, 0, 'VND', 'ACTIVE'
     WHERE NOT EXISTS (
       SELECT 1 FROM wallets WHERE user_id = $1
     )`,
    [userId],
  );

  return { userId, ...account };
}

async function createRoleTestAccounts() {
  const client = await pool.connect();
  const bcryptRounds = Number(process.env.BCRYPT_ROUNDS || 12);

  try {
    await client.query('BEGIN');

    const created = [];
    for (const account of testAccounts) {
      const result = await upsertTestAccount(client, account, bcryptRounds);
      created.push(result);
    }

    await client.query('COMMIT');

    console.log('=== ROLE TEST ACCOUNTS READY ===');
    for (const acc of created) {
      console.log(`Role: ${acc.role}`);
      console.log(`  Email: ${acc.email}`);
      console.log(`  Username: ${acc.username}`);
      console.log(`  Password: ${acc.password}`);
      console.log(`  User ID: ${acc.userId}`);
    }
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('Failed to create role test accounts:', error.message);
    process.exitCode = 1;
  } finally {
    client.release();
    await pool.end();
  }
}

createRoleTestAccounts();
