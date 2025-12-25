import express from 'express';
import db from '../models/db.js';
import {
  getAllBooks, getSearchBooks, createBook, updateBook, deleteBook
} from '../models/bookModel.js';
import { getAllStudents, getSearchStudents } from '../models/userModel.js';
import {
  getAllLoans, getSearchLoans, issueBook, returnBook, getDashboardStats
} from '../models/loanModel.js';
import { authenticate, authorizeRole } from '../middlewares/authMiddleware.js';

const router = express.Router();

// Apply auth middleware for admin
router.use(authenticate, authorizeRole('admin'));

/* ---------- Dashboard ---------- */
router.get('/dashboard', async (req, res) => {
  try {
    const stats = await getDashboardStats();
    res.json({ success: true, stats });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, message: 'Failed to load dashboard' });
  }
});

/* ---------- Books ---------- */
router.get('/books', async (req, res) => {
  try {
    const search = req.query.search || '';
    const books = search ? await getSearchBooks(search) : await getAllBooks();
    res.json({ success: true, books });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Failed to fetch books' });
  }
});

router.post('/books/add', async (req, res) => {
  try {
    const { title, author, total_copies, genre } = req.body;

    // Insert new book (existing behavior)
    const added = await createBook(title, author, total_copies, genre);

    // AFTER successful insertion, remove any suggested_books entries that match this title
    // SQL: DELETE FROM suggested_books WHERE title = $1
    try {
      await db.query('DELETE FROM suggested_books WHERE title = $1', [title]);
      console.log(`Removed suggestions for title: ${title}`);
    } catch (delErr) {
      // Log deletion errors but do not fail the overall request (book insertion succeeded)
      console.error('Error deleting suggested_books entries:', delErr);
    }

    res.json({ success: true, message: 'Book added' });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Failed to add book' });
  }
});

router.post('/books/update', async (req, res) => {
  try {
    const { id, title, author, total_copies, genre } = req.body;
    const books = await getAllBooks();
    const book = books.find(b => b.id == id);
    if (!book) return res.status(404).json({ success: false, message: 'Book not found' });

    let adjustedAvailable = book.available_copies + (total_copies - book.total_copies);
    if (adjustedAvailable < 0) adjustedAvailable = 0;

    await updateBook(id, title, author, total_copies, adjustedAvailable, genre);
    res.json({ success: true, message: 'Book updated' });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Failed to update book' });
  }
});

router.post('/books/delete', async (req, res) => {
  try {
    await deleteBook(req.body.id);
    res.json({ success: true, message: 'Book deleted' });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Failed to delete book' });
  }
});

/* ---------- Suggested Books (Admin only) ---------- */
router.get('/suggested-books', async (req, res) => {
  try {
    const { rows } = await db.query('SELECT * FROM suggested_books ORDER BY suggested_at DESC');
    res.json({ success: true, suggestedBooks: rows });
  } catch (err) {
    console.error('Failed to fetch suggested books', err);
    res.status(500).json({ success: false, message: 'Failed to fetch suggested books' });
  }
});

// Delete a suggested book by id
router.delete('/suggested-books/:id', async (req, res) => {
  try {
    const { id } = req.params;
    await db.query('DELETE FROM suggested_books WHERE id = $1', [id]);
    res.json({ success: true, message: 'Suggested book deleted' });
  } catch (err) {
    console.error('Failed to delete suggested book', err);
    res.status(500).json({ success: false, message: 'Failed to delete suggested book' });
  }
});

/* ---------- Students ---------- */
router.get('/students', async (req, res) => {
  try {
    const search = req.query.search || '';
    const students = search ? await getSearchStudents(search) : await getAllStudents();
    res.json({ success: true, students });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Failed to fetch students' });
  }
});

/* ---------- Loans ---------- */
router.get('/loans', async (req, res) => {
  try {
    const loans = req.query.search
      ? await getSearchLoans(req.query.search)
      : await getAllLoans();
    res.json({ success: true, loans });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Failed to fetch loans' });
  }
});

router.post('/loans/issue', async (req, res) => {
  try {
    await issueBook(req.body.book_id);
    res.json({ success: true, message: 'Book issued' });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Failed to issue book' });
  }
});

router.post('/loans/return', async (req, res) => {
  try {
    await returnBook(req.body.loan_id, req.body.book_id);
    res.json({ success: true, message: 'Book returned' });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Failed to return book' });
  }
});

/* ---------- Borrow Requests ---------- */
router.get('/requests', async (req, res) => {
  try {
    const { rows: requests } = await db.query(`
      SELECT br.id, br.student_id, u.name AS student_name, u.student_id AS student_id,
             br.book_id, b.title AS book_title, br.status, br.requested_at
      FROM borrow_requests br
      JOIN users u ON br.student_id = u.id
      JOIN books b ON br.book_id = b.id
      ORDER BY br.id DESC
    `);
    res.json({ success: true, requests });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Failed to fetch requests' });
  }
});

router.post('/requests/:id/approve', async (req, res) => {
  try {
    const { id } = req.params;

    await db.query("UPDATE borrow_requests SET status='approved' WHERE id=$1", [id]);

    await db.query(`
      INSERT INTO loans (student_id, book_id, issued_at, return_date)
      SELECT student_id, book_id, NOW(), NOW() + INTERVAL '1 month'
      FROM borrow_requests WHERE id=$1
    `, [id]);

    await db.query(`
      UPDATE books SET available_copies = available_copies - 1
      WHERE id = (SELECT book_id FROM borrow_requests WHERE id=$1)
    `, [id]);

    res.json({ success: true, message: 'Request approved' });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Failed to approve request' });
  }
});

router.post('/requests/:id/reject', async (req, res) => {
  try {
    await db.query(
      "UPDATE borrow_requests SET status='rejected' WHERE id=$1",
      [req.params.id]
    );
    res.json({ success: true, message: 'Request rejected' });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Failed to reject request' });
  }
});

export default router;
