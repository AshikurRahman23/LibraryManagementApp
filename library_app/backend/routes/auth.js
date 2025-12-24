import express from 'express';
import bcrypt from 'bcryptjs';
import { createUser, findUserByEmail } from '../models/userModel.js';
import { generateToken } from '../utils/jwt.js';

const router = express.Router();

/* ---------- Signup ---------- */
router.post('/signup', async (req, res) => {
  try {
    const { name, email, password, role, student_id, mobile_no } = req.body;

    const existingUser = await findUserByEmail(email);
    if (existingUser) {
      return res.status(400).json({
        success: false,
        message: 'Email already registered'
      });
    }

    const hashedPassword = await bcrypt.hash(password, 10);

    const user = await createUser(
      name,
      email,
      hashedPassword,
      role,
      student_id,
      mobile_no
    );

    const token = generateToken(user);

    res.status(201).json({
      success: true,
      message: 'Account created successfully',
      token,
      user: {
        id: user.id,
        name: user.name,
        email: user.email,
        role: user.role,
        student_id: user.student_id
      }
    });

  } catch (err) {
    res.status(500).json({
      success: false,
      message: 'Signup failed'
    });
  }
});

/* ---------- Login ---------- */
router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;

    const user = await findUserByEmail(email);
    if (!user) {
      return res.status(401).json({
        success: false,
        message: 'Invalid credentials'
      });
    }

    const match = await bcrypt.compare(password, user.password);
    if (!match) {
      return res.status(401).json({
        success: false,
        message: 'Invalid credentials'
      });
    }

    const token = generateToken(user);

    res.json({
      success: true,
      message: 'Login successful',
      token,
      user: {
        id: user.id,
        name: user.name,
        role: user.role
      }
    });

  } catch (err) {
    res.status(500).json({
      success: false,
      message: 'Login failed'
    });
  }
});

export default router;
