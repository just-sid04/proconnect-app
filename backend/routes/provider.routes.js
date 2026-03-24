/**
 * Provider Routes
 * Handles service provider profiles and discovery
 */

const express = require('express');
const router = express.Router();

const { readData, writeData, findOne, findMany, findById, query, generateId } = require('../utils/database');
const { verifyToken, optionalAuth } = require('../middleware/auth');
const { createProviderValidator, updateAvailabilityValidator, paginationValidator, searchValidator } = require('../middleware/validator');

// Get all providers with filters
router.get('/', optionalAuth, searchValidator, paginationValidator, (req, res) => {
  try {
    const { 
      category, 
      location, 
      minRating, 
      maxRate, 
      skills,
      verified,
      q,
      page = 1, 
      limit = 10 
    } = req.query;
    
    let providers = readData('providers');
    const users = readData('users');
    
    // Apply filters
    if (category) {
      providers = providers.filter(p => p.categoryId === category);
    }
    
    if (minRating) {
      providers = providers.filter(p => p.rating >= parseFloat(minRating));
    }
    
    if (maxRate) {
      providers = providers.filter(p => p.hourlyRate <= parseFloat(maxRate));
    }
    
    if (skills) {
      const skillList = skills.split(',').map(s => s.trim().toLowerCase());
      providers = providers.filter(p => 
        skillList.some(skill => 
          p.skills.some(ps => ps.toLowerCase().includes(skill))
        )
      );
    }
    
    if (verified === 'true') {
      providers = providers.filter(p => p.isVerified);
    }
    
    if (q) {
      const searchTerm = q.toLowerCase();
      providers = providers.filter(p => {
        const user = users.find(u => u.id === p.userId);
        return (
          p.description.toLowerCase().includes(searchTerm) ||
          p.skills.some(s => s.toLowerCase().includes(searchTerm)) ||
          (user && user.name.toLowerCase().includes(searchTerm))
        );
      });
    }
    
    // Sort by rating (highest first)
    providers.sort((a, b) => b.rating - a.rating);
    
    // Pagination
    const pageNum = parseInt(page);
    const limitNum = parseInt(limit);
    const startIndex = (pageNum - 1) * limitNum;
    const endIndex = startIndex + limitNum;
    const paginatedProviders = providers.slice(startIndex, endIndex);
    
    // Enrich with user data
    const enrichedProviders = paginatedProviders.map(provider => {
      const user = users.find(u => u.id === provider.userId);
      const { password, ...userData } = user || {};
      return {
        ...provider,
        user: userData
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
    console.error('Get providers error:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching providers'
    });
  }
});

// Get nearby providers
router.get('/nearby', (req, res) => {
  try {
    const { lat, lng, radius = 10, page = 1, limit = 10 } = req.query;
    
    if (!lat || !lng) {
      return res.status(400).json({
        success: false,
        message: 'Latitude and longitude are required'
      });
    }
    
    const latitude = parseFloat(lat);
    const longitude = parseFloat(lng);
    const radiusKm = parseFloat(radius);
    
    const providers = readData('providers');
    const users = readData('users');
    
    // Calculate distance using Haversine formula
    const getDistance = (lat1, lon1, lat2, lon2) => {
      const R = 6371; // Earth's radius in km
      const dLat = (lat2 - lat1) * Math.PI / 180;
      const dLon = (lon2 - lon1) * Math.PI / 180;
      const a = Math.sin(dLat/2) * Math.sin(dLat/2) +
                Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
                Math.sin(dLon/2) * Math.sin(dLon/2);
      const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
      return R * c;
    };
    
    // Filter providers by distance
    let nearbyProviders = providers.map(provider => {
      const user = users.find(u => u.id === provider.userId);
      if (!user || !user.location || !user.location.latitude) {
        return null;
      }
      
      const distance = getDistance(
        latitude, 
        longitude, 
        user.location.latitude, 
        user.location.longitude
      );
      
      return {
        ...provider,
        distance: Math.round(distance * 10) / 10,
        user: (({ password, ...rest }) => rest)(user)
      };
    }).filter(p => p && p.distance <= radiusKm);
    
    // Sort by distance
    nearbyProviders.sort((a, b) => a.distance - b.distance);
    
    // Pagination
    const pageNum = parseInt(page);
    const limitNum = parseInt(limit);
    const startIndex = (pageNum - 1) * limitNum;
    const endIndex = startIndex + limitNum;
    const paginatedProviders = nearbyProviders.slice(startIndex, endIndex);
    
    res.json({
      success: true,
      count: nearbyProviders.length,
      pagination: {
        page: pageNum,
        limit: limitNum,
        totalPages: Math.ceil(nearbyProviders.length / limitNum),
        hasMore: endIndex < nearbyProviders.length
      },
      data: paginatedProviders
    });
  } catch (error) {
    console.error('Get nearby providers error:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching nearby providers'
    });
  }
});

// Get provider by ID
router.get('/:id', optionalAuth, (req, res) => {
  try {
    const { id } = req.params;
    
    const provider = findById('providers', id);
    
    if (!provider) {
      return res.status(404).json({
        success: false,
        message: 'Provider not found'
      });
    }
    
    // Get user data
    const user = findById('users', provider.userId);
    const { password, ...userData } = user || {};
    
    // Get reviews
    const reviews = readData('reviews').filter(r => r.providerId === id);
    
    // Get category
    const category = findById('categories', provider.categoryId);
    
    res.json({
      success: true,
      data: {
        ...provider,
        user: userData,
        category,
        reviews
      }
    });
  } catch (error) {
    console.error('Get provider error:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching provider'
    });
  }
});

// Create provider profile
router.post('/', verifyToken, createProviderValidator, (req, res) => {
  try {
    // Check if user already has a provider profile
    const existingProvider = findOne('providers', 'userId', req.userId);
    if (existingProvider) {
      return res.status(409).json({
        success: false,
        message: 'User already has a provider profile'
      });
    }
    
    const { categoryId, skills, experience, hourlyRate, description, availability, serviceArea } = req.body;
    
    // Verify category exists
    const category = findById('categories', categoryId);
    if (!category) {
      return res.status(404).json({
        success: false,
        message: 'Category not found'
      });
    }
    
    const newProvider = {
      id: generateId('provider'),
      userId: req.userId,
      categoryId,
      skills: Array.isArray(skills) ? skills : [skills],
      experience: parseInt(experience) || 0,
      hourlyRate: parseFloat(hourlyRate) || 0,
      description: description || '',
      availability: availability || {
        monday: { available: true, startTime: '09:00', endTime: '17:00' },
        tuesday: { available: true, startTime: '09:00', endTime: '17:00' },
        wednesday: { available: true, startTime: '09:00', endTime: '17:00' },
        thursday: { available: true, startTime: '09:00', endTime: '17:00' },
        friday: { available: true, startTime: '09:00', endTime: '17:00' },
        saturday: { available: false, startTime: '', endTime: '' },
        sunday: { available: false, startTime: '', endTime: '' }
      },
      serviceArea: parseInt(serviceArea) || 10,
      isVerified: false,
      verificationStatus: 'pending',
      rating: 0,
      totalReviews: 0,
      totalBookings: 0,
      portfolio: [],
      documents: [],
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString()
    };
    
    const providers = readData('providers');
    providers.push(newProvider);
    writeData('providers', providers);
    
    // Update user role to provider
    const users = readData('users');
    const userIndex = users.findIndex(u => u.id === req.userId);
    if (userIndex !== -1) {
      users[userIndex].role = 'provider';
      users[userIndex].updatedAt = new Date().toISOString();
      writeData('users', users);
    }
    
    res.status(201).json({
      success: true,
      message: 'Provider profile created successfully',
      data: newProvider
    });
  } catch (error) {
    console.error('Create provider error:', error);
    res.status(500).json({
      success: false,
      message: 'Error creating provider profile'
    });
  }
});

// Update provider profile
router.put('/:id', verifyToken, (req, res) => {
  try {
    const { id } = req.params;
    
    const provider = findById('providers', id);
    
    if (!provider) {
      return res.status(404).json({
        success: false,
        message: 'Provider not found'
      });
    }
    
    // Only owner or admin can update
    if (provider.userId !== req.userId && req.userRole !== 'admin') {
      return res.status(403).json({
        success: false,
        message: 'Access denied'
      });
    }
    
    const updates = req.body;
    delete updates.id;
    delete updates.userId;
    delete updates.rating;
    delete updates.totalReviews;
    delete updates.totalBookings;
    
    // Only admin can update verification status
    if (updates.verificationStatus && req.userRole !== 'admin') {
      delete updates.verificationStatus;
    }
    
    const providers = readData('providers');
    const providerIndex = providers.findIndex(p => p.id === id);
    
    providers[providerIndex] = {
      ...providers[providerIndex],
      ...updates,
      updatedAt: new Date().toISOString()
    };
    
    writeData('providers', providers);
    
    res.json({
      success: true,
      message: 'Provider profile updated successfully',
      data: providers[providerIndex]
    });
  } catch (error) {
    console.error('Update provider error:', error);
    res.status(500).json({
      success: false,
      message: 'Error updating provider profile'
    });
  }
});

// Update availability
router.put('/:id/availability', verifyToken, updateAvailabilityValidator, (req, res) => {
  try {
    const { id } = req.params;
    const { availability } = req.body;
    
    const provider = findById('providers', id);
    
    if (!provider) {
      return res.status(404).json({
        success: false,
        message: 'Provider not found'
      });
    }
    
    if (provider.userId !== req.userId && req.userRole !== 'admin') {
      return res.status(403).json({
        success: false,
        message: 'Access denied'
      });
    }
    
    const providers = readData('providers');
    const providerIndex = providers.findIndex(p => p.id === id);
    
    providers[providerIndex].availability = availability;
    providers[providerIndex].updatedAt = new Date().toISOString();
    
    writeData('providers', providers);
    
    res.json({
      success: true,
      message: 'Availability updated successfully',
      data: providers[providerIndex].availability
    });
  } catch (error) {
    console.error('Update availability error:', error);
    res.status(500).json({
      success: false,
      message: 'Error updating availability'
    });
  }
});

// Get my provider profile
router.get('/me/profile', verifyToken, (req, res) => {
  try {
    const provider = findOne('providers', 'userId', req.userId);

    if (!provider) {
      return res.status(404).json({
        success: false,
        message: 'Provider profile not found'
      });
    }

    const users = readData('users');
    const categories = readData('categories');
    const reviews = readData('reviews').filter(r => r.providerId === provider.id);
    const bookings = readData('bookings').filter(b => b.providerId === provider.id);
    const user = users.find(u => u.id === provider.userId);
    const category = categories.find(c => c.id === provider.categoryId);

    res.json({
      success: true,
      data: {
        ...provider,
        user: user ? (({ password, ...rest }) => rest)(user) : null,
        category: category || null,
        reviews,
        bookings
      }
    });
  } catch (error) {
    console.error('Get my provider error:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching provider profile'
    });
  }
});

// Delete provider profile
router.delete('/:id', verifyToken, (req, res) => {
  try {
    const { id } = req.params;
    
    const provider = findById('providers', id);
    
    if (!provider) {
      return res.status(404).json({
        success: false,
        message: 'Provider not found'
      });
    }
    
    if (provider.userId !== req.userId && req.userRole !== 'admin') {
      return res.status(403).json({
        success: false,
        message: 'Access denied'
      });
    }
    
    const providers = readData('providers').filter(p => p.id !== id);
    writeData('providers', providers);
    
    // Revert user role to customer
    const users = readData('users');
    const userIndex = users.findIndex(u => u.id === provider.userId);
    if (userIndex !== -1) {
      users[userIndex].role = 'customer';
      users[userIndex].updatedAt = new Date().toISOString();
      writeData('users', users);
    }
    
    res.json({
      success: true,
      message: 'Provider profile deleted successfully'
    });
  } catch (error) {
    console.error('Delete provider error:', error);
    res.status(500).json({
      success: false,
      message: 'Error deleting provider profile'
    });
  }
});

module.exports = router;
