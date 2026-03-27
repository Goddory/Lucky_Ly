import crypto from 'crypto';
import { env } from '../config/env.js';

/**
 * Creates a MoMo payment request
 * @param {Object} orderInfo - Information about the order
 * @param {string} orderInfo.orderId - Unique order ID
 * @param {string} orderInfo.orderInfo - Order description
 * @param {number} orderInfo.amount - Amount in VND
 * @returns {Promise<Object>} MoMo API response containing payUrl
 */
export const createMoMoPayment = async ({ orderId, orderInfo, amount }) => {
  const { partnerCode, accessKey, secretKey, apiUrl, redirectUrl, ipnUrl } = env.momo;
  const requestId = orderId;
  const requestType = "captureWallet";
  const extraData = "";
  const amountStr = amount.toString();

  // Signature: accessKey=$accessKey&amount=$amount&extraData=$extraData&ipnUrl=$ipnUrl&orderId=$orderId&orderInfo=$orderInfo&partnerCode=$partnerCode&redirectUrl=$redirectUrl&requestId=$requestId&requestType=$requestType
  const rawSignature = `accessKey=${accessKey}&amount=${amountStr}&extraData=${extraData}&ipnUrl=${ipnUrl}&orderId=${orderId}&orderInfo=${orderInfo}&partnerCode=${partnerCode}&redirectUrl=${redirectUrl}&requestId=${requestId}&requestType=${requestType}`;
  
  const signature = crypto.createHmac('sha256', secretKey)
    .update(rawSignature)
    .digest('hex');

  const requestBody = {
    partnerCode,
    accessKey,
    requestId,
    amount: amountStr,
    orderId,
    orderInfo,
    redirectUrl,
    ipnUrl,
    extraData,
    requestType,
    signature,
    lang: 'en'
  };

  try {
    const response = await fetch(env.momo.apiUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
      },
      body: JSON.stringify(requestBody)
    });

    const text = await response.text();
    let data;
    try {
      data = JSON.parse(text);
    } catch (e) {
      console.error('MoMo Response is not JSON:', text);
      const err = new Error('MoMo payment provider returned an invalid response');
      err.statusCode = 502;
      err.details = text.substring(0, 200);
      throw err;
    }
    
    if (data.resultCode !== 0) {
      const err = new Error(`MoMo Error: ${data.message}`);
      err.statusCode = 400;
      err.resultCode = data.resultCode;
      throw err;
    }

    return data;
  } catch (error) {
    if (!error.statusCode) {
      console.error('MoMo Payment Creation failed:', error);
      error.statusCode = 503;
      error.message = 'MoMo payment service is temporarily unavailable';
    }
    throw error;
  }
};
