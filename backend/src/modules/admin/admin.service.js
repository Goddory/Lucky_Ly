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
