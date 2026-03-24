/**
 * Input Validation Middleware
 * Uses express-validator for request validation
 */

const { body, param, query, validationResult } = require('express-validator');

// Handle validation errors
const handleValidationErrors = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({
      success: false,
      message: 'Validation failed',
      errors: errors.array().map(err => ({
        field: err.path,
        message: err.msg
      }))
    });
  }
  next();
};

// Auth validators
const registerValidator = [
  body('name')
    .trim()
    .notEmpty().withMessage('Name is required')
    .isLength({ min: 2, max: 100 }).withMessage('Name must be between 2 and 100 characters'),
  body('email')
    .trim()
    .notEmpty().withMessage('Email is required')
    .isEmail().withMessage('Invalid email format')
    .normalizeEmail(),
  body('password')
    .notEmpty().withMessage('Password is required')
    .isLength({ min: 6 }).withMessage('Password must be at least 6 characters')
    .matches(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/).withMessage('Password must contain at least one uppercase letter, one lowercase letter, and one number'),
  body('phone')
    .optional()
    .trim()
    .matches(/^[\+]?[(]?[0-9]{3}[)]?[-\s\.]?[0-9]{3}[-\s\.]?[0-9]{4,6}$/).withMessage('Invalid phone number format'),
  body('role')
    .notEmpty().withMessage('Role is required')
    .isIn(['customer', 'provider']).withMessage('Role must be customer or provider'),
  handleValidationErrors
];

const loginValidator = [
  body('email')
    .trim()
    .notEmpty().withMessage('Email is required')
    .isEmail().withMessage('Invalid email format'),
  body('password')
    .notEmpty().withMessage('Password is required'),
  handleValidationErrors
];

// User validators
const updateProfileValidator = [
  body('name')
    .optional()
    .trim()
    .isLength({ min: 2, max: 100 }).withMessage('Name must be between 2 and 100 characters'),
  body('phone')
    .optional()
    .trim()
    .matches(/^[\+]?[(]?[0-9]{3}[)]?[-\s\.]?[0-9]{3}[-\s\.]?[0-9]{4,6}$/).withMessage('Invalid phone number format'),
  body('location')
    .optional()
    .isObject().withMessage('Location must be an object'),
  handleValidationErrors
];

// Provider validators
const createProviderValidator = [
  body('categoryId')
    .notEmpty().withMessage('Category ID is required'),
  body('skills')
    .isArray({ min: 1 }).withMessage('At least one skill is required'),
  body('experience')
    .notEmpty().withMessage('Experience is required')
    .isInt({ min: 0, max: 50 }).withMessage('Experience must be between 0 and 50 years'),
  body('hourlyRate')
    .optional()
    .isFloat({ min: 0, max: 1000 }).withMessage('Hourly rate must be between 0 and 1000'),
  body('description')
    .optional()
    .trim()
    .isLength({ max: 1000 }).withMessage('Description must not exceed 1000 characters'),
  body('serviceArea')
    .optional()
    .isInt({ min: 1, max: 100 }).withMessage('Service area must be between 1 and 100 miles'),
  handleValidationErrors
];

const updateAvailabilityValidator = [
  body('availability')
    .isObject().withMessage('Availability must be an object'),
  handleValidationErrors
];

// Booking validators
const createBookingValidator = [
  body('providerId')
    .notEmpty().withMessage('Provider ID is required'),
  body('categoryId')
    .notEmpty().withMessage('Category ID is required'),
  body('description')
    .trim()
    .notEmpty().withMessage('Description is required')
    .isLength({ min: 10, max: 1000 }).withMessage('Description must be between 10 and 1000 characters'),
  body('serviceLocation')
    .isObject().withMessage('Service location is required'),
  body('serviceLocation.address')
    .notEmpty().withMessage('Address is required'),
  body('scheduledDate')
    .notEmpty().withMessage('Scheduled date is required')
    .isISO8601().withMessage('Invalid date format'),
  body('scheduledTime')
    .notEmpty().withMessage('Scheduled time is required')
    .matches(/^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$/).withMessage('Invalid time format (HH:MM)'),
  handleValidationErrors
];

const updateBookingStatusValidator = [
  body('status')
    .notEmpty().withMessage('Status is required')
    .isIn(['pending', 'accepted', 'in-progress', 'completed', 'cancelled']).withMessage('Invalid status'),
  handleValidationErrors
];

// Review validators
const createReviewValidator = [
  body('bookingId')
    .notEmpty().withMessage('Booking ID is required'),
  body('providerId')
    .notEmpty().withMessage('Provider ID is required'),
  body('rating')
    .notEmpty().withMessage('Rating is required')
    .isInt({ min: 1, max: 5 }).withMessage('Rating must be between 1 and 5'),
  body('comment')
    .optional()
    .trim()
    .isLength({ max: 1000 }).withMessage('Comment must not exceed 1000 characters'),
  handleValidationErrors
];

// ID parameter validator
const idParamValidator = [
  param('id')
    .notEmpty().withMessage('ID is required'),
  handleValidationErrors
];

// Query validators
const paginationValidator = [
  query('page')
    .optional()
    .isInt({ min: 1 }).withMessage('Page must be a positive integer'),
  query('limit')
    .optional()
    .isInt({ min: 1, max: 100 }).withMessage('Limit must be between 1 and 100'),
  handleValidationErrors
];

const searchValidator = [
  query('q')
    .optional()
    .trim()
    .isLength({ min: 1, max: 100 }).withMessage('Search query must be between 1 and 100 characters'),
  query('category')
    .optional()
    .trim(),
  query('location')
    .optional()
    .trim(),
  handleValidationErrors
];

module.exports = {
  handleValidationErrors,
  registerValidator,
  loginValidator,
  updateProfileValidator,
  createProviderValidator,
  updateAvailabilityValidator,
  createBookingValidator,
  updateBookingStatusValidator,
  createReviewValidator,
  idParamValidator,
  paginationValidator,
  searchValidator
};
