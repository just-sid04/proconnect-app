/**
 * ProConnect Admin Dashboard JavaScript
 */

// Default avatar placeholder (inline SVG) to avoid external image loading failures
const DEFAULT_AVATAR = 'data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iNDAiIGhlaWdodD0iNDAiIHZpZXdCb3g9IjAgMCA0MCA0MCIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj4KICA8cmVjdCB3aWR0aD0iNDAiIGhlaWdodD0iNDAiIGZpbGw9IiNkZGQiIC8+CiAgPHRleHQgeD0iMjAiIHk9IjIzIiBmb250LXNpemU9IjE4IiB0ZXh0LWFuY2hvcj0ibWlkZGxlIiBmaWxsPSIjOTk5Ij8/PC90ZXh0Pgo8L3N2Zz4K';

// Initialize dashboard
document.addEventListener('DOMContentLoaded', function() {
    // Check authentication
    if (!checkAuth()) return;
    
    // Initialize sidebar navigation
    initSidebar();
    
    // Initialize menu toggle
    initMenuToggle();
    
    // Load dashboard data
    loadDashboardStats();
    
    // Load initial page data
    loadUsers();
    loadProviders();
    loadBookings();
    loadCategories();
    loadReviews();
});

// Sidebar Navigation
function initSidebar() {
    const navLinks = document.querySelectorAll('.sidebar-nav a');
    const pages = document.querySelectorAll('.page');
    
    navLinks.forEach(link => {
        link.addEventListener('click', (e) => {
            e.preventDefault();
            
            const pageId = link.getAttribute('data-page');
            if (!pageId) return;
            
            // Update active nav
            navLinks.forEach(l => l.parentElement.classList.remove('active'));
            link.parentElement.classList.add('active');
            
            // Show page
            pages.forEach(page => page.classList.remove('active'));
            document.getElementById(`${pageId}-page`).classList.add('active');
        });
    });
}

// Menu Toggle (Mobile)
function initMenuToggle() {
    const menuToggle = document.getElementById('menuToggle');
    const sidebar = document.querySelector('.sidebar');
    
    menuToggle?.addEventListener('click', () => {
        sidebar.classList.toggle('active');
    });
}

// Logout
document.getElementById('logoutBtn')?.addEventListener('click', (e) => {
    e.preventDefault();
    logout();
});

// Load Dashboard Stats
async function loadDashboardStats() {
    try {
        const response = await adminApi.getDashboardStats();
        
        if (response.success) {
            const stats = response.data.stats;
            
            document.getElementById('totalUsers').textContent = stats.users.total;
            document.getElementById('totalProviders').textContent = stats.providers.total;
            document.getElementById('totalBookings').textContent = stats.bookings.total;
            document.getElementById('totalRevenue').textContent = `$${stats.revenue.total.toFixed(2)}`;
            
            // Load recent bookings
            renderRecentBookings(response.data.recent.bookings);
        }
    } catch (error) {
        showToast('Error loading dashboard stats', 'error');
    }
}

// Render Recent Bookings
function renderRecentBookings(bookings) {
    const tbody = document.getElementById('recentBookingsTable');
    if (!tbody) return;
    
    if (bookings.length === 0) {
        tbody.innerHTML = '<tr><td colspan="4" class="empty-cell">No recent bookings</td></tr>';
        return;
    }
    
    tbody.innerHTML = bookings.map(booking => `
        <tr>
            <td>${booking.customer?.name || 'Unknown'}</td>
            <td>${booking.provider?.user?.name || 'Unknown'}</td>
            <td><span class="status-badge ${booking.status}">${booking.status}</span></td>
            <td>$${booking.price?.totalAmount?.toFixed(2) || '0.00'}</td>
        </tr>
    `).join('');
}

// Load Users
async function loadUsers() {
    try {
        const response = await adminApi.getUsers();
        
        if (response.success) {
            renderUsers(response.data);
        }
    } catch (error) {
        showToast('Error loading users', 'error');
    }
}

// Render Users Table
function renderUsers(users) {
    const tbody = document.getElementById('usersTable');
    if (!tbody) return;
    
    if (users.length === 0) {
        tbody.innerHTML = '<tr><td colspan="6" class="empty-cell">No users found</td></tr>';
        return;
    }
    
    tbody.innerHTML = users.map(user => `
        <tr>
            <td>
                <div class="user-cell">
                    <img src="${user.profilePhoto || DEFAULT_AVATAR}" alt="${user.name}">
                    <span>${user.name}</span>
                </div>
            </td>
            <td>${user.email}</td>
            <td><span class="role-badge ${user.role}">${user.role}</span></td>
            <td><span class="status-badge ${user.isActive ? 'active' : 'inactive'}">${user.isActive ? 'Active' : 'Inactive'}</span></td>
            <td>${new Date(user.createdAt).toLocaleDateString()}</td>
            <td>
                <button class="btn btn-sm btn-secondary" onclick="viewUser('${user.id}')">
                    <i class="fas fa-eye"></i>
                </button>
                <button class="btn btn-sm btn-danger" onclick="banUser('${user.id}')">
                    <i class="fas fa-ban"></i>
                </button>
            </td>
        </tr>
    `).join('');
}

// Load Providers
async function loadProviders() {
    try {
        const response = await adminApi.getProviders();
        
        if (response.success) {
            renderProviders(response.data);
        }
        
        // Load pending verifications
        const pendingResponse = await adminApi.getPendingVerifications();
        if (pendingResponse.success) {
            renderPendingVerifications(pendingResponse.data);
        }
    } catch (error) {
        console.error('Load providers error:', error);
        showToast(error.message ? `Error: ${error.message}` : 'Error loading providers', 'error');
    }
}

// Render Providers Table
function renderProviders(providers) {
    const tbody = document.getElementById('providersTable');
    if (!tbody) return;
    
    if (providers.length === 0) {
        tbody.innerHTML = '<tr><td colspan="5" class="empty-cell">No providers found</td></tr>';
        return;
    }
    
    tbody.innerHTML = providers.map(provider => `
        <tr>
            <td>
                <div class="user-cell">
                    <img src="${provider.user?.profilePhoto || DEFAULT_AVATAR}" alt="${provider.user?.name}">
                    <span>${provider.user?.name || 'Unknown'}</span>
                </div>
            </td>
            <td>${provider.category?.name || 'N/A'}</td>
            <td>
                <div class="rating">
                    <i class="fas fa-star"></i>
                    <span>${provider.rating} (${provider.totalReviews})</span>
                </div>
            </td>
            <td>
                <span class="status-badge ${provider.verificationStatus}">
                    ${provider.verificationStatus}
                </span>
            </td>
            <td>
                <button class="btn btn-sm btn-secondary" onclick="viewProvider('${provider.id}')">
                    <i class="fas fa-eye"></i>
                </button>
                ${provider.verificationStatus === 'pending' ? `
                    <button class="btn btn-sm btn-success" onclick="verifyProvider('${provider.id}', 'approved')">
                        <i class="fas fa-check"></i>
                    </button>
                    <button class="btn btn-sm btn-danger" onclick="verifyProvider('${provider.id}', 'rejected')">
                        <i class="fas fa-times"></i>
                    </button>
                ` : ''}
            </td>
        </tr>
    `).join('');
}

// Render Pending Verifications
function renderPendingVerifications(providers) {
    const container = document.getElementById('pendingVerificationsList');
    if (!container) return;
    
    if (providers.length === 0) {
        container.innerHTML = '<div class="empty-state"><p>No pending verifications</p></div>';
        return;
    }
    
    container.innerHTML = providers.map(provider => `
        <div class="verification-item">
            <div class="verification-info">
                <img src="${provider.user?.profilePhoto || 'https://via.placeholder.com/40'}" alt="${provider.user?.name}">
                <div>
                    <h4>${provider.user?.name || 'Unknown'}</h4>
                    <p>${provider.category?.name || 'Service Provider'}</p>
                </div>
            </div>
            <div class="verification-actions">
                <button class="btn btn-sm btn-success" onclick="verifyProvider('${provider.id}', 'approved')">
                    <i class="fas fa-check"></i> Approve
                </button>
                <button class="btn btn-sm btn-danger" onclick="verifyProvider('${provider.id}', 'rejected')">
                    <i class="fas fa-times"></i> Reject
                </button>
            </div>
        </div>
    `).join('');
}

// Verify Provider
async function verifyProvider(providerId, status) {
    try {
        const response = await adminApi.verifyProvider(providerId, status);
        
        if (response.success) {
            showToast(`Provider ${status} successfully`, 'success');
            loadProviders();
        }
    } catch (error) {
        showToast('Error verifying provider', 'error');
    }
}

// Load Bookings
async function loadBookings() {
    try {
        const response = await adminApi.getBookings();
        
        if (response.success) {
            renderBookings(response.data);
        }
    } catch (error) {
        showToast('Error loading bookings', 'error');
    }
}

// Render Bookings Table
function renderBookings(bookings) {
    const tbody = document.getElementById('bookingsTable');
    if (!tbody) return;
    
    if (bookings.length === 0) {
        tbody.innerHTML = '<tr><td colspan="7" class="empty-cell">No bookings found</td></tr>';
        return;
    }
    
    tbody.innerHTML = bookings.map(booking => `
        <tr>
            <td>#${booking.id.slice(-6)}</td>
            <td>${booking.customer?.name || 'Unknown'}</td>
            <td>${booking.provider?.user?.name || 'Unknown'}</td>
            <td>${booking.scheduledDate}</td>
            <td><span class="status-badge ${booking.status}">${booking.status}</span></td>
            <td>$${booking.price?.totalAmount?.toFixed(2) || '0.00'}</td>
            <td>
                <button class="btn btn-sm btn-secondary" onclick="viewBooking('${booking.id}')">
                    <i class="fas fa-eye"></i>
                </button>
            </td>
        </tr>
    `).join('');
}

// Load Categories
async function loadCategories() {
    try {
        const response = await adminApi.getCategories();
        
        if (response.success) {
            renderCategories(response.data);
        }
    } catch (error) {
        showToast('Error loading categories', 'error');
    }
}

// Render Categories Grid
function renderCategories(categories) {
    const grid = document.getElementById('categoriesGrid');
    if (!grid) return;
    
    if (categories.length === 0) {
        grid.innerHTML = '<div class="empty-state"><p>No categories found</p></div>';
        return;
    }
    
    grid.innerHTML = categories.map(category => `
        <div class="category-card">
            <div class="category-icon" style="background: ${category.color}20; color: ${category.color}">
                <i class="fas fa-${getCategoryIcon(category.icon)}"></i>
            </div>
            <h4>${category.name}</h4>
            <p>${category.description || 'No description'}</p>
            <div class="category-stats">
                <span><i class="fas fa-user-tie"></i> ${category.totalProviders} providers</span>
                <span><i class="fas fa-dollar-sign"></i> $${category.averageRate}/hr avg</span>
            </div>
            <div class="category-actions">
                <button class="btn btn-sm btn-secondary" onclick="editCategory('${category.id}')">
                    <i class="fas fa-edit"></i> Edit
                </button>
                <button class="btn btn-sm btn-danger" onclick="deleteCategory('${category.id}')">
                    <i class="fas fa-trash"></i>
                </button>
            </div>
        </div>
    `).join('');
}

// Get Category Icon
function getCategoryIcon(icon) {
    const icons = {
        'electrical': 'bolt',
        'plumbing': 'faucet',
        'appliance': 'tv',
        'computer': 'laptop',
        'maintenance': 'tools',
        'tutoring': 'graduation-cap',
        'beauty': 'spa',
        'automotive': 'car',
        'default': 'handshake'
    };
    return icons[icon] || icons['default'];
}

// Load Reviews
async function loadReviews() {
    try {
        const response = await adminApi.getReviews();
        
        if (response.success) {
            renderReviews(response.data);
        }
    } catch (error) {
        showToast('Error loading reviews', 'error');
    }
}

// Render Reviews Table
function renderReviews(reviews) {
    const tbody = document.getElementById('reviewsTable');
    if (!tbody) return;
    
    if (reviews.length === 0) {
        tbody.innerHTML = '<tr><td colspan="6" class="empty-cell">No reviews found</td></tr>';
        return;
    }
    
    tbody.innerHTML = reviews.map(review => `
        <tr>
            <td>${review.customer?.name || 'Unknown'}</td>
            <td>${review.provider?.user?.name || 'Unknown'}</td>
            <td>
                <div class="rating">
                    ${Array(5).fill(0).map((_, i) => `
                        <i class="fas fa-star${i < review.rating ? '' : '-o'}"></i>
                    `).join('')}
                </div>
            </td>
            <td>${review.comment || 'No comment'}</td>
            <td>${new Date(review.createdAt).toLocaleDateString()}</td>
            <td>
                <button class="btn btn-sm btn-danger" onclick="deleteReview('${review.id}')">
                    <i class="fas fa-trash"></i>
                </button>
            </td>
        </tr>
    `).join('');
}

// Modal Functions
function showModal(title, content) {
    document.getElementById('modalTitle').textContent = title;
    document.getElementById('modalBody').innerHTML = content;
    document.getElementById('modalOverlay').classList.add('active');
}

function closeModal() {
    document.getElementById('modalOverlay').classList.remove('active');
}

// Toast Notifications
function showToast(message, type = 'info') {
    const container = document.getElementById('toastContainer');
    const toast = document.createElement('div');
    toast.className = `toast ${type}`;
    
    const icon = type === 'success' ? 'check-circle' : 
                 type === 'error' ? 'exclamation-circle' : 'info-circle';
    
    toast.innerHTML = `
        <i class="fas fa-${icon}"></i>
        <span>${message}</span>
    `;
    
    container.appendChild(toast);
    
    setTimeout(() => {
        toast.remove();
    }, 3000);
}

// Close modal on overlay click
document.getElementById('modalOverlay')?.addEventListener('click', (e) => {
    if (e.target.id === 'modalOverlay') {
        closeModal();
    }
});

// Filter handlers
document.getElementById('userSearch')?.addEventListener('input', debounce(function() {
    loadUsers({ search: this.value });
}, 300));

document.getElementById('userRoleFilter')?.addEventListener('change', function() {
    loadUsers({ role: this.value });
});

document.getElementById('bookingStatusFilter')?.addEventListener('change', function() {
    loadBookings({ status: this.value });
});

// Debounce utility
function debounce(func, wait) {
    let timeout;
    return function executedFunction(...args) {
        const later = () => {
            clearTimeout(timeout);
            func(...args);
        };
        clearTimeout(timeout);
        timeout = setTimeout(later, wait);
    };
}

// Tab handlers
document.querySelectorAll('.tab-btn').forEach(btn => {
    btn.addEventListener('click', () => {
        document.querySelectorAll('.tab-btn').forEach(b => b.classList.remove('active'));
        btn.classList.add('active');
        
        const tab = btn.getAttribute('data-tab');
        // Reload providers with filter
        if (tab === 'pending') {
            loadProviders({ verificationStatus: 'pending' });
        } else if (tab === 'verified') {
            loadProviders({ verified: true });
        } else {
            loadProviders();
        }
    });
});
