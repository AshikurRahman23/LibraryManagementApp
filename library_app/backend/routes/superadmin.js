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
  deleteAdmin,
  updateAdminPermissions,
  ADMIN_PERMISSIONS
} from '../models/adminModel.js';
import { deleteStudent, getUserById, updateUserPassword } from '../models/userModel.js';

const router = express.Router();

// All routes require authentication and super_admin role
router.use(authenticate, superAdminOnly);

/* ---------- Get Available Permissions ---------- */
router.get('/permissions', (req, res) => {
  res.json({
    success: true,
    permissions: Object.values(ADMIN_PERMISSIONS),
    permissionsInfo: {
      manage_books: 'Add, edit, and delete books',
      delete_student: 'Delete student accounts',
      approve_requests: 'Approve or reject book borrow requests',
      manage_loans: 'Manage loan returns',
      manage_suggestions: 'Delete suggested books'
    }
  });
});

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
    const { name, email, password, mobile_no, permissions } = req.body;

    if (!name || !email || !password) {
      return res.status(400).json({
        success: false,
        message: 'Name, email, and password are required'
      });
    }

    // Validate permissions array
    const validPermissions = Object.values(ADMIN_PERMISSIONS);
    const adminPermissions = (permissions || []).filter(p => validPermissions.includes(p));

    // Hash password
    const hashedPassword = await bcrypt.hash(password, 10);

    // Create admin with permissions
    const newAdmin = await createAdmin(name, email, hashedPassword, mobile_no, adminPermissions);

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
    const { name, email, mobile_no, permissions } = req.body;

    if (!name || !email) {
      return res.status(400).json({
        success: false,
        message: 'Name and email are required'
      });
    }

    // Validate permissions if provided
    let adminPermissions = null;
    if (permissions !== undefined) {
      const validPermissions = Object.values(ADMIN_PERMISSIONS);
      adminPermissions = (permissions || []).filter(p => validPermissions.includes(p));
    }

    const updatedAdmin = await updateAdmin(id, name, email, mobile_no, adminPermissions);

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

/* ---------- Update Admin Permissions Only ---------- */
router.put('/admins/:id/permissions', async (req, res) => {
  try {
    const { id } = req.params;
    const { permissions } = req.body;

    // Validate permissions
    const validPermissions = Object.values(ADMIN_PERMISSIONS);
    const adminPermissions = (permissions || []).filter(p => validPermissions.includes(p));

    const updatedAdmin = await updateAdminPermissions(id, adminPermissions);

    if (!updatedAdmin) {
      return res.status(404).json({
        success: false,
        message: 'Admin not found'
      });
    }

    res.json({
      success: true,
      message: 'Permissions updated successfully',
      admin: updatedAdmin
    });
  } catch (err) {
    console.error('Error updating permissions:', err);
    res.status(500).json({ success: false, message: 'Failed to update permissions' });
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

/* ---------- Change Own Password ---------- */
router.put('/change-password', async (req, res) => {
  try {
    const { currentPassword, newPassword } = req.body;

    if (!currentPassword || !newPassword) {
      return res.status(400).json({
        success: false,
        message: 'Current password and new password are required'
      });
    }

    if (newPassword.length < 6) {
      return res.status(400).json({
        success: false,
        message: 'New password must be at least 6 characters'
      });
    }

    // Get current user
    const user = await getUserById(req.user.id);
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    // Verify current password
    const isMatch = await bcrypt.compare(currentPassword, user.password);
    if (!isMatch) {
      return res.status(400).json({
        success: false,
        message: 'Current password is incorrect'
      });
    }

    // Hash new password
    const hashedPassword = await bcrypt.hash(newPassword, 10);

    // Update password
    await updateUserPassword(req.user.id, hashedPassword);

    res.json({
      success: true,
      message: 'Password changed successfully'
    });
  } catch (err) {
    console.error('Error changing password:', err);
    res.status(500).json({
      success: false,
      message: 'Failed to change password'
    });
  }
});

export default router;
