import { pool } from './pool.js';

async function migrate() {
  try {
    await pool.query(`
      ALTER TABLE users 
      ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT true,
      ADD COLUMN IF NOT EXISTS role VARCHAR(50) DEFAULT 'user';
    `);
    console.log('Columns is_active and role added successfully or already exist.');
  } catch (error) {
    console.error('Migration error:', error.message);
  } finally {
    process.exit(0);
  }
}

migrate();
