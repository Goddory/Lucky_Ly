import fs from 'fs';
import path from 'path';
import dns from 'dns';
import net from 'net';
import { fileURLToPath } from 'url';
import dotenv from 'dotenv';
import sqlite3 from 'sqlite3';
import pg from 'pg';

const { Pool } = pg;

dotenv.config();

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

function withTimeout(promise, ms, label) {
  return new Promise((resolve, reject) => {
    const timer = setTimeout(() => {
      reject(new Error(`${label} timed out after ${ms}ms`));
    }, ms);

    promise
      .then((value) => {
        clearTimeout(timer);
        resolve(value);
      })
      .catch((error) => {
        clearTimeout(timer);
        reject(error);
      });
  });
}

function trimErrorMessage(error) {
  if (!error) return 'Unknown error';
  const message = typeof error === 'string' ? error : error.message || String(error);
  return message.replace(/\s+/g, ' ').trim();
}

async function checkSqlite() {
  const dbPath = path.resolve(__dirname, '../database/lucky_ly.sqlite');
  const dbDir = path.dirname(dbPath);

  if (!fs.existsSync(dbDir)) {
    fs.mkdirSync(dbDir, { recursive: true });
  }

  sqlite3.verbose();

  const db = await withTimeout(
    new Promise((resolve, reject) => {
      const instance = new sqlite3.Database(
        dbPath,
        sqlite3.OPEN_READWRITE | sqlite3.OPEN_CREATE,
        (err) => {
          if (err) {
            return reject(err);
          }
          return resolve(instance);
        }
      );
    }),
    8000,
    'SQLite connect'
  );

  try {
    await withTimeout(
      new Promise((resolve, reject) => {
        db.get('SELECT 1 AS ok', [], (err, row) => {
          if (err) {
            return reject(err);
          }
          if (!row || row.ok !== 1) {
            return reject(new Error('Unexpected SQLite query result'));
          }
          return resolve();
        });
      }),
      5000,
      'SQLite query'
    );

    return {
      ok: true,
      detail: `connected and query ok (db: ${dbPath})`
    };
  } finally {
    await new Promise((resolve) => {
      db.close(() => resolve());
    });
  }
}

function getMissingPostgresEnv() {
  const required = ['DB_HOST', 'DB_PORT', 'DB_NAME', 'DB_USER', 'DB_PASSWORD'];
  return required.filter((key) => !process.env[key]);
}

async function checkPostgres() {
  const missing = getMissingPostgresEnv();
  if (missing.length > 0) {
    throw new Error(`missing env: ${missing.join(', ')}`);
  }

  const pool = new Pool({
    host: process.env.DB_HOST,
    port: Number(process.env.DB_PORT),
    database: process.env.DB_NAME,
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    ssl: process.env.DB_SSL === 'true' ? { rejectUnauthorized: false } : false,
    connectionTimeoutMillis: 10000
  });

  let client;
  try {
    client = await withTimeout(pool.connect(), 12000, 'PostgreSQL connect');
    const res = await withTimeout(client.query('SELECT 1 AS ok'), 5000, 'PostgreSQL query');

    if (!res.rows?.length || res.rows[0].ok !== 1) {
      throw new Error('Unexpected PostgreSQL query result');
    }

    return {
      ok: true,
      detail: `connected to ${process.env.DB_HOST}:${process.env.DB_PORT}/${process.env.DB_NAME}`
    };
  } finally {
    if (client) {
      client.release();
    }
    await pool.end();
  }
}

async function resolveMongoTarget(mongoUri) {
  if (mongoUri.startsWith('mongodb+srv://')) {
    const url = new URL(mongoUri.replace('mongodb+srv://', 'https://'));
    const rootHost = url.hostname;
    const srvRecords = await dns.promises.resolveSrv(`_mongodb._tcp.${rootHost}`);

    if (!srvRecords.length) {
      throw new Error(`no SRV record found for ${rootHost}`);
    }

    const first = srvRecords[0];
    return {
      host: first.name.replace(/\.$/, ''),
      port: Number(first.port) || 27017,
      mode: 'mongodb+srv'
    };
  }

  if (mongoUri.startsWith('mongodb://')) {
    const withoutScheme = mongoUri.slice('mongodb://'.length);
    const authority = withoutScheme.split('/')[0];
    const hostList = authority.includes('@')
      ? authority.slice(authority.lastIndexOf('@') + 1)
      : authority;

    const firstHost = hostList.split(',')[0];
    const [host, portRaw] = firstHost.split(':');

    if (!host) {
      throw new Error('cannot parse host from MongoDB URI');
    }

    return {
      host,
      port: Number(portRaw) || 27017,
      mode: 'mongodb'
    };
  }

  throw new Error('unsupported MongoDB URI format');
}

function testTcpConnection(host, port) {
  return new Promise((resolve, reject) => {
    const socket = new net.Socket();

    socket.once('error', (err) => {
      socket.destroy();
      reject(err);
    });

    socket.connect(port, host, () => {
      socket.end();
      resolve();
    });
  });
}

async function checkMongo() {
  const mongoUri = process.env.MONGO_URI;
  if (!mongoUri) {
    throw new Error('missing env: MONGO_URI');
  }

  const target = await resolveMongoTarget(mongoUri);
  await withTimeout(testTcpConnection(target.host, target.port), 12000, 'MongoDB TCP connect');

  return {
    ok: true,
    detail: `reachable at ${target.host}:${target.port} (${target.mode})`
  };
}

async function checkSendGrid() {
  const apiKey = process.env.SENDGRID_API_KEY;
  if (!apiKey) {
    throw new Error('missing env: SENDGRID_API_KEY');
  }

  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 12000);

  try {
    const response = await fetch('https://api.sendgrid.com/v3/user/account', {
      method: 'GET',
      headers: {
        Authorization: `Bearer ${apiKey}`,
        'Content-Type': 'application/json'
      },
      signal: controller.signal
    });

    const bodyText = await response.text();

    if (!response.ok) {
      const compactBody = bodyText.replace(/\s+/g, ' ').trim();
      throw new Error(`HTTP ${response.status} ${response.statusText} ${compactBody}`);
    }

    return {
      ok: true,
      detail: 'reachable and API key accepted'
    };
  } finally {
    clearTimeout(timeout);
  }
}

async function runCheck(name, checkFn) {
  process.stdout.write(`- ${name}: `);
  try {
    const result = await checkFn();
    console.log(`OK (${result.detail})`);
    return { name, ok: true, detail: result.detail };
  } catch (error) {
    const message = trimErrorMessage(error);
    console.log(`FAILED (${message})`);
    return { name, ok: false, detail: message };
  }
}

async function main() {
  console.log('========================================');
  console.log(' Lucky Ly - Cloud/Database Connectivity');
  console.log('========================================');

  const results = [];
  results.push(await runCheck('SQLite', checkSqlite));
  results.push(await runCheck('PostgreSQL', checkPostgres));
  results.push(await runCheck('MongoDB', checkMongo));
  results.push(await runCheck('SendGrid', checkSendGrid));

  const failed = results.filter((item) => !item.ok);

  console.log('');
  if (failed.length === 0) {
    console.log('RESULT: ALL CONNECTION CHECKS PASSED');
    process.exitCode = 0;
    return;
  }

  console.log('RESULT: CONNECTION CHECK FAILED');
  for (const item of failed) {
    console.log(`  * ${item.name}: ${item.detail}`);
  }
  process.exitCode = 1;
}

main().catch((error) => {
  console.error('Unexpected check failure:', trimErrorMessage(error));
  process.exitCode = 1;
});
