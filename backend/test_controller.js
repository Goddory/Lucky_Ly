import { pool } from './src/db/pool.js';

async function testController() {
  try {
    await pool.query("DROP TABLE IF EXISTS transactions CASCADE;");
    await pool.query(`
    CREATE TABLE IF NOT EXISTS transactions (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      user_id UUID REFERENCES users(user_id) ON DELETE CASCADE,
      order_id VARCHAR(50) UNIQUE NOT NULL,
      amount INTEGER NOT NULL,
      type VARCHAR(20) DEFAULT 'deposit',
      provider VARCHAR(20) NOT NULL,
      status VARCHAR(20) DEFAULT 'pending',
      created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
      updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
    );
    `);
    console.log("Recreated transactions table successfully");
  } catch (error) {
    console.error("ERROR:", error);
  } finally {
    process.exit(0);
  }
}

testController();
