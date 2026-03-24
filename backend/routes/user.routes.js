/**
 * User Routes
 * Handles user profile management
 */

const express = require('express');
const router = express.Router();

const { readData, writeData, findOne, findById } = require('../utils/database');
const { verifyToken, isOwnerOrAdmin } = require('../middleware/auth');
const { updateProfileValidator, idParamValidator } = require('../middleware/validator');
const { getFileUrl } = require('../middleware/upload');

// Get all users (admin only)
router.get('/', verifyToken, (req, res) => {
  try {
    if (req.userRole !== 'admin') {
      return res.status(403).json({
        success: false,
        message: 'Admin access required'
      });
    }
    
    const users = readData('users');
    const usersWithoutPasswords = users.map(user => {
      const { password, ...userData } = user;
      return userData;
    });
    
    res.json({
      success: true,
      count: usersWithoutPasswords.length,
      data: usersWithoutPasswords
    });
  } catch (error) {
    console.error('Get users error:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching users'
    });
  }
});

// Get current user profile
router.get('/me', verifyToken, (req, res) => {
  try {
    const user = findById('users', req.userId);

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    const { password, ...userData } = user;

    res.json({
      success: true,
      data: userData
    });
  } catch (error) {
    console.error('Get current user error:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching user'
    });
  }
});

// Update current user profile
router.put('/me', verifyToken, updateProfileValidator, (req, res) => {
  try {
    const user = findById('users', req.userId);

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    const updates = { ...req.body };
    delete updates.password;
    delete updates.role;
    delete updates.id;

    const users = readData('users');
    const userIndex = users.findIndex(u => u.id === req.userId);

    users[userIndex] = {
      ...users[userIndex],
      ...updates,
      updatedAt: new Date().toISOString()
    };

    writeData('users', users);

    const { password, ...updatedUser } = users[userIndex];

    res.json({
      success: true,
      message: 'Profile updated successfully',
      data: updatedUser
    });
  } catch (error) {
    console.error('Update current user error:', error);
    res.status(500).json({
      success: false,
      message: 'Error updating user'
    });
  }
});

// Get user by ID
router.get('/:id', verifyToken, idParamValidator, (req, res) => {
  try {
    const { id } = req.params;
    
    // Users can only view their own profile unless they're admin
    if (req.userRole !== 'admin' && req.userId !== id) {
      return res.status(403).json({
        success: false,
        message: 'Access denied'
      });
    }
    
    const user = findById('users', id);
    
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }
    
    const { password, ...userData } = user;
    
    res.json({
      success: true,
      data: userData
    });
  } catch (error) {
    console.error('Get user error:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching user'
    });
  }
});

// Update user profile
router.put('/:id', verifyToken, idParamValidator, updateProfileValidator, (req, res) => {
  try {
    const { id } = req.params;
    
    // Users can only update their own profile unless they're admin
    if (req.userRole !== 'admin' && req.userId !== id) {
      return res.status(403).json({
        success: false,
        message: 'Access denied'
      });
    }
    
    const user = findById('users', id);
    
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }
    
    const updates = req.body;
    delete updates.password; // Prevent password update through this route
    delete updates.role; // Prevent role change through this route
    delete updates.id; // Prevent ID change
    
    const users = readData('users');
    const userIndex = users.findIndex(u => u.id === id);
    
    users[userIndex] = {
      ...users[userIndex],
      ...updates,
      updatedAt: new Date().toISOString()
    };
    
    writeData('users', users);
    
    const { password, ...updatedUser } = users[userIndex];
    
    res.json({
      success: true,
      message: 'Profile updated successfully',
      data: updatedUser
    });
  } catch (error) {
    console.error('Update user error:', error);
    res.status(500).json({
      success: false,
      message: 'Error updating user'
    });
  }
});

// Update profile photo
router.put('/:id/photo', verifyToken, (req, res) => {
  try {
    const { id } = req.params;
    const { photoUrl } = req.body;
    
    if (req.userId !== id && req.userRole !== 'admin') {
      return res.status(403).json({
        success: false,
        message: 'Access denied'
      });
    }
    
    const users = readData('users');
    const userIndex = users.findIndex(u => u.id === id);
    
    if (userIndex === -1) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }
    
    users[userIndex].profilePhoto = photoUrl;
    users[userIndex].updatedAt = new Date().toISOString();
    
    writeData('users', users);
    
    res.json({
      success: true,
      message: 'Profile photo updated successfully',
      data: { photoUrl }
    });
  } catch (error) {
    console.error('Update photo error:', error);
    res.status(500).json({
      success: false,
      message: 'Error updating profile photo'
    });
  }
});

// Delete user (admin only)
router.delete('/:id', verifyToken, idParamValidator, (req, res) => {
  try {
    if (req.userRole !== 'admin') {
      return res.status(403).json({
        success: false,
        message: 'Admin access required'
      });
    }
    
    const { id } = req.params;
    
    // Prevent deleting yourself
    if (req.userId === id) {
      return res.status(400).json({
        success: false,
        message: 'Cannot delete your own account'
      });
    }
    
    const users = readData('users');
    const filteredUsers = users.filter(u => u.id !== id);
    
    if (filteredUsers.length === users.length) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }
    
    writeData('users', filteredUsers);
    
    res.json({
      success: true,
      message: 'User deleted successfully'
    });
  } catch (error) {
    console.error('Delete user error:', error);
    res.status(500).json({
      success: false,
      message: 'Error deleting user'
    });
  }
});

// Deactivate user account
router.put('/:id/deactivate', verifyToken, (req, res) => {
  try {
    const { id } = req.params;
    
    if (req.userId !== id && req.userRole !== 'admin') {
      return res.status(403).json({
        success: false,
        message: 'Access denied'
      });
    }
    
    const users = readData('users');
    const userIndex = users.findIndex(u => u.id === id);
    
    if (userIndex === -1) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }
    
    users[userIndex].isActive = false;
    users[userIndex].updatedAt = new Date().toISOString();
    
    writeData('users', users);
    
    res.json({
      success: true,
      message: 'Account deactivated successfully'
    });
  } catch (error) {
    console.error('Deactivate user error:', error);
    res.status(500).json({
      success: false,
      message: 'Error deactivating account'
    });
  }
});

module.exports = router;
