import { pool } from '../../db/pool.js';

export const getStats = async (period) => {
    let dateFilter = '';
    if (period === 'day') dateFilter = "AND created_at >= NOW() - INTERVAL '1 day'";
    else if (period === 'month') dateFilter = "AND created_at >= NOW() - INTERVAL '1 month'";
    else if (period === 'year') dateFilter = "AND created_at >= NOW() - INTERVAL '1 year'";

    const userCountQuery = `SELECT COUNT(*) FROM users WHERE 1=1 ${dateFilter}`;
    const txStatsQuery = `
        SELECT 
            COUNT(*) as total_transactions,
            COALESCE(SUM(amount), 0) as total_volume
        FROM transactions 
        WHERE 1=1 ${dateFilter}
    `;

    const [userRes, txRes] = await Promise.all([
        pool.query(userCountQuery),
        pool.query(txStatsQuery)
    ]);

    return {
        userCount: parseInt(userRes.rows[0].count),
        transactionCount: parseInt(txRes.rows[0].total_transactions),
        totalVolume: parseFloat(txRes.rows[0].total_volume)
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

export const listUsers = async ({ search = '', limit = 10, offset = 0 }) => {
    const safeSearch = search || '';
    const safeLimit = parseInt(limit) || 10;
    const safeOffset = parseInt(offset) || 0;
    const searchPattern = `%${safeSearch}%`;
    const query = `
        SELECT 
            u.user_id, u.username, u.email, u.full_name, u.avatar_url, u.role, u.status, u.created_at,
            w.balance, w.currency
        FROM users u
        LEFT JOIN wallets w ON u.user_id = w.user_id
        WHERE u.email ILIKE $1 OR u.username ILIKE $1 OR u.full_name ILIKE $1
        ORDER BY u.created_at DESC
        LIMIT $2 OFFSET $3
    `;
    const countQuery = `
        SELECT COUNT(*) FROM users 
        WHERE email ILIKE $1 OR username ILIKE $1 OR full_name ILIKE $1
    `;
    
    const [rowsRes, countRes] = await Promise.all([
        pool.query(query, [searchPattern, safeLimit, safeOffset]),
        pool.query(countQuery, [searchPattern])
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

export const updateUserStatus = async (userId, status) => {
    const query = `
        UPDATE users 
        SET status = $1 
        WHERE user_id = $2 
        RETURNING user_id, email, status
    `;
    const { rows } = await pool.query(query, [status, userId]);
    return rows[0];
};
