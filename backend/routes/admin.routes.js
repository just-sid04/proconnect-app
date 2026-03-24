/**
 * Admin Routes
 * Handles administrative operations
 */

const express = require('express');
const router = express.Router();

const { readData, writeData, findById, getStats } = require('../utils/database');
const { verifyToken, isAdmin } = require('../middleware/auth');

// Get dashboard statistics
router.get('/dashboard', verifyToken, isAdmin, (req, res) => {
  try {
    const users = readData('users');
    const providers = readData('providers');
    const bookings = readData('bookings');
    const reviews = readData('reviews');
    const categories = readData('categories');
    
    // Calculate statistics
    const totalUsers = users.filter(u => u.role === 'customer').length;
    const totalProviders = providers.length;
    const verifiedProviders = providers.filter(p => p.isVerified).length;
    const pendingVerifications = providers.filter(p => p.verificationStatus === 'pending').length;
    
    const totalBookings = bookings.length;
    const pendingBookings = bookings.filter(b => b.status === 'pending').length;
    const completedBookings = bookings.filter(b => b.status === 'completed').length;
    const cancelledBookings = bookings.filter(b => b.status === 'cancelled').length;
    
    const totalRevenue = bookings
      .filter(b => b.status === 'completed')
      .reduce((sum, b) => sum + (b.price?.totalAmount || 0), 0);
    
    const totalReviews = reviews.length;
    const averageRating = reviews.length > 0
      ? Math.round((reviews.reduce((sum, r) => sum + r.rating, 0) / reviews.length) * 10) / 10
      : 0;
    
    // Recent activity
    const recentUsers = users
      .sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt))
      .slice(0, 5);
    
    const recentBookings = bookings
      .sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt))
      .slice(0, 5);
    
    res.json({
      success: true,
      data: {
        stats: {
          users: {
            total: totalUsers,
            newThisWeek: users.filter(u => {
              const weekAgo = new Date();
              weekAgo.setDate(weekAgo.getDate() - 7);
              return new Date(u.createdAt) > weekAgo && u.role === 'customer';
            }).length
          },
          providers: {
            total: totalProviders,
            verified: verifiedProviders,
            pendingVerification: pendingVerifications
          },
          bookings: {
            total: totalBookings,
            pending: pendingBookings,
            completed: completedBookings,
            cancelled: cancelledBookings
          },
          revenue: {
            total: totalRevenue,
            thisMonth: bookings
              .filter(b => {
                const bookingDate = new Date(b.createdAt);
                const now = new Date();
                return b.status === 'completed' && 
                       bookingDate.getMonth() === now.getMonth() &&
                       bookingDate.getFullYear() === now.getFullYear();
              })
              .reduce((sum, b) => sum + (b.price?.totalAmount || 0), 0)
          },
          reviews: {
            total: totalReviews,
            averageRating
          },
          categories: categories.length
        },
        recent: {
          users: recentUsers.map(u => ({ id: u.id, name: u.name, email: u.email, role: u.role, createdAt: u.createdAt })),
          bookings: recentBookings
        }
      }
    });
  } catch (error) {
    console.error('Get dashboard stats error:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching dashboard statistics'
    });
  }
});

// Get all users with pagination
router.get('/users', verifyToken, isAdmin, (req, res) => {
  try {
    const { role, page = 1, limit = 20, search } = req.query;
    
    let users = readData('users');
    
    // Filter by role
    if (role) {
      users = users.filter(u => u.role === role);
    }
    
    // Search
    if (search) {
      const searchTerm = search.toLowerCase();
      users = users.filter(u => 
        u.name.toLowerCase().includes(searchTerm) ||
        u.email.toLowerCase().includes(searchTerm)
      );
    }
    
    // Sort by created date
    users.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));
    
    // Pagination
    const pageNum = parseInt(page);
    const limitNum = parseInt(limit);
    const startIndex = (pageNum - 1) * limitNum;
    const endIndex = startIndex + limitNum;
    const paginatedUsers = users.slice(startIndex, endIndex);
    
    // Remove passwords
    const usersWithoutPasswords = paginatedUsers.map(user => {
      const { password, ...userData } = user;
      return userData;
    });
    
    res.json({
      success: true,
      count: users.length,
      pagination: {
        page: pageNum,
        limit: limitNum,
        totalPages: Math.ceil(users.length / limitNum),
        hasMore: endIndex < users.length
      },
      data: usersWithoutPasswords
    });
  } catch (error) {
    console.error('Get admin users error:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching users'
    });
  }
});

// Get all providers with pagination and filters
router.get('/providers', verifyToken, isAdmin, (req, res) => {
  try {
    const { verificationStatus, verified, page = 1, limit = 20, search } = req.query;

    let providers = readData('providers');
    const users = readData('users');

    if (verificationStatus) {
      providers = providers.filter(p => p.verificationStatus === verificationStatus);
    }

    if (verified === 'true') {
      providers = providers.filter(p => p.isVerified === true);
    } else if (verified === 'false') {
      providers = providers.filter(p => p.isVerified === false);
    }

    if (search) {
      const searchTerm = search.toLowerCase();
      providers = providers.filter(provider => {
        const user = users.find(u => u.id === provider.userId);
        return (
          provider.description?.toLowerCase().includes(searchTerm) ||
          provider.skills?.some(s => s.toLowerCase().includes(searchTerm)) ||
          user?.name?.toLowerCase().includes(searchTerm) ||
          user?.email?.toLowerCase().includes(searchTerm)
        );
      });
    }

    providers.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));

    const pageNum = parseInt(page);
    const limitNum = parseInt(limit);
    const startIndex = (pageNum - 1) * limitNum;
    const endIndex = startIndex + limitNum;
    const paginatedProviders = providers.slice(startIndex, endIndex);

    const enrichedProviders = paginatedProviders.map(provider => {
      const user = users.find(u => u.id === provider.userId);
      return {
        ...provider,
        user: user ? (({ password, ...rest }) => rest)(user) : null
      };
    });

    res.json({
      success: true,
      count: providers.length,
      pagination: {
        page: pageNum,
        limit: limitNum,
        totalPages: Math.ceil(providers.length / limitNum),
        hasMore: endIndex < providers.length
      },
      data: enrichedProviders
    });
  } catch (error) {
    console.error('Get admin providers error:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching providers'
    });
  }
});

// Verify provider
router.put('/providers/:id/verify', verifyToken, isAdmin, (req, res) => {
  try {
    const { id } = req.params;
    const { status, notes } = req.body;
    
    const provider = findById('providers', id);
    
    if (!provider) {
      return res.status(404).json({
        success: false,
        message: 'Provider not found'
      });
    }
    
    const providers = readData('providers');
    const providerIndex = providers.findIndex(p => p.id === id);
    
    providers[providerIndex].verificationStatus = status;
    providers[providerIndex].isVerified = status === 'approved';
    providers[providerIndex].verificationNotes = notes || '';
    providers[providerIndex].verifiedAt = new Date().toISOString();
    providers[providerIndex].updatedAt = new Date().toISOString();
    
    writeData('providers', providers);
    
    res.json({
      success: true,
      message: `Provider ${status} successfully`,
      data: providers[providerIndex]
    });
  } catch (error) {
    console.error('Verify provider error:', error);
    res.status(500).json({
      success: false,
      message: 'Error verifying provider'
    });
  }
});

// Get pending verifications
router.get('/verifications/pending', verifyToken, isAdmin, (req, res) => {
  try {
    const providers = readData('providers').filter(p => p.verificationStatus === 'pending');
    const users = readData('users');
    
    const enrichedProviders = providers.map(provider => {
      const user = users.find(u => u.id === provider.userId);
      return {
        ...provider,
        user: user ? (({ password, ...rest }) => rest)(user) : null
      };
    });
    
    res.json({
      success: true,
      count: enrichedProviders.length,
      data: enrichedProviders
    });
  } catch (error) {
    console.error('Get pending verifications error:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching pending verifications'
    });
  }
});

// Get all bookings (admin)
router.get('/bookings', verifyToken, isAdmin, (req, res) => {
  try {
    const { status, page = 1, limit = 20 } = req.query;
    
    let bookings = readData('bookings');
    
    if (status) {
      bookings = bookings.filter(b => b.status === status);
    }
    
    bookings.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));
    
    const pageNum = parseInt(page);
    const limitNum = parseInt(limit);
    const startIndex = (pageNum - 1) * limitNum;
    const endIndex = startIndex + limitNum;
    const paginatedBookings = bookings.slice(startIndex, endIndex);
    
    const users = readData('users');
    const providers = readData('providers');
    
    const enrichedBookings = paginatedBookings.map(booking => {
      const customer = users.find(u => u.id === booking.customerId);
      const providerData = providers.find(p => p.id === booking.providerId);
      const providerUser = providerData ? users.find(u => u.id === providerData.userId) : null;
      
      return {
        ...booking,
        customer: customer ? (({ password, ...rest }) => rest)(customer) : null,
        provider: providerData ? {
          ...providerData,
          user: providerUser ? (({ password, ...rest }) => rest)(providerUser) : null
        } : null
      };
    });
    
    res.json({
      success: true,
      count: bookings.length,
      pagination: {
        page: pageNum,
        limit: limitNum,
        totalPages: Math.ceil(bookings.length / limitNum),
        hasMore: endIndex < bookings.length
      },
      data: enrichedBookings
    });
  } catch (error) {
    console.error('Get admin bookings error:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching bookings'
    });
  }
});

// Get all reviews (admin)
router.get('/reviews', verifyToken, isAdmin, (req, res) => {
  try {
    const { page = 1, limit = 20 } = req.query;
    
    let reviews = readData('reviews');
    reviews.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));
    
    const pageNum = parseInt(page);
    const limitNum = parseInt(limit);
    const startIndex = (pageNum - 1) * limitNum;
    const endIndex = startIndex + limitNum;
    const paginatedReviews = reviews.slice(startIndex, endIndex);
    
    const users = readData('users');
    const providers = readData('providers');
    
    const enrichedReviews = paginatedReviews.map(review => {
      const customer = users.find(u => u.id === review.customerId);
      const provider = providers.find(p => p.id === review.providerId);
      const providerUser = provider ? users.find(u => u.id === provider.userId) : null;
      
      return {
        ...review,
        customer: customer ? (({ password, ...rest }) => rest)(customer) : null,
        provider: provider ? {
          ...provider,
          user: providerUser ? (({ password, ...rest }) => rest)(providerUser) : null
        } : null
      };
    });
    
    res.json({
      success: true,
      count: reviews.length,
      pagination: {
        page: pageNum,
        limit: limitNum,
        totalPages: Math.ceil(reviews.length / limitNum),
        hasMore: endIndex < reviews.length
      },
      data: enrichedReviews
    });
  } catch (error) {
    console.error('Get admin reviews error:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching reviews'
    });
  }
});

// Ban/unban user
router.put('/users/:id/ban', verifyToken, isAdmin, (req, res) => {
  try {
    const { id } = req.params;
    const { reason } = req.body;
    
    const user = findById('users', id);
    
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }
    
    // Prevent banning admin
    if (user.role === 'admin') {
      return res.status(403).json({
        success: false,
        message: 'Cannot ban admin users'
      });
    }
    
    const users = readData('users');
    const userIndex = users.findIndex(u => u.id === id);
    
    users[userIndex].isActive = false;
    users[userIndex].banReason = reason || '';
    users[userIndex].bannedAt = new Date().toISOString();
    users[userIndex].updatedAt = new Date().toISOString();
    
    writeData('users', users);
    
    res.json({
      success: true,
      message: 'User banned successfully'
    });
  } catch (error) {
    console.error('Ban user error:', error);
    res.status(500).json({
      success: false,
      message: 'Error banning user'
    });
  }
});

// Unban user
router.put('/users/:id/unban', verifyToken, isAdmin, (req, res) => {
  try {
    const { id } = req.params;
    
    const users = readData('users');
    const userIndex = users.findIndex(u => u.id === id);
    
    if (userIndex === -1) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }
    
    users[userIndex].isActive = true;
    users[userIndex].banReason = '';
    users[userIndex].bannedAt = null;
    users[userIndex].updatedAt = new Date().toISOString();
    
    writeData('users', users);
    
    res.json({
      success: true,
      message: 'User unbanned successfully'
    });
  } catch (error) {
    console.error('Unban user error:', error);
    res.status(500).json({
      success: false,
      message: 'Error unbanning user'
    });
  }
});

// Get system stats
router.get('/stats', verifyToken, isAdmin, (req, res) => {
  try {
    const stats = getStats();
    
    res.json({
      success: true,
      data: stats
    });
  } catch (error) {
    console.error('Get system stats error:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching system stats'
    });
  }
});

module.exports = router;
