import crypto from 'crypto';
import qs from 'qs';
import { env } from '../config/env.js';

function sortObject(obj) {
  let sorted = {};
  let str = [];
  let key;
  for (key in obj) {
    if (obj.hasOwnProperty(key)) {
      str.push(encodeURIComponent(key));
    }
  }
  str.sort();
  for (key = 0; key < str.length; key++) {
    sorted[str[key]] = encodeURIComponent(obj[str[key]]).replace(/%20/g, "+");
  }
  return sorted;
}

/**
 * Creates a VNPay payment request URL (Strict v2.1.0 compliance)
 */
export const createVNPayPayment = async ({ orderId, orderInfo, amount, ipAddr = '127.0.0.1' }) => {
  const vnp_TmnCode = env.vnpay.tmnCode || 'MO4V1NJO';
  const vnp_HashSecret = env.vnpay.hashSecret || '8O43F3YO38U2JV5UZDUU4JI6PFW7XLTO';
  const vnp_Url = env.vnpay.url || 'https://sandbox.vnpayment.vn/paymentv2/vpcpay.html';
  const vnp_ReturnUrl = env.vnpay.returnUrl || `http://localhost:${env.port}/api/payment/vnpay/callback`;

  const date = new Date();
  const formatVnpayDate = (date) => {
    const y = date.getFullYear();
    const m = String(date.getMonth() + 1).padStart(2, '0');
    const d = String(date.getDate()).padStart(2, '0');
    const h = String(date.getHours()).padStart(2, '0');
    const min = String(date.getMinutes()).padStart(2, '0');
    const s = String(date.getSeconds()).padStart(2, '0');
    return `${y}${m}${d}${h}${min}${s}`;
  };

  const createDate = formatVnpayDate(date);
  const expireDate = new Date(date.getTime() + 15 * 60000); 
  const vnp_ExpireDate = formatVnpayDate(expireDate);

  let vnp_Params = {};
  vnp_Params['vnp_Version'] = '2.1.0';
  vnp_Params['vnp_Command'] = 'pay';
  vnp_Params['vnp_TmnCode'] = vnp_TmnCode;
  vnp_Params['vnp_Locale'] = 'vn';
  vnp_Params['vnp_CurrCode'] = 'VND';
  vnp_Params['vnp_TxnRef'] = orderId;
  vnp_Params['vnp_OrderInfo'] = orderInfo || 'Thanh toan don hang';
  vnp_Params['vnp_OrderType'] = 'other';
  vnp_Params['vnp_Amount'] = amount * 100;
  vnp_Params['vnp_ReturnUrl'] = vnp_ReturnUrl;
  
  let validIp = ipAddr || '127.0.0.1';
  if (typeof validIp === 'string' && validIp.includes(',')) {
      validIp = validIp.split(',')[0].trim();
  }
  if (validIp === '::1') validIp = '127.0.0.1';
  if (validIp.includes('::ffff:')) validIp = validIp.replace('::ffff:', '');
  vnp_Params['vnp_IpAddr'] = validIp;
  
  vnp_Params['vnp_CreateDate'] = createDate;
  vnp_Params['vnp_ExpireDate'] = vnp_ExpireDate;

  // VNPay v2.1.0 Hashing Logic
  // 1. Sort all vnp_ fields alphabetically (excluding vnp_SecureHash)
  const sortedKeys = Object.keys(vnp_Params).sort();
  
  // 2. Build string to hash
  // Theo VNPay 2.1.0, các giá trị trong chuỗi hash CẦN được URL Encode, và khoảng trắng thay bằng dấu +
  const signData = sortedKeys
    .map(key => `${encodeURIComponent(key)}=${encodeURIComponent(vnp_Params[key]).replace(/%20/g, "+")}`)
    .join('&');

  // 3. Create HMAC-SHA512
  const hmac = crypto.createHmac("sha512", vnp_HashSecret);
  const signed = hmac.update(Buffer.from(signData, 'utf-8')).digest("hex"); 
  
  // 4. Build Final URL
  const paymentUrl = `${vnp_Url}?${signData}&vnp_SecureHash=${signed}`;

  return {
    payUrl: paymentUrl,
    orderId,
    amount,
    message: "Success"
  };
};

export const verifyVNPayCallback = (vnp_Params) => {
  const vnp_HashSecret = env.vnpay.hashSecret || '8O43F3YO38U2JV5UZDUU4JI6PFW7XLTO';
  const secureHash = vnp_Params['vnp_SecureHash'];
  
  delete vnp_Params['vnp_SecureHash'];
  delete vnp_Params['vnp_SecureHashType'];

  const sortedKeys = Object.keys(vnp_Params).sort();
  
  const signData = sortedKeys
    .map(key => `${encodeURIComponent(key)}=${encodeURIComponent(vnp_Params[key]).replace(/%20/g, "+")}`)
    .join('&');
      
  const hmac = crypto.createHmac("sha512", vnp_HashSecret);
  const signed = hmac.update(Buffer.from(signData, 'utf-8')).digest("hex");     

  return secureHash === signed;
}
