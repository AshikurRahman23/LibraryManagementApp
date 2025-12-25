import express from 'express';
import dotenv from 'dotenv';
import bodyParser from 'body-parser';
import authRoutes from './routes/auth.js';
import adminRoutes from './routes/admin.js';
import studentRoutes from './routes/student.js';
import { authenticate, authorizeRole } from './middlewares/authMiddleware.js';
import pool from './models/db.js';
import libraryRoutes from './routes/library.js';

dotenv.config();
const app = express();

/* ---------- Middleware ---------- */
app.use(bodyParser.urlencoded({ extended: true }));
app.use(bodyParser.json());

/* ---------- CORS (Flutter / Mobile) ---------- */
app.use((req, res, next) => {
  res.header('Access-Control-Allow-Origin', '*');
  res.header(
    'Access-Control-Allow-Headers',
    'Origin, X-Requested-With, Content-Type, Accept, Authorization'
  );
  res.header(
    'Access-Control-Allow-Methods',
    'GET, POST, PUT, DELETE, OPTIONS'
  );

  if (req.method === 'OPTIONS') {
    return res.sendStatus(200);
  }

  next();
});

/* ---------- Routes ---------- */
app.use('/auth', authRoutes);
app.use('/admin', adminRoutes);
app.use('/student', studentRoutes);
app.use('/', libraryRoutes);

// Support DELETE /admin/suggested-books/:id at the app level (protected by admin auth)
// Added to ensure DELETE requests are handled even if router order or other factors cause a 404.
app.delete('/admin/suggested-books/:id', authenticate, authorizeRole('admin'), async (req, res) => {
  try {
    const { id } = req.params;
    await pool.query('DELETE FROM suggested_books WHERE id = $1', [id]);
    res.json({ success: true, message: 'Suggested book deleted' });
  } catch (err) {
    console.error('Failed to delete suggested book', err);
    res.status(500).json({ success: false, message: 'Failed to delete suggested book' });
  }
});


/* ---------- Health Check ---------- */
app.get('/', (req, res) => {
  res.json({
    success: true,
    message: 'Library API is running'
  });
});

/* ---------- Start Server ---------- */
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`🚀 Server running on http://localhost:${PORT}`);
});
