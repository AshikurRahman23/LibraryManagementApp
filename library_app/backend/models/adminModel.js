import pool from './db.js';

/**
 * Available admin permissions
 */
export const ADMIN_PERMISSIONS = {
  MANAGE_BOOKS: 'manage_books',           // Add, edit, delete books
  DELETE_STUDENT: 'delete_student',        // Delete students
  APPROVE_REQUESTS: 'approve_requests',    // Approve/reject book requests
  MANAGE_LOANS: 'manage_loans',            // Manage loan returns
  MANAGE_SUGGESTIONS: 'manage_suggestions' // Delete suggested books
};

/**
 * Get all admin users (excluding super_admin)
 */
export const getAllAdmins = async () => {
    const res = await pool.query(
        'SELECT id, name, email, role, mobile_no, permissions, created_at FROM users WHERE role=$1 ORDER BY created_at DESC',
        ['admin']
    );
    return res.rows;
};

/**
 * Get admin by ID
 */
export const getAdminById = async (id) => {
    const res = await pool.query(
        'SELECT id, name, email, role, mobile_no, permissions, created_at FROM users WHERE id=$1 AND role=$2',
        [id, 'admin']
    );
    return res.rows[0];
};

/**
 * Search admins by name, email
 */
export const searchAdmins = async (searchTerm) => {
    const search = `%${searchTerm}%`;
    const res = await pool.query(
        `SELECT id, name, email, role, mobile_no, permissions, created_at 
         FROM users 
         WHERE role=$1 AND (name ILIKE $2 OR email ILIKE $2)
         ORDER BY created_at DESC`,
        ['admin', search]
    );
    return res.rows;
};

/**
 * Create new admin user with permissions
 */
export const createAdmin = async (name, email, hashedPassword, mobile_no, permissions = []) => {
    const res = await pool.query(
        `INSERT INTO users (name, email, password, role, mobile_no, permissions) 
         VALUES ($1, $2, $3, $4, $5, $6) RETURNING id, name, email, role, mobile_no, permissions, created_at`,
        [name, email, hashedPassword, 'admin', mobile_no, JSON.stringify(permissions)]
    );
    return res.rows[0];
};

/**
 * Update admin details (excluding password) with permissions
 */
export const updateAdmin = async (id, name, email, mobile_no, permissions = null) => {
    // If permissions provided, update them too
    if (permissions !== null) {
        const res = await pool.query(
            `UPDATE users 
             SET name=$1, email=$2, mobile_no=$3, permissions=$4
             WHERE id=$5 AND role=$6 
             RETURNING id, name, email, role, mobile_no, permissions, created_at`,
            [name, email, mobile_no, JSON.stringify(permissions), id, 'admin']
        );
        return res.rows[0];
    }
    
    const res = await pool.query(
        `UPDATE users 
         SET name=$1, email=$2, mobile_no=$3 
         WHERE id=$4 AND role=$5 
         RETURNING id, name, email, role, mobile_no, permissions, created_at`,
        [name, email, mobile_no, id, 'admin']
    );
    return res.rows[0];
};

/**
 * Update admin permissions only
 */
export const updateAdminPermissions = async (id, permissions) => {
    const res = await pool.query(
        `UPDATE users 
         SET permissions=$1 
         WHERE id=$2 AND role=$3 
         RETURNING id, name, email, role, mobile_no, permissions, created_at`,
        [JSON.stringify(permissions), id, 'admin']
    );
    return res.rows[0];
};

/**
 * Update admin password
 */
export const updateAdminPassword = async (id, hashedPassword) => {
    const res = await pool.query(
        `UPDATE users 
         SET password=$1 
         WHERE id=$2 AND role=$3 
         RETURNING id`,
        [hashedPassword, id, 'admin']
    );
    return res.rows[0];
};

/**
 * Delete admin user
 * Note: This should check if admin has any related data before deletion
 */
export const deleteAdmin = async (id) => {
    // First check if this admin exists and is actually an admin
    const checkRes = await pool.query(
        'SELECT id FROM users WHERE id=$1 AND role=$2',
        [id, 'admin']
    );

    if (checkRes.rows.length === 0) {
        throw new Error('Admin not found or not an admin role');
    }

    // Delete the admin
    const res = await pool.query(
        'DELETE FROM users WHERE id=$1 AND role=$2 RETURNING id',
        [id, 'admin']
    );
    return res.rows[0];
};

/**
 * Check if email is already used by another admin
 */
export const isEmailTakenByAdmin = async (email, excludeId = null) => {
    let query = 'SELECT id FROM users WHERE email=$1 AND role=$2';
    const params = [email, 'admin'];

    if (excludeId) {
        query += ' AND id != $3';
        params.push(excludeId);
    }

    const res = await pool.query(query, params);
    return res.rows.length > 0;
};

/**
 * Get admin statistics
 */
export const getAdminStats = async () => {
    const totalAdminsRes = await pool.query(
        'SELECT COUNT(*) as count FROM users WHERE role=$1',
        ['admin']
    );

    return {
        totalAdmins: parseInt(totalAdminsRes.rows[0].count)
    };
};
