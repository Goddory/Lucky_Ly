import { ensureGiftCashflowSchema, processExpiredGiftRefunds } from './gifts.service.js';

const DEFAULT_REFUND_INTERVAL_MS = 5 * 60 * 1000;

let refundTimer = null;

export const startGiftRefundScheduler = ({ intervalMs = DEFAULT_REFUND_INTERVAL_MS } = {}) => {
  if (refundTimer) return;

  const runRefundCycle = async () => {
    try {
      const refundedCount = await processExpiredGiftRefunds();
      if (refundedCount > 0) {
        console.log(`[GiftRefundScheduler] Refunded ${refundedCount} expired gift(s).`);
      }
    } catch (error) {
      console.error('[GiftRefundScheduler] Failed to process expired gifts:', error.message);
    }
  };

  ensureGiftCashflowSchema().catch((error) => {
    console.error('[GiftRefundScheduler] Failed to ensure gift schema:', error.message);
  });

  runRefundCycle().catch(() => {});
  refundTimer = setInterval(() => {
    runRefundCycle().catch(() => {});
  }, intervalMs);

  if (typeof refundTimer.unref === 'function') {
    refundTimer.unref();
  }
};
