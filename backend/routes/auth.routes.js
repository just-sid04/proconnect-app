/**
 * Authentication Routes
 * Handles user registration, login, and token management
 */

const express = require('express');
const bcrypt = require('bcryptjs');
const router = express.Router();

const { readData, writeData, findOne, insert, generateId } = require('../utils/database');
const { generateToken, verifyToken } = require('../middleware/auth');
const { registerValidator, loginValidator } = require('../middleware/validator');

// Register new user
router.post('/register', registerValidator, async (req, res) => {
  try {
    const { name, email, password, phone, role, location } = req.body;
    
    // Check if user already exists
    const existingUser = findOne('users', 'email', email);
    if (existingUser) {
      return res.status(409).json({
        success: false,
        message: 'User with this email already exists'
      });
    }
    
    // Hash password
    const saltRounds = 10;
    const hashedPassword = await bcrypt.hash(password, saltRounds);
    
    // Create new user
    const newUser = {
      id: generateId('user'),
      name,
      email,
      password: hashedPassword,
      phone: phone || '',
      role,
      profilePhoto: '',
      location: location || null,
      isActive: true,
      isVerified: false,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString()
    };
    
    // Save user
    insert('users', newUser);
    
    // Generate token
    const token = generateToken(newUser);
    
    // Return user data (without password)
    const { password: _, ...userData } = newUser;
    
    res.status(201).json({
      success: true,
      message: 'User registered successfully',
      data: {
        user: userData,
        token
      }
    });
  } catch (error) {
    console.error('Registration error:', error);
    res.status(500).json({
      success: false,
      message: 'Error registering user'
    });
  }
});

// Login user
router.post('/login', loginValidator, async (req, res) => {
  try {
    const { email, password } = req.body;
    
    // Find user by email
    const user = findOne('users', 'email', email);
    if (!user) {
      return res.status(401).json({
        success: false,
        message: 'Invalid email or password'
      });
    }
    
    // Check if user is active
    if (!user.isActive) {
      return res.status(403).json({
        success: false,
        message: 'Account has been deactivated. Please contact support.'
      });
    }
    
    // Verify password
    const isPasswordValid = await bcrypt.compare(password, user.password);
    if (!isPasswordValid) {
      return res.status(401).json({
        success: false,
        message: 'Invalid email or password'
      });
    }
    
    // Generate token
    const token = generateToken(user);
    
    // Return user data (without password)
    const { password: _, ...userData } = user;
    
    res.json({
      success: true,
      message: 'Login successful',
      data: {
        user: userData,
        token
      }
    });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({
      success: false,
      message: 'Error logging in'
    });
  }
});

// Get current user profile
router.get('/me', verifyToken, (req, res) => {
  try {
    const user = findOne('users', 'id', req.userId);
    
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }
    
    // Return user data (without password)
    const { password: _, ...userData } = user;
    
    res.json({
      success: true,
      data: userData
    });
  } catch (error) {
    console.error('Get profile error:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching user profile'
    });
  }
});

// Refresh token
router.post('/refresh', verifyToken, (req, res) => {
  try {
    const user = findOne('users', 'id', req.userId);
    
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }
    
    const token = generateToken(user);
    
    res.json({
      success: true,
      data: { token }
    });
  } catch (error) {
    console.error('Token refresh error:', error);
    res.status(500).json({
      success: false,
      message: 'Error refreshing token'
    });
  }
});

// Change password
router.post('/change-password', verifyToken, async (req, res) => {
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
    
    const user = findOne('users', 'id', req.userId);
    
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }
    
    // Verify current password
    const isPasswordValid = await bcrypt.compare(currentPassword, user.password);
    if (!isPasswordValid) {
      return res.status(401).json({
        success: false,
        message: 'Current password is incorrect'
      });
    }
    
    // Hash new password
    const saltRounds = 10;
    const hashedPassword = await bcrypt.hash(newPassword, saltRounds);
    
    // Update password
    const users = readData('users');
    const userIndex = users.findIndex(u => u.id === req.userId);
    users[userIndex].password = hashedPassword;
    users[userIndex].updatedAt = new Date().toISOString();
    writeData('users', users);
    
    res.json({
      success: true,
      message: 'Password changed successfully'
    });
  } catch (error) {
    console.error('Change password error:', error);
    res.status(500).json({
      success: false,
      message: 'Error changing password'
    });
  }
});

// Logout (client-side token removal, but we can track if needed)
router.post('/logout', verifyToken, (req, res) => {
  res.json({
    success: true,
    message: 'Logged out successfully'
  });
});

module.exports = router;
