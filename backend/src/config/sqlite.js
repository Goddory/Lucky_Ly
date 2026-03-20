const path = require('path');
const sqlite3 = require('sqlite3');

// Resolve the database path from environment or fall back to the previous default.
// Using __dirname ensures this is independent of the current working directory.
const DEFAULT_DB_PATH = path.join(__dirname, '../../database/lucky_ly.sqlite');
const DB_PATH = process.env.SQLITE_DB_PATH || DEFAULT_DB_PATH;

/**
 * Holds the active SQLite Database instance once initialized.
 * @type {sqlite3.Database | null}
 */
let db = null;

/**
 * Initialize the SQLite database connection.
 * This function should be awaited during server startup before app.listen().
 *
 * @returns {Promise<sqlite3.Database>}
 */
async function initSqlite() {
  if (db) {
    // Already initialized; return existing instance.
    return db;
  }

  sqlite3.verbose();

  return new Promise((resolve, reject) => {
    const instance = new sqlite3.Database(DB_PATH, (err) => {
      if (err) {
        return reject(err);
      }
      db = instance;
      resolve(db);
    });
  });
}

/**
 * Get the initialized SQLite Database instance.
 * Throws if initSqlite() has not been successfully called yet.
 *
 * @returns {sqlite3.Database}
 */
function getDb() {
  if (!db) {
    throw new Error('SQLite database has not been initialized. Call initSqlite() before using getDb().');
  }
  return db;
}

module.exports = {
  initSqlite,
  getDb,
};
import sqlite3 from 'sqlite3';
import path from 'path';
import { fileURLToPath } from 'url';
import fs from 'fs';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const dbPath = path.resolve(__dirname, '../../database/lucky_ly.sqlite');

// Create database directory if it doesn't exist
const dbDir = path.dirname(dbPath);
if (!fs.existsSync(dbDir)) {
    fs.mkdirSync(dbDir, { recursive: true });
}

export const sqliteDb = new sqlite3.Database(dbPath, (err) => {
    if (err) {
        console.error('❌ Failed to connect to SQLite database:', err.message);
    } else {
        console.log('✅ Connected to SQLite database successfully');
    }
});

export default sqliteDb;
