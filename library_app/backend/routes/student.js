import express from 'express';
import db from '../models/db.js';
import {
  getAllBooks, getFeaturedBooks, getSearchBooks
} from '../models/bookModel.js';
import {
  getStudentLoans, getStudentSearchLoans, countCurrentlyBorrowedBooks
} from '../models/loanModel.js';
import { authenticate, authorizeRole } from '../middlewares/authMiddleware.js';

const router = express.Router();

router.use(authenticate, authorizeRole('student'));

router.get('/dashboard', async (req, res) => {
  try {
    // Fetch student info from DB using the id from JWT
    const userRes = await db.query(
      'SELECT id, name, student_id, email FROM users WHERE id = $1',
      [req.user.id]
    );

    if (userRes.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Student not found'
      });
    }

    const user = userRes.rows[0];

    // Fetch featured books
    const featuredBooks = await getFeaturedBooks();

    res.json({
      success: true,
      user,
      featuredBooks
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({
      success: false,
      message: 'Server error'
    });
  }
});

router.get('/books', async (req, res) => {
  const books = req.query.search
    ? await getSearchBooks(req.query.search)
    : await getAllBooks();

  const borrowed = await countCurrentlyBorrowedBooks(req.user.id);
  res.json({ success: true, books, borrowed });
});

router.get('/mybooks', async (req, res) => {
  const loans = req.query.search
    ? await getStudentSearchLoans(req.query.search, req.user.id)
    : await getStudentLoans(req.user.id);

  res.json({
    success: true,
    currentLoans: loans.filter(l => l.status !== 'returned'),
    pastLoans: loans.filter(l => l.status === 'returned')
  });
});

router.post('/borrow-request', async (req, res) => {
  await db.query(
    `INSERT INTO borrow_requests (student_id, book_id, status, requested_at)
     VALUES ($1, $2, 'pending', NOW())`,
    [req.user.id, req.body.bookId]
  );

  res.status(201).json({
    success: true,
    message: 'Borrow request sent'
  });
});

export default router;
