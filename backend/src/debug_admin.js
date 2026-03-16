import { pool } from './db/pool.js';
import bcrypt from 'bcrypt';

async function checkAdmin() {
  try {
    const res = await pool.query('SELECT * FROM users WHERE email = $1', ['admin@gmail.com']);
    if (res.rows.length === 0) {
      console.log('❌ Admin user not found in database.');
    } else {
      const user = res.rows[0];
      console.log('✅ Admin user found:');
      console.log('   ID:', user.user_id);
      console.log('   Role:', user.role);
      console.log('   Email:', user.email);
      
      // Verify password
      const passwordMatch = await bcrypt.compare('Luckyly@2016', user.password_hash);
      console.log('   Password verification ("Luckyly@2016"):', passwordMatch ? 'MATCHED' : 'FAILED');
    }
  } catch (err) {
    console.error('❌ Error checking database:', err);
  } finally {
    process.exit();
  }
}

checkAdmin();
