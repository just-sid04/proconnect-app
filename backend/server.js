/**
 * ProConnect Backend Server
 * Node.js + Express REST API
 */

const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');
const path = require('path');

// Load environment variables
dotenv.config();

// Import routes
const authRoutes = require('./routes/auth.routes');
const userRoutes = require('./routes/user.routes');
const providerRoutes = require('./routes/provider.routes');
const bookingRoutes = require('./routes/booking.routes');
const reviewRoutes = require('./routes/review.routes');
const categoryRoutes = require('./routes/category.routes');
const adminRoutes = require('./routes/admin.routes');

// Initialize Express app
const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// Static files for uploads
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// API Routes
app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/providers', providerRoutes);
app.use('/api/bookings', bookingRoutes);
app.use('/api/reviews', reviewRoutes);
app.use('/api/categories', categoryRoutes);
app.use('/api/admin', adminRoutes);

// Health check endpoint
app.get('/api/health', (req, res) => {
  res.json({
    status: 'OK',
    message: 'ProConnect API is running',
    timestamp: new Date().toISOString(),
    version: '1.0.0'
  });
});

// Root endpoint
app.get('/', (req, res) => {
  res.json({
    name: 'ProConnect API',
    description: 'Smart Local Service Provider Platform',
    version: '1.0.0',
    endpoints: {
      auth: '/api/auth',
      users: '/api/users',
      providers: '/api/providers',
      bookings: '/api/bookings',
      reviews: '/api/reviews',
      categories: '/api/categories',
      admin: '/api/admin'
    }
  });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({
    success: false,
    message: 'Route not found'
  });
});

// Error handler
app.use((err, req, res, next) => {
  console.error('Error:', err);
  res.status(err.status || 500).json({
    success: false,
    message: err.message || 'Internal server error',
    error: process.env.NODE_ENV === 'development' ? err.stack : undefined
  });
});

// Start server
app.listen(PORT, () => {
  console.log(`
╔════════════════════════════════════════════════════════════╗
║                                                            ║
║           ProConnect API Server                            ║
║           Smart Local Service Provider Platform            ║
║                                                            ║
╚════════════════════════════════════════════════════════════╝

🚀 Server running on http://localhost:${PORT}
📚 API Documentation: http://localhost:${PORT}/
🔧 Environment: ${process.env.NODE_ENV || 'development'}

Available Endpoints:
  • Auth:      http://localhost:${PORT}/api/auth
  • Users:     http://localhost:${PORT}/api/users
  • Providers: http://localhost:${PORT}/api/providers
  • Bookings:  http://localhost:${PORT}/api/bookings
  • Reviews:   http://localhost:${PORT}/api/reviews
  • Categories:http://localhost:${PORT}/api/categories
  • Admin:     http://localhost:${PORT}/api/admin

Press Ctrl+C to stop the server.
  `);
});

module.exports = app;
