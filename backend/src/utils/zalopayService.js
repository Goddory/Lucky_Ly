import axios from 'axios';
import CryptoJS from 'crypto-js';
import moment from 'moment';
import { env } from '../config/env.js';

/**
 * Create a ZaloPay order
 * @param {Object} params 
 * @param {string} params.amount - Payment amount as string
 * @param {string} params.orderId - Unique order ID
 * @param {string} params.description - Order description
 * @param {string} params.appUser - Optional user identifier
 * @returns {Promise<Object>} ZaloPay response
 */
export const createZaloPayOrder = async ({ amount, orderId, description, appUser = 'lucky_ly_user' }) => {
  const embed_data = {
    redirecturl: env.zalopay.redirectUrl
  };

  const items = [];
  const app_trans_id = `${moment().format('YYMMDD')}_${orderId}`;

  const order = {
    app_id: env.zalopay.appId,
    app_trans_id,
    app_user: appUser,
    app_time: Date.now(),
    item: JSON.stringify(items),
    embed_data: JSON.stringify(embed_data),
    amount: Number(amount),
    callback_url: env.zalopay.callbackUrl,
    description: description || `Lucky Ly - Payment #${orderId}`,
    bank_code: '',
  };

  // MAC = appid|app_trans_id|appuser|amount|apptime|embeddata|item
  const data =
    order.app_id +
    '|' +
    order.app_trans_id +
    '|' +
    order.app_user +
    '|' +
    order.amount +
    '|' +
    order.app_time +
    '|' +
    order.embed_data +
    '|' +
    order.item;
    
  order.mac = CryptoJS.HmacSHA256(data, env.zalopay.key1).toString();

  try {
    const result = await axios.post(env.zalopay.endpoint, null, { params: order });
    return {
      ...result.data,
      app_trans_id
    };
  } catch (error) {
    console.error('ZaloPay Create Order Error:', error.response?.data || error.message);
    throw error;
  }
};

/**
 * Verify ZaloPay callback MAC
 * @param {string} dataStr 
 * @param {string} reqMac 
 * @returns {boolean}
 */
export const verifyZaloPayCallback = (dataStr, reqMac) => {
  const mac = CryptoJS.HmacSHA256(dataStr, env.zalopay.key2).toString();
  return reqMac === mac;
};

/**
 * Query ZaloPay order status
 * @param {string} app_trans_id 
 * @returns {Promise<Object>}
 */
export const queryZaloPayOrderStatus = async (app_trans_id) => {
  const postData = {
    app_id: env.zalopay.appId,
    app_trans_id,
  };

  const data = postData.app_id + '|' + postData.app_trans_id + '|' + env.zalopay.key1;
  postData.mac = CryptoJS.HmacSHA256(data, env.zalopay.key1).toString();

  const queryUrl = 'https://sb-openapi.zalopay.vn/v2/query';

  try {
    const result = await axios.post(queryUrl, null, {
      params: postData,
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' }
    });
    return result.data;
  } catch (error) {
    console.error('ZaloPay Query Status Error:', error.response?.data || error.message);
    throw error;
  }
};
