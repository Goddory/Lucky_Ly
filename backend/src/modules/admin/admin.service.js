import { pool } from '../../db/pool.js';

export const getStats = async (period = 'month') => {
    let dateFilter = '';
    if (period === 'day') dateFilter = "AND created_at >= NOW() - INTERVAL '1 day'";
    else if (period === 'month') dateFilter = "AND created_at >= NOW() - INTERVAL '1 month'";
    else if (period === 'year') dateFilter = "AND created_at >= NOW() - INTERVAL '1 year'";

    const userCountQuery = `SELECT COUNT(*) FROM users WHERE role = 'USER' ${dateFilter}`;
    const activeUsersQuery = `SELECT COUNT(*) FROM users WHERE status = 'ACTIVE' AND role = 'USER'`;
    const totalBalanceQuery = `SELECT SUM(balance) FROM wallets`;
    const pendingAppealsQuery = `SELECT COUNT(*) FROM user_appeals WHERE status = 'PENDING'`;
    
    // Giữ lại tx stats nếu cần
    const txStatsQuery = `
        SELECT 
            COUNT(*) as total_transactions,
            COALESCE(SUM(amount), 0) as total_volume
        FROM transactions 
        WHERE 1=1 ${dateFilter}
    `;

    // Chúng ta sử dụng try/catch cho txStats vì bảng transactions có thể chưa có hoặc có cấu trúc khác
    let txRes = { rows: [{ total_transactions: 0, total_volume: 0 }] };
    try {
        txRes = await pool.query(txStatsQuery);
    } catch (e) {
        // Table might not exist or other issues
    }

    const [userRes, activeRes, balanceRes, appealRes] = await Promise.all([
        pool.query(userCountQuery),
        pool.query(activeUsersQuery),
        pool.query(totalBalanceQuery),
        pool.query(pendingAppealsQuery)
    ]);

    return {
        userCount: parseInt(userRes.rows[0].count),
        activeUsers: parseInt(activeRes.rows[0].count),
        totalBalance: parseFloat(balanceRes.rows[0].sum || 0),
        pendingAppeals: parseInt(appealRes.rows[0].count),
        transactionCount: parseInt(txRes.rows[0].total_transactions),
        totalVolume: parseFloat(txRes.rows[0].total_volume),
        period
    };
};

export const updateSystemTheme = async (themeConfig) => {
    const query = `
        INSERT INTO system_config (key, value)
        VALUES ('active_theme', $1)
        ON CONFLICT (key) DO UPDATE SET value = $1, updated_at = NOW()
        RETURNING *;
    `;
    const { rows } = await pool.query(query, [JSON.stringify(themeConfig)]);
    return rows[0].value;
};

export const listUsers = async ({ search = '', status = '', limit = 10, offset = 0 }) => {
    const safeSearch = search || '';
    const safeLimit = parseInt(limit) || 10;
    const safeOffset = parseInt(offset) || 0;
    const searchPattern = `%${safeSearch}%`;
    
    let whereClause = '(u.email ILIKE $1::text OR u.username ILIKE $1::text OR u.full_name ILIKE $1::text)';
    const queryParams = [searchPattern];
    
    if (status && ['ACTIVE', 'BLOCKED'].includes(status)) {
        queryParams.push(status);
        whereClause += ` AND u.status = $${queryParams.length}::text`;
    }

    const query = `
        SELECT 
            u.user_id, u.username, u.email, u.full_name, u.avatar_url, u.role, u.status, u.block_reason, u.created_at,
            w.balance, w.currency
        FROM users u
        LEFT JOIN wallets w ON u.user_id = w.user_id
        WHERE ${whereClause}
        ORDER BY u.created_at DESC
        LIMIT $${queryParams.length + 1} OFFSET $${queryParams.length + 2}
    `;
    
    const countQuery = `
        SELECT COUNT(*) FROM users u
        WHERE ${whereClause}
    `;
    
    const [rowsRes, countRes] = await Promise.all([
        pool.query(query, [...queryParams, safeLimit, safeOffset]),
        pool.query(countQuery, queryParams)
    ]);

    return {
        users: rowsRes.rows,
        total: parseInt(countRes.rows[0].count),
        limit: parseInt(limit),
        offset: parseInt(offset)
    };
};

export const getUserDetails = async (userId) => {
    const query = `
        SELECT 
            u.*,
            w.balance, w.currency, w.status as wallet_status
        FROM users u
        LEFT JOIN wallets w ON u.user_id = w.user_id
        WHERE u.user_id = $1
    `;
    const { rows } = await pool.query(query, [userId]);
    return rows[0];
};

export const updateUserStatus = async (userId, status, blockReason = null) => {
    const query = `
        UPDATE users 
        SET status = $1, block_reason = $2 
        WHERE user_id = $3 
        RETURNING user_id, email, status, block_reason
    `;
    const { rows } = await pool.query(query, [status, blockReason, userId]);
    
    if (status === 'BLOCKED') {
        await pool.query(
            'UPDATE auth_refresh_tokens SET revoked_at = NOW() WHERE user_id = $1 AND revoked_at IS NULL',
            [userId]
        );
    }
    
    return rows[0];
};
