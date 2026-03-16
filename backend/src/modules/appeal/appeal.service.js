import { pool } from '../../db/pool.js';

export const createAppeal = async (userId, reason) => {
    const query = `
        INSERT INTO user_appeals (user_id, reason)
        VALUES ($1, $2)
        RETURNING *
    `;
    const { rows } = await pool.query(query, [userId, reason]);
    return rows[0];
};

export const listAppeals = async ({ status = 'PENDING', limit = 10, offset = 0 }) => {
    const query = `
        SELECT 
            a.*,
            u.username, u.email, u.full_name, u.block_reason
        FROM user_appeals a
        JOIN users u ON a.user_id = u.user_id
        WHERE a.status = $1
        ORDER BY a.created_at DESC
        LIMIT $2 OFFSET $3
    `;
    const countQuery = `SELECT COUNT(*) FROM user_appeals WHERE status = $1`;
    
    const [rowsRes, countRes] = await Promise.all([
        pool.query(query, [status, limit, offset]),
        pool.query(countQuery, [status])
    ]);

    return {
        appeals: rowsRes.rows,
        total: parseInt(countRes.rows[0].count)
    };
};

export const respondToAppeal = async (appealId, status, adminNote) => {
    const client = await pool.connect();
    try {
        await client.query('BEGIN');

        const updateAppealQuery = `
            UPDATE user_appeals 
            SET status = $1, admin_note = $2, updated_at = NOW() 
            WHERE appeal_id = $3 
            RETURNING *
        `;
        const { rows } = await client.query(updateAppealQuery, [status, adminNote, appealId]);
        const appeal = rows[0];

        if (!appeal) {
            throw new Error('Appeal not found');
        }

        if (status === 'APPROVED') {
            // Unblock user
            await client.query(
                "UPDATE users SET status = 'ACTIVE', block_reason = NULL WHERE user_id = $1",
                [appeal.user_id]
            );
        }

        await client.query('COMMIT');
        return appeal;
    } catch (err) {
        await client.query('ROLLBACK');
        throw err;
    } finally {
        client.release();
    }
};

export const getLatestAppealByUser = async (userId) => {
    const query = `
        SELECT * FROM user_appeals 
        WHERE user_id = $1 
        ORDER BY created_at DESC 
        LIMIT 1
    `;
    const { rows } = await pool.query(query, [userId]);
    return rows[0];
};
