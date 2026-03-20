import { env } from '../config/env.js';

/**
 * MOCK: Creates a simulated MoMo payment request
 * @param {Object} orderInfo - Information about the order
 * @param {string} orderInfo.orderId - Unique order ID
 * @param {string} orderInfo.orderInfo - Order description
 * @param {number} orderInfo.amount - Amount in VND
 * @returns {Promise<Object>} MoMo API response containing mock payUrl
 */
export const createMoMoPayment = async ({ orderId, orderInfo, amount }) => {
  // Vì không có API Key thật từ MoMo Doanh Nghiệp, chúng ta giả lập (Mock)
  // URL trả về sẽ trỏ đến trang thanh toán giả lập trên chính Backend của chúng ta.
  
  const mockPayUrl = `http://127.0.0.1:${env.port}/api/payment/momo/mock-page?orderId=${orderId}&amount=${amount}&orderInfo=${encodeURIComponent(orderInfo)}`;

  return {
    payUrl: mockPayUrl,
    orderId: orderId,
    amount: amount,
    message: "Success (Mocked)"
  };
};
