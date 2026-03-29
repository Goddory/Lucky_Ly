import { pool } from '../src/db/pool.js';

async function createPromotionsTables() {
  const client = await pool.connect();
  try {
    console.log('Creating promotions tables...');
    await client.query('BEGIN');

    await client.query(`
      CREATE TABLE IF NOT EXISTS promotions (
          id SERIAL PRIMARY KEY,
          name VARCHAR(255) NOT NULL,
          target_audience VARCHAR(50) DEFAULT 'All',
          discount_type VARCHAR(20) DEFAULT 'Percent',
          discount_value DECIMAL(10, 2) NOT NULL,
          starts_at TIMESTAMP WITH TIME ZONE,
          expires_at TIMESTAMP WITH TIME ZONE,
          created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
      );
    `);

    await client.query(`
      CREATE TABLE IF NOT EXISTS vouchers (
          id SERIAL PRIMARY KEY,
          promotion_id INTEGER REFERENCES promotions(id) ON DELETE CASCADE,
          code VARCHAR(50) UNIQUE NOT NULL,
          max_uses INTEGER DEFAULT 1,
          current_uses INTEGER DEFAULT 0,
          created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
      );
    `);

    await client.query(`
      CREATE TABLE IF NOT EXISTS promotion_usage (
          id SERIAL PRIMARY KEY,
          voucher_id INTEGER REFERENCES vouchers(id) ON DELETE CASCADE,
          user_id UUID REFERENCES users(user_id) ON DELETE CASCADE,
          transaction_id INTEGER REFERENCES transactions(id) ON DELETE CASCADE,
          used_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
      );
    `);

    await client.query('COMMIT');
    console.log('✅ Promotions tables created successfully!');
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('❌ Error creating tables:', err);
  } finally {
    client.release();
    pool.end();
  }
}

createPromotionsTables();
