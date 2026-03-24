import https from 'https';
import crypto from 'crypto';
import { env } from './src/config/env.js';

const { partnerCode, accessKey, secretKey, apiUrl, redirectUrl, ipnUrl } = env.momo;
const orderId = 'TEST' + Date.now();
const requestId = orderId;
const amount = "50000";
const orderInfo = "Test";
const requestType = "captureWallet";
const extraData = "";

const rawSignature = `accessKey=${accessKey}&amount=${amount}&extraData=${extraData}&ipnUrl=${ipnUrl}&orderId=${orderId}&orderInfo=${orderInfo}&partnerCode=${partnerCode}&redirectUrl=${redirectUrl}&requestId=${requestId}&requestType=${requestType}`;
const signature = crypto.createHmac('sha256', secretKey).update(rawSignature).digest('hex');

const body = JSON.stringify({
    partnerCode, accessKey, requestId, amount, orderId, orderInfo, redirectUrl, ipnUrl, extraData, requestType, signature, lang: 'en'
});

const options = {
    method: 'POST',
    headers: {
        'Content-Type': 'application/json',
        'Content-Length': body.length
    }
};

const req = https.request(apiUrl, options, (res) => {
    let data = '';
    res.on('data', (chunk) => data += chunk);
    res.on('end', () => {
        console.log('Status:', res.statusCode);
        console.log('Body:', data);
    });
});

req.on('error', (e) => console.error(e));
req.write(body);
req.end();
