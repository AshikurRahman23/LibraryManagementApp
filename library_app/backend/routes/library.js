import express from 'express';
import pool from '../models/db.js';
import { createSuggestedBook } from '../models/suggestedModel.js';

const router = express.Router();

/**
 * GET /check-book?title=BOOK_TITLE
 * Returns { exists: true/false }
 */
router.get('/check-book', async (req, res) => {
  const titleRaw = req.query.title;
  if (!titleRaw) return res.status(400).json({ error: 'Missing title param' });
  const title = titleRaw.trim();

  try {
    // Use a case-insensitive partial match
    const result = await pool.query(
      'SELECT 1 FROM books WHERE title ILIKE $1 LIMIT 1',
      [`%${title}%`]
    );
    res.json({ exists: result.rowCount > 0 });
  } catch (err) {
    console.error('Error checking book:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * POST /suggest-book
 * Body: { title }
 */
router.post('/suggest-book', async (req, res) => {
  const { title } = req.body;
  if (!title) return res.status(400).json({ error: 'Missing title in body' });

  try {
    // url is no longer stored in the suggested_books table; ignore if present
    const suggested = await createSuggestedBook(title);
    res.status(201).json({ success: true, suggested });
  } catch (err) {
    console.error('Error suggesting book:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

export default router;
