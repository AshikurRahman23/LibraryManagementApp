import pool from './db.js';

// Create payments table if not exists
export const initPaymentsTable = async () => {
    await pool.query(`
        CREATE TABLE IF NOT EXISTS payments (
            id SERIAL PRIMARY KEY,
            loan_id INTEGER REFERENCES loans(id) ON DELETE SET NULL,
            user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
            amount INTEGER NOT NULL,
            payment_method VARCHAR(50) NOT NULL,
            transaction_id VARCHAR(100),
            created_at TIMESTAMP DEFAULT NOW()
        )
    `);
};

// Create a new payment
export const createPayment = async (loanId, userId, amount, paymentMethod, transactionId) => {
    const res = await pool.query(
        `INSERT INTO payments (loan_id, user_id, amount, payment_method, transaction_id)
         VALUES ($1, $2, $3, $4, $5) RETURNING *`,
        [loanId, userId, amount, paymentMethod, transactionId]
    );
    return res.rows[0];
};

// Get payments for a specific user (student)
export const getPaymentsByUserId = async (userId) => {
    const res = await pool.query(
        `SELECT p.*, 
                b.title as book_title,
                l.return_date
         FROM payments p
         LEFT JOIN loans l ON p.loan_id = l.id
         LEFT JOIN books b ON l.book_id = b.id
         WHERE p.user_id = $1
         ORDER BY p.created_at DESC`,
        [userId]
    );
    return res.rows;
};

// Get all payments (for admin)
export const getAllPayments = async () => {
    const res = await pool.query(
        `SELECT p.*, 
                u.name as student_name,
                u.email as student_email,
                u.student_id,
                b.title as book_title,
                l.return_date
         FROM payments p
         JOIN users u ON p.user_id = u.id
         LEFT JOIN loans l ON p.loan_id = l.id
         LEFT JOIN books b ON l.book_id = b.id
         ORDER BY p.created_at DESC`
    );
    return res.rows;
};

// Search payments (for admin)
export const searchPayments = async (search) => {
    const searchTerm = `%${search}%`;
    const res = await pool.query(
        `SELECT p.*, 
                u.name as student_name,
                u.email as student_email,
                u.student_id,
                b.title as book_title,
                l.return_date
         FROM payments p
         JOIN users u ON p.user_id = u.id
         LEFT JOIN loans l ON p.loan_id = l.id
         LEFT JOIN books b ON l.book_id = b.id
         WHERE u.name ILIKE $1 
            OR u.email ILIKE $1 
            OR u.student_id ILIKE $1 
            OR b.title ILIKE $1
            OR p.payment_method ILIKE $1
         ORDER BY p.created_at DESC`,
        [searchTerm]
    );
    return res.rows;
};
