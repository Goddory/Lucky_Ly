import http from 'http';
import app from './app.js';
import { env } from './config/env.js';
import { pool } from './db/pool.js';
import connectMongo from './database/mongo_client.js';
import { initSocketServer } from './sockets/chat.socket.js';
import { initFirebase } from './services/notification.service.js';
import './config/sqlite.js';

async function start() {
  try {
    await pool.query('SELECT 1');
    console.log('✅ Connected to Neon PostgreSQL successfully');

    // MongoDB (optional)
    try {
      const mongoResult = await connectMongo();
      if (mongoResult?.connected) {
        console.log('✅ Connected to MongoDB successfully');
      } else {
        console.error(`⚠️ MongoDB Connection Failed (Proceeding without Mongo): ${mongoResult?.reason || 'unknown reason'}`);
      }
    } catch (e) {
      console.error('⚠️ MongoDB Connection Failed (Proceeding without Mongo):', e?.message || e);
    }
    
    // Firebase Admin SDK (optional, for push notifications)
    initFirebase();

    // Create HTTP server and attach Socket.io
    const server = http.createServer(app);
    initSocketServer(server);
    console.log('✅ Socket.io server attached');

    server.listen(env.port, '0.0.0.0', () => {
      console.log(`Auth API running on port ${env.port}`);
    });
  } catch (err) {
    console.error('Failed to connect to primary PostgreSQL:', err);
    process.exit(1);
  }
}

start();
