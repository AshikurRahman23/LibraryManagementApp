import pool from './db.js';

/**
 * Save a suggested book into suggested_books table
 * @param {string} title
 */
export const createSuggestedBook = async (title) => {
  // url column was removed from schema; only insert title
  const res = await pool.query(
    'INSERT INTO suggested_books (title) VALUES ($1) RETURNING *',
    [title]
  );
  return res.rows[0];
};

export const getSuggestedBooks = async () => {
  const res = await pool.query('SELECT * FROM suggested_books ORDER BY suggested_at DESC');
  return res.rows;
};
