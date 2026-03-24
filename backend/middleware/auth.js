/**
 * Authentication Middleware
 * Handles JWT verification and role-based access control
 */

const jwt = require('jsonwebtoken');
const { findById } = require('../utils/database');

const JWT_SECRET = process.env.JWT_SECRET || 'your-super-secret-jwt-key';

// Verify JWT token
const verifyToken = (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({
        success: false,
        message: 'Access denied. No token provided.'
      });
    }
    
    const token = authHeader.split(' ')[1];
    
    jwt.verify(token, JWT_SECRET, (err, decoded) => {
      if (err) {
        return res.status(401).json({
          success: false,
          message: 'Invalid or expired token'
        });
      }
      
      req.userId = decoded.userId;
      req.userRole = decoded.role;
      req.userEmail = decoded.email;
      
      next();
    });
  } catch (error) {
    console.error('Auth middleware error:', error);
    return res.status(500).json({
      success: false,
      message: 'Authentication error'
    });
  }
};

// Check if user is admin
const isAdmin = (req, res, next) => {
  if (req.userRole !== 'admin') {
    return res.status(403).json({
      success: false,
      message: 'Access denied. Admin privileges required.'
    });
  }
  next();
};

// Check if user is provider
const isProvider = (req, res, next) => {
  if (req.userRole !== 'provider') {
    return res.status(403).json({
      success: false,
      message: 'Access denied. Provider privileges required.'
    });
  }
  next();
};

// Check if user is customer
const isCustomer = (req, res, next) => {
  if (req.userRole !== 'customer') {
    return res.status(403).json({
      success: false,
      message: 'Access denied. Customer privileges required.'
    });
  }
  next();
};

// Check if user owns the resource or is admin
const isOwnerOrAdmin = (getUserIdFromRequest) => {
  return (req, res, next) => {
    const resourceUserId = getUserIdFromRequest(req);
    
    if (req.userRole !== 'admin' && req.userId !== resourceUserId) {
      return res.status(403).json({
        success: false,
        message: 'Access denied. You can only access your own resources.'
      });
    }
    next();
  };
};

// Optional authentication - doesn't fail if no token
const optionalAuth = (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return next();
    }
    
    const token = authHeader.split(' ')[1];
    
    jwt.verify(token, JWT_SECRET, (err, decoded) => {
      if (!err) {
        req.userId = decoded.userId;
        req.userRole = decoded.role;
        req.userEmail = decoded.email;
      }
      next();
    });
  } catch (error) {
    next();
  }
};

// Generate JWT token
const generateToken = (user) => {
  return jwt.sign(
    {
      userId: user.id,
      email: user.email,
      role: user.role,
      name: user.name
    },
    JWT_SECRET,
    { expiresIn: process.env.JWT_EXPIRE || '7d' }
  );
};

module.exports = {
  verifyToken,
  isAdmin,
  isProvider,
  isCustomer,
  isOwnerOrAdmin,
  optionalAuth,
  generateToken
};
