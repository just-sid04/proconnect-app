/**
 * Review Routes
 * Handles ratings and reviews for service providers
 */

const express = require('express');
const router = express.Router();

const { readData, writeData, findById, findOne, generateId } = require('../utils/database');
const { verifyToken } = require('../middleware/auth');
const { createReviewValidator } = require('../middleware/validator');

// Get all reviews
router.get('/', (req, res) => {
  try {
    const { providerId, customerId, page = 1, limit = 10 } = req.query;
    
    let reviews = readData('reviews');
    const users = readData('users');
    const providers = readData('providers');
    
    // Filter by provider
    if (providerId) {
      reviews = reviews.filter(r => r.providerId === providerId);
    }
    
    // Filter by customer
    if (customerId) {
      reviews = reviews.filter(r => r.customerId === customerId);
    }
    
    // Sort by date (newest first)
    reviews.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));
    
    // Pagination
    const pageNum = parseInt(page);
    const limitNum = parseInt(limit);
    const startIndex = (pageNum - 1) * limitNum;
    const endIndex = startIndex + limitNum;
    const paginatedReviews = reviews.slice(startIndex, endIndex);
    
    // Enrich with user data
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
    console.error('Get reviews error:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching reviews'
    });
  }
});

// Get review by ID
router.get('/:id', (req, res) => {
  try {
    const { id } = req.params;
    
    const review = findById('reviews', id);
    
    if (!review) {
      return res.status(404).json({
        success: false,
        message: 'Review not found'
      });
    }
    
    // Enrich with user data
    const users = readData('users');
    const providers = readData('providers');
    
    const customer = users.find(u => u.id === review.customerId);
    const provider = providers.find(p => p.id === review.providerId);
    const providerUser = provider ? users.find(u => u.id === provider.userId) : null;
    
    res.json({
      success: true,
      data: {
        ...review,
        customer: customer ? (({ password, ...rest }) => rest)(customer) : null,
        provider: provider ? {
          ...provider,
          user: providerUser ? (({ password, ...rest }) => rest)(providerUser) : null
        } : null
      }
    });
  } catch (error) {
    console.error('Get review error:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching review'
    });
  }
});

// Create new review
router.post('/', verifyToken, createReviewValidator, (req, res) => {
  try {
    const { bookingId, providerId, rating, comment } = req.body;
    
    // Verify booking exists and belongs to user
    const booking = findById('bookings', bookingId);
    
    if (!booking) {
      return res.status(404).json({
        success: false,
        message: 'Booking not found'
      });
    }
    
    if (booking.customerId !== req.userId) {
      return res.status(403).json({
        success: false,
        message: 'Can only review your own bookings'
      });
    }
    
    // Check if booking is completed
    if (booking.status !== 'completed') {
      return res.status(400).json({
        success: false,
        message: 'Can only review completed bookings'
      });
    }
    
    // Check if already reviewed
    const existingReview = findOne('reviews', 'bookingId', bookingId);
    if (existingReview) {
      return res.status(409).json({
        success: false,
        message: 'Booking already reviewed'
      });
    }
    
    // Verify provider
    const provider = findById('providers', providerId);
    if (!provider) {
      return res.status(404).json({
        success: false,
        message: 'Provider not found'
      });
    }
    
    const newReview = {
      id: generateId('review'),
      bookingId,
      customerId: req.userId,
      providerId,
      rating: parseInt(rating),
      comment: comment || '',
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString()
    };
    
    const reviews = readData('reviews');
    reviews.push(newReview);
    writeData('reviews', reviews);
    
    // Update provider rating
    const providerReviews = reviews.filter(r => r.providerId === providerId);
    const totalRating = providerReviews.reduce((sum, r) => sum + r.rating, 0);
    const averageRating = totalRating / providerReviews.length;
    
    const providers = readData('providers');
    const providerIndex = providers.findIndex(p => p.id === providerId);
    providers[providerIndex].rating = Math.round(averageRating * 10) / 10;
    providers[providerIndex].totalReviews = providerReviews.length;
    writeData('providers', providers);
    
    res.status(201).json({
      success: true,
      message: 'Review created successfully',
      data: newReview
    });
  } catch (error) {
    console.error('Create review error:', error);
    res.status(500).json({
      success: false,
      message: 'Error creating review'
    });
  }
});

// Update review
router.put('/:id', verifyToken, (req, res) => {
  try {
    const { id } = req.params;
    const { rating, comment } = req.body;
    
    const review = findById('reviews', id);
    
    if (!review) {
      return res.status(404).json({
        success: false,
        message: 'Review not found'
      });
    }
    
    // Only review author can update
    if (review.customerId !== req.userId && req.userRole !== 'admin') {
      return res.status(403).json({
        success: false,
        message: 'Access denied'
      });
    }
    
    const reviews = readData('reviews');
    const reviewIndex = reviews.findIndex(r => r.id === id);
    
    if (rating !== undefined) {
      reviews[reviewIndex].rating = parseInt(rating);
    }
    
    if (comment !== undefined) {
      reviews[reviewIndex].comment = comment;
    }
    
    reviews[reviewIndex].updatedAt = new Date().toISOString();
    writeData('reviews', reviews);
    
    // Recalculate provider rating
    const providerId = reviews[reviewIndex].providerId;
    const providerReviews = reviews.filter(r => r.providerId === providerId);
    const totalRating = providerReviews.reduce((sum, r) => sum + r.rating, 0);
    const averageRating = totalRating / providerReviews.length;
    
    const providers = readData('providers');
    const providerIndex = providers.findIndex(p => p.id === providerId);
    providers[providerIndex].rating = Math.round(averageRating * 10) / 10;
    writeData('providers', providers);
    
    res.json({
      success: true,
      message: 'Review updated successfully',
      data: reviews[reviewIndex]
    });
  } catch (error) {
    console.error('Update review error:', error);
    res.status(500).json({
      success: false,
      message: 'Error updating review'
    });
  }
});

// Delete review
router.delete('/:id', verifyToken, (req, res) => {
  try {
    const { id } = req.params;
    
    const review = findById('reviews', id);
    
    if (!review) {
      return res.status(404).json({
        success: false,
        message: 'Review not found'
      });
    }
    
    // Only review author or admin can delete
    if (review.customerId !== req.userId && req.userRole !== 'admin') {
      return res.status(403).json({
        success: false,
        message: 'Access denied'
      });
    }
    
    const providerId = review.providerId;
    
    const reviews = readData('reviews').filter(r => r.id !== id);
    writeData('reviews', reviews);
    
    // Recalculate provider rating
    const providerReviews = reviews.filter(r => r.providerId === providerId);
    const providers = readData('providers');
    const providerIndex = providers.findIndex(p => p.id === providerId);
    
    if (providerReviews.length > 0) {
      const totalRating = providerReviews.reduce((sum, r) => sum + r.rating, 0);
      const averageRating = totalRating / providerReviews.length;
      providers[providerIndex].rating = Math.round(averageRating * 10) / 10;
      providers[providerIndex].totalReviews = providerReviews.length;
    } else {
      providers[providerIndex].rating = 0;
      providers[providerIndex].totalReviews = 0;
    }
    
    writeData('providers', providers);
    
    res.json({
      success: true,
      message: 'Review deleted successfully'
    });
  } catch (error) {
    console.error('Delete review error:', error);
    res.status(500).json({
      success: false,
      message: 'Error deleting review'
    });
  }
});

// Get provider rating summary
router.get('/summary/:providerId', (req, res) => {
  try {
    const { providerId } = req.params;
    
    const reviews = readData('reviews').filter(r => r.providerId === providerId);
    
    if (reviews.length === 0) {
      return res.json({
        success: true,
        data: {
          averageRating: 0,
          totalReviews: 0,
          ratingDistribution: {
            5: 0, 4: 0, 3: 0, 2: 0, 1: 0
          }
        }
      });
    }
    
    const totalRating = reviews.reduce((sum, r) => sum + r.rating, 0);
    const averageRating = totalRating / reviews.length;
    
    const distribution = { 5: 0, 4: 0, 3: 0, 2: 0, 1: 0 };
    reviews.forEach(r => {
      distribution[r.rating] = (distribution[r.rating] || 0) + 1;
    });
    
    res.json({
      success: true,
      data: {
        averageRating: Math.round(averageRating * 10) / 10,
        totalReviews: reviews.length,
        ratingDistribution: distribution
      }
    });
  } catch (error) {
    console.error('Get rating summary error:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching rating summary'
    });
  }
});

module.exports = router;
