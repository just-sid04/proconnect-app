/**
 * Booking Routes
 * Handles service booking operations
 */

const express = require('express');
const router = express.Router();

const { readData, writeData, findById, generateId } = require('../utils/database');
const { verifyToken } = require('../middleware/auth');
const { createBookingValidator, updateBookingStatusValidator } = require('../middleware/validator');

// Get all bookings for current user
router.get('/', verifyToken, (req, res) => {
  try {
    const { status, role = 'customer', page = 1, limit = 10 } = req.query;
    
    let bookings = readData('bookings');
    const users = readData('users');
    const providers = readData('providers');
    
    // Filter by user role
    if (role === 'provider') {
      const provider = providers.find(p => p.userId === req.userId);
      if (!provider) {
        return res.status(404).json({
          success: false,
          message: 'Provider profile not found'
        });
      }
      bookings = bookings.filter(b => b.providerId === provider.id);
    } else {
      bookings = bookings.filter(b => b.customerId === req.userId);
    }
    
    // Filter by status
    if (status) {
      bookings = bookings.filter(b => b.status === status);
    }
    
    // Sort by created date (newest first)
    bookings.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));
    
    // Pagination
    const pageNum = parseInt(page);
    const limitNum = parseInt(limit);
    const startIndex = (pageNum - 1) * limitNum;
    const endIndex = startIndex + limitNum;
    const paginatedBookings = bookings.slice(startIndex, endIndex);
    
    // Enrich with user and provider data
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
    console.error('Get bookings error:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching bookings'
    });
  }
});

// Get booking by ID
router.get('/:id', verifyToken, (req, res) => {
  try {
    const { id } = req.params;
    
    const booking = findById('bookings', id);
    
    if (!booking) {
      return res.status(404).json({
        success: false,
        message: 'Booking not found'
      });
    }
    
    // Check access
    const providers = readData('providers');
    const provider = providers.find(p => p.id === booking.providerId);
    
    if (booking.customerId !== req.userId && 
        (!provider || provider.userId !== req.userId) && 
        req.userRole !== 'admin') {
      return res.status(403).json({
        success: false,
        message: 'Access denied'
      });
    }
    
    // Enrich with user and provider data
    const users = readData('users');
    const customer = users.find(u => u.id === booking.customerId);
    const providerData = providers.find(p => p.id === booking.providerId);
    const providerUser = providerData ? users.find(u => u.id === providerData.userId) : null;
    
    res.json({
      success: true,
      data: {
        ...booking,
        customer: customer ? (({ password, ...rest }) => rest)(customer) : null,
        provider: providerData ? {
          ...providerData,
          user: providerUser ? (({ password, ...rest }) => rest)(providerUser) : null
        } : null
      }
    });
  } catch (error) {
    console.error('Get booking error:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching booking'
    });
  }
});

// Create new booking
router.post('/', verifyToken, createBookingValidator, (req, res) => {
  try {
    const { 
      providerId, 
      categoryId, 
      description, 
      serviceLocation, 
      scheduledDate, 
      scheduledTime,
      estimatedDuration,
      notes 
    } = req.body;
    
    // Verify provider exists
    const provider = findById('providers', providerId);
    if (!provider) {
      return res.status(404).json({
        success: false,
        message: 'Provider not found'
      });
    }
    
    // Check if provider is verified
    if (!provider.isVerified) {
      return res.status(400).json({
        success: false,
        message: 'Cannot book with unverified provider'
      });
    }
    
    // Prevent booking yourself
    if (provider.userId === req.userId) {
      return res.status(400).json({
        success: false,
        message: 'Cannot book your own services'
      });
    }
    
    // Calculate estimated price
    const estimatedHours = parseInt(estimatedDuration) || 2;
    const totalAmount = provider.hourlyRate * estimatedHours;
    
    const newBooking = {
      id: generateId('booking'),
      customerId: req.userId,
      providerId,
      categoryId,
      status: 'pending',
      description,
      serviceLocation,
      scheduledDate,
      scheduledTime,
      estimatedDuration: estimatedHours,
      price: {
        hourlyRate: provider.hourlyRate,
        estimatedHours,
        totalAmount,
        materialsCost: 0
      },
      notes: notes || '',
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
      acceptedAt: null,
      startedAt: null,
      completedAt: null,
      cancelledAt: null,
      cancellationReason: null
    };
    
    const bookings = readData('bookings');
    bookings.push(newBooking);
    writeData('bookings', bookings);
    
    res.status(201).json({
      success: true,
      message: 'Booking created successfully',
      data: newBooking
    });
  } catch (error) {
    console.error('Create booking error:', error);
    res.status(500).json({
      success: false,
      message: 'Error creating booking'
    });
  }
});

// Update booking status
router.put('/:id/status', verifyToken, updateBookingStatusValidator, (req, res) => {
  try {
    const { id } = req.params;
    const { status, cancellationReason } = req.body;
    
    const booking = findById('bookings', id);
    
    if (!booking) {
      return res.status(404).json({
        success: false,
        message: 'Booking not found'
      });
    }
    
    // Get provider info
    const providers = readData('providers');
    const provider = providers.find(p => p.id === booking.providerId);
    
    // Check permissions based on status change
    const isCustomer = booking.customerId === req.userId;
    const isProvider = provider && provider.userId === req.userId;
    const isAdmin = req.userRole === 'admin';
    
    // Validate status transitions and permissions
    const validTransitions = {
      'pending': ['accepted', 'cancelled'],
      'accepted': ['in-progress', 'cancelled'],
      'in-progress': ['completed', 'cancelled'],
      'completed': [],
      'cancelled': []
    };
    
    if (!validTransitions[booking.status].includes(status)) {
      return res.status(400).json({
        success: false,
        message: `Cannot transition from ${booking.status} to ${status}`
      });
    }
    
    // Check who can perform the action
    if (status === 'accepted' && !isProvider && !isAdmin) {
      return res.status(403).json({
        success: false,
        message: 'Only the provider can accept bookings'
      });
    }
    
    if (status === 'in-progress' && !isProvider && !isAdmin) {
      return res.status(403).json({
        success: false,
        message: 'Only the provider can start the service'
      });
    }
    
    if (status === 'completed' && !isProvider && !isAdmin) {
      return res.status(403).json({
        success: false,
        message: 'Only the provider can complete bookings'
      });
    }
    
    if (status === 'cancelled' && !isCustomer && !isProvider && !isAdmin) {
      return res.status(403).json({
        success: false,
        message: 'Only involved parties can cancel bookings'
      });
    }
    
    const bookings = readData('bookings');
    const bookingIndex = bookings.findIndex(b => b.id === id);
    
    bookings[bookingIndex].status = status;
    bookings[bookingIndex].updatedAt = new Date().toISOString();
    
    // Set timestamp based on status
    if (status === 'accepted') {
      bookings[bookingIndex].acceptedAt = new Date().toISOString();
    } else if (status === 'in-progress') {
      bookings[bookingIndex].startedAt = new Date().toISOString();
    } else if (status === 'completed') {
      bookings[bookingIndex].completedAt = new Date().toISOString();
      
      // Update provider stats
      if (provider) {
        const providerIndex = providers.findIndex(p => p.id === booking.providerId);
        providers[providerIndex].totalBookings += 1;
        writeData('providers', providers);
      }
    } else if (status === 'cancelled') {
      bookings[bookingIndex].cancelledAt = new Date().toISOString();
      bookings[bookingIndex].cancellationReason = cancellationReason || '';
    }
    
    writeData('bookings', bookings);
    
    res.json({
      success: true,
      message: `Booking ${status} successfully`,
      data: bookings[bookingIndex]
    });
  } catch (error) {
    console.error('Update booking status error:', error);
    res.status(500).json({
      success: false,
      message: 'Error updating booking status'
    });
  }
});

// Update booking details (before acceptance)
router.put('/:id', verifyToken, (req, res) => {
  try {
    const { id } = req.params;
    const updates = req.body;
    
    const booking = findById('bookings', id);
    
    if (!booking) {
      return res.status(404).json({
        success: false,
        message: 'Booking not found'
      });
    }
    
    // Only customer can update, and only if pending
    if (booking.customerId !== req.userId) {
      return res.status(403).json({
        success: false,
        message: 'Only the customer can update booking details'
      });
    }
    
    if (booking.status !== 'pending') {
      return res.status(400).json({
        success: false,
        message: 'Cannot update booking after it has been accepted'
      });
    }
    
    // Restrict what can be updated
    const allowedUpdates = ['description', 'serviceLocation', 'scheduledDate', 'scheduledTime', 'estimatedDuration', 'notes'];
    const filteredUpdates = {};
    
    allowedUpdates.forEach(key => {
      if (updates[key] !== undefined) {
        filteredUpdates[key] = updates[key];
      }
    });
    
    // Recalculate price if duration changed
    if (filteredUpdates.estimatedDuration) {
      const provider = findById('providers', booking.providerId);
      if (provider) {
        const hours = parseInt(filteredUpdates.estimatedDuration);
        filteredUpdates.price = {
          ...booking.price,
          estimatedHours: hours,
          totalAmount: provider.hourlyRate * hours
        };
      }
    }
    
    const bookings = readData('bookings');
    const bookingIndex = bookings.findIndex(b => b.id === id);
    
    bookings[bookingIndex] = {
      ...bookings[bookingIndex],
      ...filteredUpdates,
      updatedAt: new Date().toISOString()
    };
    
    writeData('bookings', bookings);
    
    res.json({
      success: true,
      message: 'Booking updated successfully',
      data: bookings[bookingIndex]
    });
  } catch (error) {
    console.error('Update booking error:', error);
    res.status(500).json({
      success: false,
      message: 'Error updating booking'
    });
  }
});

// Delete booking (only pending bookings)
router.delete('/:id', verifyToken, (req, res) => {
  try {
    const { id } = req.params;
    
    const booking = findById('bookings', id);
    
    if (!booking) {
      return res.status(404).json({
        success: false,
        message: 'Booking not found'
      });
    }
    
    // Get provider info
    const providers = readData('providers');
    const provider = providers.find(p => p.id === booking.providerId);
    
    const isCustomer = booking.customerId === req.userId;
    const isProvider = provider && provider.userId === req.userId;
    const isAdmin = req.userRole === 'admin';
    
    if (!isCustomer && !isProvider && !isAdmin) {
      return res.status(403).json({
        success: false,
        message: 'Access denied'
      });
    }
    
    // Only allow deletion of pending or cancelled bookings
    if (!['pending', 'cancelled'].includes(booking.status)) {
      return res.status(400).json({
        success: false,
        message: 'Cannot delete active bookings'
      });
    }
    
    const bookings = readData('bookings').filter(b => b.id !== id);
    writeData('bookings', bookings);
    
    res.json({
      success: true,
      message: 'Booking deleted successfully'
    });
  } catch (error) {
    console.error('Delete booking error:', error);
    res.status(500).json({
      success: false,
      message: 'Error deleting booking'
    });
  }
});

module.exports = router;
