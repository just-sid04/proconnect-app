/**
 * ProConnect Admin Dashboard API Client
 */

const API_BASE_URL = 'http://localhost:3000/api';

// API Client
const api = {
    // Auth token storage
    token: localStorage.getItem('adminToken'),
    
    // Set auth token
    setToken(token) {
        this.token = token;
        localStorage.setItem('adminToken', token);
    },
    
    // Clear auth token
    clearToken() {
        this.token = null;
        localStorage.removeItem('adminToken');
    },
    
    // Get headers
    getHeaders() {
        const headers = {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
        };
        if (this.token) {
            headers['Authorization'] = `Bearer ${this.token}`;
        }
        return headers;
    },
    
    // GET request
    async get(endpoint) {
        const response = await fetch(`${API_BASE_URL}${endpoint}`, {
            method: 'GET',
            headers: this.getHeaders(),
        });
        return this.handleResponse(response);
    },
    
    // POST request
    async post(endpoint, data) {
        const response = await fetch(`${API_BASE_URL}${endpoint}`, {
            method: 'POST',
            headers: this.getHeaders(),
            body: JSON.stringify(data),
        });
        return this.handleResponse(response);
    },
    
    // PUT request
    async put(endpoint, data) {
        const response = await fetch(`${API_BASE_URL}${endpoint}`, {
            method: 'PUT',
            headers: this.getHeaders(),
            body: JSON.stringify(data),
        });
        return this.handleResponse(response);
    },
    
    // DELETE request
    async delete(endpoint) {
        const response = await fetch(`${API_BASE_URL}${endpoint}`, {
            method: 'DELETE',
            headers: this.getHeaders(),
        });
        return this.handleResponse(response);
    },
    
    // Handle response
    async handleResponse(response) {
        const data = await response.json();
        if (!response.ok) {
            // If 401 Unauthorized, clear token and redirect to login
            if (response.status === 401) {
                this.clearToken();
                window.location.href = 'login.html';
                throw new Error('Session expired. Please login again.');
            }
            throw new Error(data.message || 'Something went wrong');
        }
        return data;
    },
};

// Admin API Endpoints
const adminApi = {
    // Dashboard
    getDashboardStats() {
        return api.get('/admin/dashboard');
    },
    
    // Users
    getUsers(params = {}) {
        const queryString = new URLSearchParams(params).toString();
        return api.get(`/admin/users?${queryString}`);
    },
    
    banUser(userId, reason) {
        return api.put(`/admin/users/${userId}/ban`, { reason });
    },
    
    unbanUser(userId) {
        return api.put(`/admin/users/${userId}/unban`);
    },
    
    deleteUser(userId) {
        return api.delete(`/users/${userId}`);
    },
    
    // Providers
    getProviders(params = {}) {
        const queryString = new URLSearchParams(params).toString();
        return api.get(`/providers?${queryString}`);
    },
    
    getPendingVerifications() {
        return api.get('/admin/verifications/pending');
    },
    
    verifyProvider(providerId, status, notes = '') {
        return api.put(`/admin/providers/${providerId}/verify`, { status, notes });
    },
    
    // Bookings
    getBookings(params = {}) {
        const queryString = new URLSearchParams(params).toString();
        return api.get(`/admin/bookings?${queryString}`);
    },
    
    // Categories
    getCategories() {
        return api.get('/categories');
    },
    
    createCategory(data) {
        return api.post('/categories', data);
    },
    
    updateCategory(categoryId, data) {
        return api.put(`/categories/${categoryId}`, data);
    },
    
    deleteCategory(categoryId) {
        return api.delete(`/categories/${categoryId}`);
    },
    
    // Reviews
    getReviews(params = {}) {
        const queryString = new URLSearchParams(params).toString();
        return api.get(`/admin/reviews?${queryString}`);
    },
    
    deleteReview(reviewId) {
        return api.delete(`/reviews/${reviewId}`);
    },
};

// Check if admin is logged in
function checkAuth() {
    const token = localStorage.getItem('adminToken');
    // If there is no token or it doesn't look like a JWT, require login.
    if (!token || token.split('.').length !== 3) {
        localStorage.removeItem('adminToken');
        localStorage.removeItem('adminUser');
        window.location.href = 'login.html';
        return false;
    }

    api.setToken(token);
    return true;
}

// Login function
async function login(email, password) {
    const response = await fetch(`${API_BASE_URL}/auth/login`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({ email, password }),
    });
    
    const data = await response.json();
    
    if (data.success && data.data.user.role === 'admin') {
        api.setToken(data.data.token);
        return { success: true };
    }
    
    return { success: false, message: data.message || 'Invalid credentials' };
}

// Logout function
function logout() {
    api.clearToken();
    window.location.href = 'login.html';
}
