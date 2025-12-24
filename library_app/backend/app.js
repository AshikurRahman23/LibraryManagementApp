import express from 'express';
import dotenv from 'dotenv';
import bodyParser from 'body-parser';
import authRoutes from './routes/auth.js';
import adminRoutes from './routes/admin.js';
import studentRoutes from './routes/student.js';

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
