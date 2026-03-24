/**
 * Category Routes
 * Handles service categories
 */

const express = require('express');
const router = express.Router();

const { readData, writeData, findById, generateId } = require('../utils/database');
const { verifyToken, isAdmin } = require('../middleware/auth');

// Get all categories
router.get('/', (req, res) => {
  try {
    const categories = readData('categories');
    
    // Filter active categories only (for public)
    const activeCategories = categories.filter(c => c.isActive !== false);
    
    res.json({
      success: true,
      count: activeCategories.length,
      data: activeCategories
    });
  } catch (error) {
    console.error('Get categories error:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching categories'
    });
  }
});

// Get category by ID
router.get('/:id', (req, res) => {
  try {
    const { id } = req.params;
    
    const category = findById('categories', id);
    
    if (!category) {
      return res.status(404).json({
        success: false,
        message: 'Category not found'
      });
    }
    
    // Get providers count for this category
    const providers = readData('providers').filter(p => p.categoryId === id);
    
    res.json({
      success: true,
      data: {
        ...category,
        providerCount: providers.length
      }
    });
  } catch (error) {
    console.error('Get category error:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching category'
    });
  }
});

// Get providers by category
router.get('/:id/providers', (req, res) => {
  try {
    const { id } = req.params;
    const { page = 1, limit = 10, verified } = req.query;
    
    const category = findById('categories', id);
    
    if (!category) {
      return res.status(404).json({
        success: false,
        message: 'Category not found'
      });
    }
    
    let providers = readData('providers').filter(p => p.categoryId === id);
    const users = readData('users');
    
    // Filter verified providers
    if (verified === 'true') {
      providers = providers.filter(p => p.isVerified);
    }
    
    // Sort by rating
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
    console.error('Get category providers error:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching category providers'
    });
  }
});

// Create category (admin only)
router.post('/', verifyToken, isAdmin, (req, res) => {
  try {
    const { name, description, icon, color, services } = req.body;
    
    if (!name) {
      return res.status(400).json({
        success: false,
        message: 'Category name is required'
      });
    }
    
    // Check if category exists
    const categories = readData('categories');
    const existingCategory = categories.find(c => c.name.toLowerCase() === name.toLowerCase());
    
    if (existingCategory) {
      return res.status(409).json({
        success: false,
        message: 'Category with this name already exists'
      });
    }
    
    const newCategory = {
      id: generateId('cat'),
      name,
      description: description || '',
      icon: icon || 'default',
      color: color || '#2196F3',
      services: services || [],
      averageRate: 0,
      totalProviders: 0,
      isActive: true,
      createdAt: new Date().toISOString()
    };
    
    categories.push(newCategory);
    writeData('categories', categories);
    
    res.status(201).json({
      success: true,
      message: 'Category created successfully',
      data: newCategory
    });
  } catch (error) {
    console.error('Create category error:', error);
    res.status(500).json({
      success: false,
      message: 'Error creating category'
    });
  }
});

// Update category (admin only)
router.put('/:id', verifyToken, isAdmin, (req, res) => {
  try {
    const { id } = req.params;
    const updates = req.body;
    
    const category = findById('categories', id);
    
    if (!category) {
      return res.status(404).json({
        success: false,
        message: 'Category not found'
      });
    }
    
    const categories = readData('categories');
    const categoryIndex = categories.findIndex(c => c.id === id);
    
    // Don't allow changing id
    delete updates.id;
    
    categories[categoryIndex] = {
      ...categories[categoryIndex],
      ...updates
    };
    
    writeData('categories', categories);
    
    res.json({
      success: true,
      message: 'Category updated successfully',
      data: categories[categoryIndex]
    });
  } catch (error) {
    console.error('Update category error:', error);
    res.status(500).json({
      success: false,
      message: 'Error updating category'
    });
  }
});

// Delete category (admin only)
router.delete('/:id', verifyToken, isAdmin, (req, res) => {
  try {
    const { id } = req.params;
    
    const category = findById('categories', id);
    
    if (!category) {
      return res.status(404).json({
        success: false,
        message: 'Category not found'
      });
    }
    
    // Check if providers are using this category
    const providers = readData('providers').filter(p => p.categoryId === id);
    
    if (providers.length > 0) {
      // Soft delete - mark as inactive
      const categories = readData('categories');
      const categoryIndex = categories.findIndex(c => c.id === id);
      categories[categoryIndex].isActive = false;
      writeData('categories', categories);
      
      return res.json({
        success: true,
        message: 'Category deactivated (has associated providers)'
      });
    }
    
    // Hard delete
    const categories = readData('categories').filter(c => c.id !== id);
    writeData('categories', categories);
    
    res.json({
      success: true,
      message: 'Category deleted successfully'
    });
  } catch (error) {
    console.error('Delete category error:', error);
    res.status(500).json({
      success: false,
      message: 'Error deleting category'
    });
  }
});

// Get category statistics
router.get('/stats/overview', verifyToken, isAdmin, (req, res) => {
  try {
    const categories = readData('categories');
    const providers = readData('providers');
    
    const stats = categories.map(cat => {
      const categoryProviders = providers.filter(p => p.categoryId === cat.id);
      const verifiedProviders = categoryProviders.filter(p => p.isVerified);
      
      return {
        id: cat.id,
        name: cat.name,
        totalProviders: categoryProviders.length,
        verifiedProviders: verifiedProviders.length,
        averageRating: categoryProviders.length > 0
          ? Math.round((categoryProviders.reduce((sum, p) => sum + p.rating, 0) / categoryProviders.length) * 10) / 10
          : 0
      };
    });
    
    res.json({
      success: true,
      data: stats
    });
  } catch (error) {
    console.error('Get category stats error:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching category statistics'
    });
  }
});

module.exports = router;
