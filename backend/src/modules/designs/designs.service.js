import { pool } from '../../db/pool.js';

export const createDesign = async (userId, designData) => {
    const { name, type, config, image_url } = designData;
    const query = `
        INSERT INTO designs (user_id, name, type, config, image_url)
        VALUES ($1, $2, $3, $4, $5)
        RETURNING *;
    `;
    const values = [userId, name, type, JSON.stringify(config), image_url];
    const { rows } = await pool.query(query, values);
    return rows[0];
};

export const getUserDesigns = async (userId) => {
    const query = `
        SELECT * FROM designs
        WHERE user_id = $1
        ORDER BY created_at DESC;
    `;
    const values = [userId];
    const { rows } = await pool.query(query, values);
    return rows;
};

export const getDesignById = async (id, userId) => {
    const query = `
        SELECT * FROM designs
        WHERE id = $1 AND user_id = $2;
    `;
    const values = [id, userId];
    const { rows } = await pool.query(query, values);
    return rows[0];
};

export const deleteDesign = async (id, userId) => {
    const query = `
        DELETE FROM designs
        WHERE id = $1 AND user_id = $2
        RETURNING *;
    `;
    const values = [id, userId];
    const { rows } = await pool.query(query, values);
    return rows[0];
};
