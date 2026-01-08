import express from 'express';
import bcrypt from 'bcryptjs';
import { authenticate } from '../middlewares/authMiddleware.js';
import { superAdminOnly } from '../middlewares/rbacMiddleware.js';
import {
  getAllAdmins,
  getAdminById,
  searchAdmins,
  createAdmin,
  updateAdmin,
  updateAdminPassword,
  deleteAdmin
} from '../models/adminModel.js';
import { deleteStudent } from '../models/userModel.js';

const router = express.Router();

// All routes require authentication and super_admin role
router.use(authenticate, superAdminOnly);

/* ---------- Get All Admins ---------- */
router.get('/admins', async (req, res) => {
  try {
    const search = req.query.search || '';
    const admins = search ? await searchAdmins(search) : await getAllAdmins();
    res.json({ success: true, admins });
  } catch (err) {
    console.error('Error fetching admins:', err);
    res.status(500).json({ success: false, message: 'Failed to fetch admins' });
  }
});

/* ---------- Get Admin By ID ---------- */
router.get('/admins/:id', async (req, res) => {
  try {
    const admin = await getAdminById(req.params.id);
    if (!admin) {
      return res.status(404).json({ success: false, message: 'Admin not found' });
    }
    res.json({ success: true, admin });
  } catch (err) {
    console.error('Error fetching admin:', err);
    res.status(500).json({ success: false, message: 'Failed to fetch admin' });
  }
});

/* ---------- Create New Admin ---------- */
router.post('/admins/add', async (req, res) => {
  try {
    const { name, email, password, mobile_no } = req.body;

    if (!name || !email || !password) {
      return res.status(400).json({
        success: false,
        message: 'Name, email, and password are required'
      });
    }

    // Hash password
    const hashedPassword = await bcrypt.hash(password, 10);

    // Create admin
    const newAdmin = await createAdmin(name, email, hashedPassword, mobile_no);

    res.json({
      success: true,
      message: 'Admin created successfully',
      admin: newAdmin
    });
  } catch (err) {
    console.error('Error creating admin:', err);
    
    // Handle duplicate email
    if (err.code === '23505') {
      return res.status(409).json({
        success: false,
        message: 'Email already exists'
      });
    }

    res.status(500).json({ success: false, message: 'Failed to create admin' });
  }
});

/* ---------- Update Admin ---------- */
router.put('/admins/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { name, email, mobile_no } = req.body;

    if (!name || !email) {
      return res.status(400).json({
        success: false,
        message: 'Name and email are required'
      });
    }

    const updatedAdmin = await updateAdmin(id, name, email, mobile_no);

    if (!updatedAdmin) {
      return res.status(404).json({
        success: false,
        message: 'Admin not found'
      });
    }

    res.json({
      success: true,
      message: 'Admin updated successfully',
      admin: updatedAdmin
    });
  } catch (err) {
    console.error('Error updating admin:', err);

    if (err.code === '23505') {
      return res.status(409).json({
        success: false,
        message: 'Email already exists'
      });
    }

    res.status(500).json({ success: false, message: 'Failed to update admin' });
  }
});

/* ---------- Update Admin Password ---------- */
router.put('/admins/:id/password', async (req, res) => {
  try {
    const { id } = req.params;
    const { password } = req.body;

    if (!password || password.length < 6) {
      return res.status(400).json({
        success: false,
        message: 'Password must be at least 6 characters'
      });
    }

    const hashedPassword = await bcrypt.hash(password, 10);
    const result = await updateAdminPassword(id, hashedPassword);

    if (!result) {
      return res.status(404).json({
        success: false,
        message: 'Admin not found'
      });
    }

    res.json({
      success: true,
      message: 'Password updated successfully'
    });
  } catch (err) {
    console.error('Error updating password:', err);
    res.status(500).json({ success: false, message: 'Failed to update password' });
  }
});

/* ---------- Delete Admin ---------- */
router.delete('/admins/:id', async (req, res) => {
  try {
    const { id } = req.params;

    // Prevent super admin from deleting themselves
    if (parseInt(id) === req.user.id) {
      return res.status(400).json({
        success: false,
        message: 'Cannot delete your own account'
      });
    }

    const result = await deleteAdmin(id);

    if (!result) {
      return res.status(404).json({
        success: false,
        message: 'Admin not found'
      });
    }

    res.json({
      success: true,
      message: 'Admin deleted successfully'
    });
  } catch (err) {
    console.error('Error deleting admin:', err);
    res.status(500).json({ success: false, message: err.message || 'Failed to delete admin' });
  }
});

/* ---------- Delete Student ---------- */
router.delete('/students/:id', async (req, res) => {
  try {
    const { id } = req.params;

    const result = await deleteStudent(id);

    if (!result) {
      return res.status(404).json({
        success: false,
        message: 'Student not found'
      });
    }

    res.json({
      success: true,
      message: 'Student deleted successfully'
    });
  } catch (err) {
    console.error('Error deleting student:', err);
    res.status(500).json({ success: false, message: err.message || 'Failed to delete student' });
  }
});

export default router;
