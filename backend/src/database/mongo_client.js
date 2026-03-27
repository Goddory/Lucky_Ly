import mongoose from 'mongoose';

const RETRYABLE_LABELS = new Set(['RetryableError', 'SystemOverloadedError']);

function isRetryableMongoError(error) {
  if (!error) return false;

  const labels = error.errorLabelSet;
  if (labels && typeof labels.has === 'function') {
    for (const label of RETRYABLE_LABELS) {
      if (labels.has(label)) return true;
    }
  }

  const message = String(error.message || '').toLowerCase();
  return message.includes('timed out') ||
    message.includes('tlsv1 alert internal error') ||
    message.includes('connection') ||
    message.includes('handshake');
}

function compactMongoError(error) {
  return String(error?.message || error || 'Unknown MongoDB error')
    .replace(/\s+/g, ' ')
    .trim();
}

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

const connectMongo = async () => {
  const mongoUri = process.env.MONGO_URI;
  if (!mongoUri) {
    console.warn('⚠️ MONGO_URI is missing in .env. MongoDB will not be connected.');
    return { connected: false, reason: 'MONGO_URI is missing' };
  }

  if (mongoose.connection.readyState === 1) {
    return { connected: true, reason: 'already connected' };
  }

  const maxAttempts = Number(process.env.MONGO_CONNECT_MAX_ATTEMPTS || 4);
  const baseDelayMs = Number(process.env.MONGO_CONNECT_RETRY_DELAY_MS || 1200);

  const connectOptions = {
    serverSelectionTimeoutMS: Number(process.env.MONGO_SERVER_SELECTION_TIMEOUT_MS || 12000),
    connectTimeoutMS: Number(process.env.MONGO_CONNECT_TIMEOUT_MS || 12000),
    socketTimeoutMS: Number(process.env.MONGO_SOCKET_TIMEOUT_MS || 20000),
    maxPoolSize: Number(process.env.MONGO_MAX_POOL_SIZE || 10),
    tls: process.env.MONGO_TLS === 'false' ? false : true,
    retryWrites: true
  };

  const ipFamilyRaw = process.env.MONGO_IP_FAMILY;
  if (ipFamilyRaw === '4' || ipFamilyRaw === '6') {
    connectOptions.family = Number(ipFamilyRaw);
  }

  if (process.env.MONGO_TLS_ALLOW_INVALID_CERTS === 'true') {
    connectOptions.tlsAllowInvalidCertificates = true;
  }

  let lastError = null;

  for (let attempt = 1; attempt <= maxAttempts; attempt += 1) {
    try {
      await mongoose.connect(mongoUri, connectOptions);
      console.log('✅ Connected to MongoDB Desktop/Cloud successfully');
      return { connected: true, reason: 'connected' };
    } catch (error) {
      lastError = error;
      const retryable = isRetryableMongoError(error);
      const isLastAttempt = attempt === maxAttempts;

      console.error(
        `❌ MongoDB connect attempt ${attempt}/${maxAttempts} failed: ${compactMongoError(error)}`
      );

      if (!retryable || isLastAttempt) {
        break;
      }

      const delay = baseDelayMs * attempt;
      console.warn(`↻ Retrying MongoDB connection in ${delay}ms...`);
      await sleep(delay);
    }
  }

  return {
    connected: false,
    reason: compactMongoError(lastError)
  };
};

export default connectMongo;
