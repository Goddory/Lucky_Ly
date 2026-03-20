import { pool } from '../../db/pool.js';

export const createEvent = async (userId, eventData) => {
    const { title, date, type, note } = eventData;
    const query = `
        INSERT INTO events (user_id, title, date, type, note)
        VALUES ($1, $2, $3, $4, $5)
        RETURNING *;
    `;
    const values = [userId, title, date, type, note];
    const { rows } = await pool.query(query, values);
    return rows[0];
};

export const getUserEvents = async (userId) => {
    const query = `
        SELECT * FROM events
        WHERE user_id = $1 OR type = 'holiday'
        ORDER BY date ASC;
    `;
    const values = [userId];
    const { rows } = await pool.query(query, values);
    return rows;
};

export const deleteEvent = async (id, userId) => {
    const query = `
        DELETE FROM events
        WHERE id = $1 AND user_id = $2
        RETURNING *;
    `;
    const values = [id, userId];
    const { rows } = await pool.query(query, values);
    return rows[0];
};
