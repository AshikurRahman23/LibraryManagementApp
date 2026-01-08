import express from 'express';
import db from '../models/db.js';
import {
  getAllBooks, getFeaturedBooks, getSearchBooks
} from '../models/bookModel.js';
import {
  getStudentLoans, getStudentSearchLoans, countCurrentlyBorrowedBooks
} from '../models/loanModel.js';
import { createPayment, getPaymentsByUserId } from '../models/paymentModel.js';
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

/* ---------- Payment Routes ---------- */

// Make a payment for a loan penalty
router.post('/payments', async (req, res) => {
  try {
    const { loan_id, amount, payment_method, reference } = req.body;

    if (!loan_id || !amount || !payment_method) {
      return res.status(400).json({
        success: false,
        message: 'Loan ID, amount, and payment method are required'
      });
    }

    // Generate a dummy transaction ID
    const transactionId = `TXN${Date.now()}${Math.floor(Math.random() * 1000)}`;

    const payment = await createPayment(
      loan_id,
      req.user.id,
      amount,
      payment_method,
      transactionId,
      reference || null
    );

    res.json({
      success: true,
      message: 'Payment successful',
      payment,
      transactionId
    });
  } catch (err) {
    console.error('Payment error:', err);
    res.status(500).json({
      success: false,
      message: 'Payment failed'
    });
  }
});

// Get student's payment history
router.get('/payments', async (req, res) => {
  try {
    const payments = await getPaymentsByUserId(req.user.id);
    res.json({
      success: true,
      payments
    });
  } catch (err) {
    console.error('Error fetching payments:', err);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch payment history'
    });
  }
});

export default router;
