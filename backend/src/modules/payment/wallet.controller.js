import { pool } from '../../db/pool.js';

// ─── GET WALLET BALANCE ───────────────────────────────────────
export const getBalance = async (req, res, next) => {
  try {
    const userId = req.user?.userId;
    if (!userId) return res.status(401).json({ message: 'Unauthorized' });

    // Upsert: create wallet row if first time
    await pool.query(
      `INSERT INTO wallets (user_id, balance, currency, status)
       VALUES ($1, 0, 'VND', 'ACTIVE')
       ON CONFLICT (user_id) DO NOTHING`,
      [userId]
    );

    const result = await pool.query(
      'SELECT balance FROM wallets WHERE user_id = $1',
      [userId]
    );

    const balance = result.rows[0]?.balance ?? 0;
    return res.status(200).json({ balance: Number(balance) });
  } catch (error) {
    next(error);
  }
};

// ─── WITHDRAW ────────────────────────────────────────────────
// POST /api/payment/wallet/withdraw
// Body: { amount, bankCode, accountNumber, accountName }
export const withdraw = async (req, res, next) => {
  const client = await pool.connect();
  try {
    const userId = req.user?.userId;
    if (!userId) return res.status(401).json({ message: 'Unauthorized' });

    const { amount, bankCode, accountNumber, accountName } = req.body;
    const parsedAmount = parseInt(amount);

    if (!parsedAmount || parsedAmount < 10000) {
      return res.status(400).json({ message: 'Số tiền rút tối thiểu là 10,000đ' });
    }
    if (!accountNumber || !bankCode) {
      return res.status(400).json({ message: 'Vui lòng cung cấp thông tin ngân hàng' });
    }

    await client.query('BEGIN');

    // Check balance
    const walletRes = await client.query(
      'SELECT balance FROM wallets WHERE user_id = $1 FOR UPDATE',
      [userId]
    );
    const currentBalance = Number(walletRes.rows[0]?.balance ?? 0);

    if (currentBalance < parsedAmount) {
      await client.query('ROLLBACK');
      return res.status(400).json({
        message: `Số dư không đủ. Hiện tại: ${currentBalance.toLocaleString('vi-VN')}đ`
      });
    }

    // Deduct balance
    await client.query(
      'UPDATE wallets SET balance = balance - $1 WHERE user_id = $2',
      [parsedAmount, userId]
    );

    // Record transaction
    const orderId = `WD_${Date.now()}_${userId}`;
    await client.query(
      `INSERT INTO transactions (sender_id, order_id, amount, provider, status, tx_type, note)
       VALUES ($1, $2, $3, $4, $5, $6, $7)`,
      [
        userId,
        orderId,
        parsedAmount,
        bankCode,
        'pending',
        'withdraw',
        `${accountName ?? ''} - ${accountNumber}`
      ]
    );

    await client.query('COMMIT');

    return res.status(200).json({
      message: 'Yêu cầu rút tiền đã được gửi. Sẽ được xử lý trong 1-3 ngày làm việc.',
      orderId,
      amount: parsedAmount,
      remainingBalance: currentBalance - parsedAmount,
    });
  } catch (error) {
    await client.query('ROLLBACK');
    next(error);
  } finally {
    client.release();
  }
};

// ─── TRANSFER (PEER-TO-PEER) ──────────────────────────────────
// POST /api/payment/wallet/transfer
// Body: { toEmail, amount, note }
export const transfer = async (req, res, next) => {
  const client = await pool.connect();
  try {
    const senderId = req.user?.userId;
    if (!senderId) return res.status(401).json({ message: 'Unauthorized' });

    const { toEmail, amount, note } = req.body;
    const parsedAmount = parseInt(amount);

    if (!parsedAmount || parsedAmount < 1000) {
      return res.status(400).json({ message: 'Số tiền chuyển tối thiểu là 1,000đ' });
    }
    if (!toEmail) {
      return res.status(400).json({ message: 'Vui lòng nhập email người nhận' });
    }

    await client.query('BEGIN');

    // Find recipient
    const recipientRes = await client.query(
      'SELECT user_id AS id, username FROM users WHERE email = $1',
      [toEmail.toLowerCase().trim()]
    );
    if (recipientRes.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({ message: 'Không tìm thấy người dùng với email này' });
    }
    const recipient = recipientRes.rows[0];

    if (recipient.id === senderId) {
      await client.query('ROLLBACK');
      return res.status(400).json({ message: 'Không thể chuyển tiền cho chính mình' });
    }

    // Check sender balance
    const senderWallet = await client.query(
      'SELECT balance FROM wallets WHERE user_id = $1 FOR UPDATE',
      [senderId]
    );
    const senderBalance = Number(senderWallet.rows[0]?.balance ?? 0);

    if (senderBalance < parsedAmount) {
      await client.query('ROLLBACK');
      return res.status(400).json({
        message: `Số dư không đủ. Hiện tại: ${senderBalance.toLocaleString('vi-VN')}đ`
      });
    }

    // Ensure recipient wallet exists
    await client.query(
      `INSERT INTO wallets (user_id, balance, currency, status)
       VALUES ($1, 0, 'VND', 'ACTIVE')
       ON CONFLICT (user_id) DO NOTHING`,
      [recipient.id]
    );

    // Deduct from sender
    await client.query(
      'UPDATE wallets SET balance = balance - $1 WHERE user_id = $2',
      [parsedAmount, senderId]
    );

    // Credit recipient
    await client.query(
      'UPDATE wallets SET balance = balance + $1 WHERE user_id = $2',
      [parsedAmount, recipient.id]
    );

    // Record transaction for sender
    const orderId = `TF_${Date.now()}_${senderId.substring(0,6)}`;
    await client.query(
      `INSERT INTO transactions (sender_id, receiver_id, order_id, amount, provider, status, tx_type)
       VALUES ($1, $2, $3, $4, $5, $6, $7)`,
      [senderId, recipient.id, orderId, parsedAmount, 'wallet', 'success', 'transfer']
    );

    await client.query('COMMIT');

    return res.status(200).json({
      message: `Đã chuyển ${parsedAmount.toLocaleString('vi-VN')}đ cho ${recipient.username} thành công!`,
      orderId,
      amount: parsedAmount,
      recipientUsername: recipient.username,
    });
  } catch (error) {
    await client.query('ROLLBACK');
    next(error);
  } finally {
    client.release();
  }
};

// ─── ADMIN ADD MONEY ─────────────────────────────────────────
// POST /api/payment/wallet/admin-add
// Body: { toEmail, amount, note }
export const adminAddMoney = async (req, res, next) => {
  const client = await pool.connect();
  try {
    const adminId = req.user?.userId;
    const adminRole = req.user?.role?.toLowerCase();
    if (!adminId || (adminRole !== 'admin' && adminRole !== 'marketing_admin')) {
      return res.status(403).json({ message: 'Forbidden: Requires admin privileges' });
    }

    const { toEmail, amount, note } = req.body;
    const parsedAmount = parseInt(amount);

    if (!parsedAmount || parsedAmount < 1000) {
      return res.status(400).json({ message: 'Số tiền nạp tối thiểu là 1,000đ' });
    }
    if (!toEmail) {
      return res.status(400).json({ message: 'Vui lòng nhập email người nhận' });
    }

    await client.query('BEGIN');

    // Find recipient
    const recipientRes = await client.query(
      'SELECT user_id AS id, username FROM users WHERE email = $1',
      [toEmail.toLowerCase().trim()]
    );
    if (recipientRes.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({ message: 'Không tìm thấy người dùng với email này' });
    }
    const recipient = recipientRes.rows[0];

    // Ensure recipient wallet exists
    await client.query(
      `INSERT INTO wallets (user_id, balance, currency, status)
       VALUES ($1, 0, 'VND', 'ACTIVE')
       ON CONFLICT (user_id) DO NOTHING`,
      [recipient.id]
    );

    // Credit recipient
    await client.query(
      'UPDATE wallets SET balance = balance + $1 WHERE user_id = $2',
      [parsedAmount, recipient.id]
    );

    // Record transaction
    const orderId = `ADADD_${Date.now()}_${adminId.substring(0,6)}`;
    await client.query(
      `INSERT INTO transactions (sender_id, receiver_id, order_id, amount, provider, status, tx_type)
       VALUES ($1, $2, $3, $4, $5, $6, $7)`,
      [adminId, recipient.id, orderId, parsedAmount, 'system', 'success', 'admin_deposit']
    );

    await client.query('COMMIT');

    return res.status(200).json({
      message: `Đã cộng ${parsedAmount.toLocaleString('vi-VN')}đ vào ví của ${recipient.username} thành công!`,
      orderId,
      amount: parsedAmount,
      recipientUsername: recipient.username,
    });
  } catch (error) {
    await client.query('ROLLBACK');
    console.error("ADMIN_ADD_MONEY_ERROR:", error);
    return res.status(500).json({ message: 'Lỗi DB: ' + error.message, stack: error.stack });
  } finally {
    client.release();
  }
};
