/**
 * Database Utility Module
 * Handles JSON file operations for data persistence
 */

const fs = require('fs');
const path = require('path');

const DATA_DIR = path.join(__dirname, '..', 'data');

// Ensure data directory exists
if (!fs.existsSync(DATA_DIR)) {
  fs.mkdirSync(DATA_DIR, { recursive: true });
}

// Database file paths
const DB_FILES = {
  users: path.join(DATA_DIR, 'users.json'),
  providers: path.join(DATA_DIR, 'providers.json'),
  bookings: path.join(DATA_DIR, 'bookings.json'),
  reviews: path.join(DATA_DIR, 'reviews.json'),
  categories: path.join(DATA_DIR, 'categories.json')
};

// Initialize database files if they don't exist
const initializeDatabase = () => {
  Object.entries(DB_FILES).forEach(([key, filePath]) => {
    if (!fs.existsSync(filePath)) {
      const initialData = key === 'categories' ? { [key]: [] } : { [key]: [] };
      fs.writeFileSync(filePath, JSON.stringify(initialData, null, 2));
      console.log(`✓ Created ${key}.json`);
    }
  });
};

// Read data from JSON file
const readData = (collection) => {
  try {
    const filePath = DB_FILES[collection];
    if (!filePath) {
      throw new Error(`Unknown collection: ${collection}`);
    }
    
    const data = fs.readFileSync(filePath, 'utf8');
    const parsed = JSON.parse(data);
    return parsed[collection] || [];
  } catch (error) {
    console.error(`Error reading ${collection}:`, error.message);
    return [];
  }
};

// Write data to JSON file
const writeData = (collection, data) => {
  try {
    const filePath = DB_FILES[collection];
    if (!filePath) {
      throw new Error(`Unknown collection: ${collection}`);
    }
    
    const dataToWrite = { [collection]: data };
    fs.writeFileSync(filePath, JSON.stringify(dataToWrite, null, 2));
    return true;
  } catch (error) {
    console.error(`Error writing ${collection}:`, error.message);
    return false;
  }
};

// Find one item by key-value pair
const findOne = (collection, key, value) => {
  const data = readData(collection);
  return data.find(item => item[key] === value);
};

// Find multiple items by key-value pair
const findMany = (collection, key, value) => {
  const data = readData(collection);
  return data.filter(item => item[key] === value);
};

// Find by ID
const findById = (collection, id) => {
  return findOne(collection, 'id', id);
};

// Insert new item
const insert = (collection, item) => {
  const data = readData(collection);
  data.push(item);
  return writeData(collection, data);
};

// Update item by ID
const updateById = (collection, id, updates) => {
  const data = readData(collection);
  const index = data.findIndex(item => item.id === id);
  
  if (index === -1) {
    return false;
  }
  
  data[index] = { ...data[index], ...updates, updatedAt: new Date().toISOString() };
  return writeData(collection, data);
};

// Delete item by ID
const deleteById = (collection, id) => {
  const data = readData(collection);
  const filtered = data.filter(item => item.id !== id);
  
  if (filtered.length === data.length) {
    return false;
  }
  
  return writeData(collection, filtered);
};

// Query with filters
const query = (collection, filters = {}) => {
  let data = readData(collection);
  
  Object.entries(filters).forEach(([key, value]) => {
    if (value !== undefined && value !== null && value !== '') {
      data = data.filter(item => {
        if (typeof item[key] === 'string' && typeof value === 'string') {
          return item[key].toLowerCase().includes(value.toLowerCase());
        }
        return item[key] === value;
      });
    }
  });
  
  return data;
};

// Generate unique ID
const generateId = (prefix) => {
  const timestamp = Date.now().toString(36);
  const random = Math.random().toString(36).substr(2, 5);
  return `${prefix}-${timestamp}-${random}`;
};

// Get statistics
const getStats = () => {
  const stats = {};
  
  Object.keys(DB_FILES).forEach(collection => {
    const data = readData(collection);
    stats[collection] = {
      count: data.length,
      lastUpdated: fs.existsSync(DB_FILES[collection]) 
        ? fs.statSync(DB_FILES[collection]).mtime 
        : null
    };
  });
  
  return stats;
};

module.exports = {
  initializeDatabase,
  readData,
  writeData,
  findOne,
  findMany,
  findById,
  insert,
  updateById,
  deleteById,
  query,
  generateId,
  getStats,
  DB_FILES
};
