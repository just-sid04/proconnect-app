/**
 * ProConnect Admin Dashboard — UI Logic
 * Fully connected to Supabase. No hardcoded/dummy data.
 */

// ─── GLOBALS ──────────────────────────────────────────────────────────────────
let currentAdmin = null;
let allNotifications = [];
let notificationDropdownOpen = false;
let profileDropdownOpen = false;
let currentProviderTab = 'all';
let currentCategoryList = [];

// ─── HELPERS ──────────────────────────────────────────────────────────────────
const AVATAR_COLORS = ['#2196F3','#4CAF50','#FF9800','#E91E63','#9C27B0','#00BCD4','#FF5722','#607D8B'];

function getInitialsAvatar(name, size = 36) {
    const safeName = (name || '?').trim();
    const parts = safeName.split(' ').filter(Boolean);
    const initials = parts.length >= 2
        ? (parts[0][0] + parts[parts.length - 1][0]).toUpperCase()
        : safeName.substring(0, 2).toUpperCase();
    const color = AVATAR_COLORS[safeName.charCodeAt(0) % AVATAR_COLORS.length];
    const fs = Math.round(size * 0.38);
    return `<div class="initials-avatar" style="width:${size}px;height:${size}px;background:${color};font-size:${fs}px;">${initials}</div>`;
}

function formatDate(iso) {
    if (!iso) return '—';
    return new Date(iso).toLocaleDateString('en-IN', { day:'2-digit', month:'short', year:'numeric' });
}

function formatTime(iso) {
    if (!iso) return '';
    const d = new Date(iso);
    const diff = Math.round((Date.now() - d) / 60000);
    if (diff < 1) return 'just now';
    if (diff < 60) return `${diff}m ago`;
    if (diff < 1440) return `${Math.round(diff/60)}h ago`;
    return formatDate(iso);
}

function debounce(fn, ms) {
    let t;
    return function(...args) {
        clearTimeout(t);
        t = setTimeout(() => fn.apply(this, args), ms);
    };
}

// Toast
function showToast(message, type = 'info') {
    const container = document.getElementById('toastContainer');
    const toast = document.createElement('div');
    toast.className = `toast ${type}`;
    const icon = type === 'success' ? 'check-circle' : type === 'error' ? 'exclamation-circle' : 'info-circle';
    toast.innerHTML = `<i class="fas fa-${icon}"></i><span>${message}</span>`;
    container.appendChild(toast);
    setTimeout(() => toast.remove(), 3500);
}

// Modal
function showModal(title, content, size = '') {
    document.getElementById('modalTitle').textContent = title;
    document.getElementById('modalBody').innerHTML = content;
    const modal = document.querySelector('.modal');
    modal.className = 'modal' + (size ? ' modal-' + size : '');
    document.getElementById('modalOverlay').classList.add('active');
}
function closeModal() {
    document.getElementById('modalOverlay').classList.remove('active');
}
document.addEventListener('DOMContentLoaded', () => {
    document.getElementById('modalOverlay')?.addEventListener('click', e => {
        if (e.target.id === 'modalOverlay') closeModal();
    });
});

// Confirm dialog built on modal
function showConfirm(title, message, onConfirm) {
    showModal(title, `
        <p style="color:#475569;margin-bottom:24px;">${message}</p>
        <div style="display:flex;gap:12px;justify-content:flex-end;">
            <button class="btn btn-secondary" onclick="closeModal()">Cancel</button>
            <button class="btn btn-danger" id="confirmYesBtn">Confirm</button>
        </div>
    `);
    document.getElementById('confirmYesBtn').onclick = () => { closeModal(); onConfirm(); };
}

// ─── INIT ─────────────────────────────────────────────────────────────────────
document.addEventListener('DOMContentLoaded', async () => {
    currentAdmin = await checkAuth();
    if (!currentAdmin) return;

    initAdminProfile();
    initSidebar();
    initMenuToggle();
    initDropdownCloser();
    initNotificationBell();
    initRealtimeSubscriptions();

    loadDashboard();
    loadUsersPage();
    loadProvidersPage();
    loadBookingsPage();
    loadCategoriesPage();
    loadReviewsPage();
    loadSettingsPage();
    loadEarningsPage();

    // Filter event listeners
    document.getElementById('userSearch')?.addEventListener('input', debounce(function() {
        loadUsersPage({ search: this.value, role: document.getElementById('userRoleFilter').value });
    }, 350));
    document.getElementById('userRoleFilter')?.addEventListener('change', function() {
        loadUsersPage({ search: document.getElementById('userSearch').value, role: this.value });
    });
    document.getElementById('bookingStatusFilter')?.addEventListener('change', function() {
        loadBookingsPage({ status: this.value });
    });

    // Provider tabs
    document.querySelectorAll('.tab-btn').forEach(btn => {
        btn.addEventListener('click', () => {
            document.querySelectorAll('.tab-btn').forEach(b => b.classList.remove('active'));
            btn.classList.add('active');
            currentProviderTab = btn.getAttribute('data-tab');
            loadProvidersPage({ status: currentProviderTab === 'all' ? '' : currentProviderTab });
        });
    });
});

// ─── ADMIN PROFILE IN HEADER ──────────────────────────────────────────────────
function initAdminProfile() {
    const nameSpan = document.getElementById('adminName');
    const avatarDiv = document.getElementById('adminAvatar');
    if (nameSpan) nameSpan.textContent = currentAdmin.name || 'Admin';
    if (avatarDiv) avatarDiv.innerHTML = getInitialsAvatar(currentAdmin.name, 36);
}

// ─── SIDEBAR NAVIGATION ───────────────────────────────────────────────────────
function initSidebar() {
    const navLinks = document.querySelectorAll('.sidebar-nav a');
    const pages = document.querySelectorAll('.page');
    navLinks.forEach(link => {
        link.addEventListener('click', e => {
            e.preventDefault();
            const pageId = link.getAttribute('data-page');
            if (!pageId) return;
            navLinks.forEach(l => l.parentElement.classList.remove('active'));
            link.parentElement.classList.add('active');
            pages.forEach(p => p.classList.remove('active'));
            document.getElementById(`${pageId}-page`)?.classList.add('active');
            closeAllDropdowns();
        });
    });
    document.getElementById('logoutBtn')?.addEventListener('click', e => {
        e.preventDefault();
        showConfirm('Logout', 'Are you sure you want to logout?', logoutUser);
    });
}

function initMenuToggle() {
    document.getElementById('menuToggle')?.addEventListener('click', () => {
        document.querySelector('.sidebar').classList.toggle('open');
    });
}

// ─── DROPDOWN CLOSE ON OUTSIDE CLICK ─────────────────────────────────────────
function closeAllDropdowns() {
    document.getElementById('notificationDropdown')?.classList.remove('active');
    document.getElementById('profileDropdown')?.classList.remove('active');
    notificationDropdownOpen = false;
    profileDropdownOpen = false;
}
function initDropdownCloser() {
    document.addEventListener('click', e => {
        if (!e.target.closest('.notification-wrapper') && !e.target.closest('.user-profile-wrapper')) {
            closeAllDropdowns();
        }
    });
}

// ─── NOTIFICATION BELL ────────────────────────────────────────────────────────
function initNotificationBell() {
    const btn = document.getElementById('notificationBtn');
    btn?.addEventListener('click', e => {
        e.stopPropagation();
        notificationDropdownOpen = !notificationDropdownOpen;
        document.getElementById('notificationDropdown').classList.toggle('active', notificationDropdownOpen);
        profileDropdownOpen = false;
        document.getElementById('profileDropdown')?.classList.remove('active');
        if (notificationDropdownOpen) refreshNotifications();
    });
}

async function refreshNotifications() {
    try {
        allNotifications = await getNotifications();
        const badge = document.getElementById('notifBadge');
        if (badge) {
            badge.textContent = allNotifications.length;
            badge.style.display = allNotifications.length ? '' : 'none';
        }
        renderNotificationDropdown();
    } catch (err) {
        console.error('Notifications error:', err);
    }
}

function renderNotificationDropdown() {
    const list = document.getElementById('notificationList');
    if (!list) return;
    if (!allNotifications.length) {
        list.innerHTML = '<div class="notif-empty"><i class="fas fa-bell-slash"></i><p>No new notifications</p></div>';
        return;
    }
    list.innerHTML = allNotifications.map(n => `
        <div class="notif-item">
            <div class="notif-icon" style="background:${n.color}20;color:${n.color}">
                <i class="fas fa-${n.icon}"></i>
            </div>
            <div class="notif-content">
                <p>${n.text}</p>
                <span>${formatTime(n.time)}</span>
            </div>
        </div>
    `).join('');
}

function addNotification(text, icon, color) {
    allNotifications.unshift({ text, icon, color, time: new Date().toISOString() });
    const badge = document.getElementById('notifBadge');
    if (badge) {
        badge.textContent = allNotifications.length;
        badge.style.display = '';
    }
    if (notificationDropdownOpen) renderNotificationDropdown();
}

// ─── ADMIN PROFILE DROPDOWN ───────────────────────────────────────────────────
function initProfileDropdown() {/* handled via initDropdownCloser */ }
window.toggleProfileDropdown = function(e) {
    e.stopPropagation();
    profileDropdownOpen = !profileDropdownOpen;
    document.getElementById('profileDropdown').classList.toggle('active', profileDropdownOpen);
    notificationDropdownOpen = false;
    document.getElementById('notificationDropdown')?.classList.remove('active');
};

// ─── REALTIME ─────────────────────────────────────────────────────────────────
function initRealtimeSubscriptions() {
    supabaseClient
        .channel('admin-realtime')
        .on('postgres_changes', { event: 'INSERT', schema: 'public', table: 'service_providers' }, payload => {
            handleNewProviderRealtime(payload.new);
        })
        .on('postgres_changes', { event: 'INSERT', schema: 'public', table: 'bookings' }, payload => {
            addNotification('New booking created', 'calendar-check', '#2196F3');
            showToast('New booking received!', 'info');
            // Refresh dashboard counts if on dashboard
            if (document.querySelector('#dashboard-page.active')) loadDashboard();
        })
        .on('postgres_changes', { event: 'INSERT', schema: 'public', table: 'profiles' }, payload => {
            const role = payload.new.role;
            addNotification(`New ${role} signed up`, 'user-plus', '#4CAF50');
        })
        .subscribe();
}

async function handleNewProviderRealtime(newProvider) {
    // Fetch full provider record with joins
    const { data } = await supabaseClient
        .from('service_providers')
        .select(`
            id, verification_status, rating, total_reviews, created_at,
            profiles!user_id(name, email, profile_photo),
            categories!category_id(name, icon, color)
        `)
        .eq('id', newProvider.id)
        .single();

    if (data) {
        const name = data.profiles?.name || 'A provider';
        addNotification(`${name} registered — awaiting verification`, 'user-tie', '#FF9800');
        showToast(`New provider registered: ${name}`, 'info');

        // If currently viewing "all" or "pending" providers tab, prepend row
        const tbody = document.getElementById('providersTable');
        if (tbody && (currentProviderTab === 'all' || currentProviderTab === 'pending')) {
            const row = buildProviderRow(data);
            tbody.insertAdjacentHTML('afterbegin', row);
        }
    }
}

// ─── DASHBOARD PAGE ───────────────────────────────────────────────────────────
async function loadDashboard() {
    try {
        const [stats, recentBookings, pendingVerifs] = await Promise.all([
            getDashboardStats(),
            getRecentBookings(),
            getPendingVerifications(),
        ]);

        document.getElementById('totalUsers').textContent = stats.users;
        document.getElementById('totalProviders').textContent = stats.providers;
        document.getElementById('totalBookings').textContent = stats.bookings;
        document.getElementById('totalRevenue').textContent = `₹${Number(stats.revenue).toLocaleString('en-IN', { minimumFractionDigits: 0 })}`;

        renderRecentBookingsTable(recentBookings);
        renderPendingVerificationsList(pendingVerifs);
    } catch (err) {
        console.error(err);
        showToast('Error loading dashboard data', 'error');
    }

    // Load notifications on startup
    refreshNotifications();
}

function renderRecentBookingsTable(bookings) {
    const tbody = document.getElementById('recentBookingsTable');
    if (!tbody) return;
    if (!bookings.length) {
        tbody.innerHTML = '<tr><td colspan="4" class="empty-cell">No recent bookings</td></tr>';
        return;
    }
    tbody.innerHTML = bookings.map(b => {
        const customer = b.customer?.name || 'Unknown';
        const providerName = b.provider?.profiles?.name || b.provider?.['profiles!user_id']?.name || 'Unknown';
        const amount = b.price?.totalAmount || b.price?.total_amount || 0;
        return `
        <tr>
            <td>${customer}</td>
            <td>${providerName}</td>
            <td><span class="status-badge ${b.status}">${b.status}</span></td>
            <td>₹${Number(amount).toLocaleString('en-IN')}</td>
        </tr>`;
    }).join('');
}

function renderPendingVerificationsList(providers) {
    const container = document.getElementById('pendingVerificationsList');
    if (!container) return;
    if (!providers.length) {
        container.innerHTML = '<div class="empty-state"><i class="fas fa-check-circle"></i><p>No pending verifications</p></div>';
        return;
    }
    container.innerHTML = providers.map(p => {
        const profile = p.profiles || p['profiles!user_id'] || {};
        const name = profile.name || 'Unknown';
        const catName = p.categories?.name || p['categories!category_id']?.name || 'Service Provider';
        return `
        <div class="pending-item">
            ${getInitialsAvatar(name, 40)}
            <div class="info">
                <strong>${name}</strong>
                <p>${catName}</p>
            </div>
            <div style="display:flex;gap:6px;">
                <button class="btn btn-sm btn-success" onclick="approveProviderQuick('${p.id}')" title="Approve">
                    <i class="fas fa-check"></i>
                </button>
                <button class="btn btn-sm btn-danger" onclick="rejectProviderQuick('${p.id}')" title="Reject">
                    <i class="fas fa-times"></i>
                </button>
            </div>
        </div>`;
    }).join('');
}

window.approveProviderQuick = async function(id) {
    try {
        await updateProviderStatus(id, 'approved');
        showToast('Provider approved!', 'success');
        loadDashboard();
        loadProvidersPage();
    } catch(e) { showToast('Error: ' + e.message, 'error'); }
};
window.rejectProviderQuick = async function(id) {
    try {
        await updateProviderStatus(id, 'rejected');
        showToast('Provider rejected.', 'info');
        loadDashboard();
        loadProvidersPage();
    } catch(e) { showToast('Error: ' + e.message, 'error'); }
};

// ─── USERS PAGE ───────────────────────────────────────────────────────────────
async function loadUsersPage({ search = '', role = '' } = {}) {
    const tbody = document.getElementById('usersTable');
    if (!tbody) return;
    tbody.innerHTML = '<tr><td colspan="6" class="empty-cell"><div class="spinner" style="margin:auto;"></div></td></tr>';
    try {
        const users = await getUsers({ search, role });
        renderUsersTable(users);
    } catch (err) {
        showToast('Error loading users: ' + err.message, 'error');
        tbody.innerHTML = '<tr><td colspan="6" class="empty-cell">Error loading users</td></tr>';
    }
}

function renderUsersTable(users) {
    const tbody = document.getElementById('usersTable');
    if (!tbody) return;
    if (!users.length) {
        tbody.innerHTML = '<tr><td colspan="6" class="empty-cell">No users found</td></tr>';
        return;
    }
    tbody.innerHTML = users.map(u => `
        <tr>
            <td>
                <div class="user-cell">
                    ${getInitialsAvatar(u.name, 34)}
                    <span>${u.name || '—'}</span>
                </div>
            </td>
            <td>${u.email || '—'}</td>
            <td><span class="role-badge ${u.role}">${u.role}</span></td>
            <td><span class="status-badge ${u.is_active ? 'active' : 'inactive'}">${u.is_active ? 'Active' : 'Inactive'}</span></td>
            <td>${formatDate(u.created_at)}</td>
            <td>
                <button class="btn btn-sm btn-secondary" onclick="viewUser('${u.id}')"><i class="fas fa-eye"></i></button>
                <button class="btn btn-sm ${u.is_active ? 'btn-danger' : 'btn-success'}" onclick="toggleUserStatus('${u.id}', ${u.is_active}, '${(u.name||'').replace(/'/g,"\\'")}')">
                    <i class="fas fa-${u.is_active ? 'ban' : 'check'}"></i>
                </button>
            </td>
        </tr>
    `).join('');
}

window.viewUser = async function(id) {
    showModal('User Details', '<div style="text-align:center;padding:20px;"><div class="spinner" style="margin:auto;"></div></div>');
    try {
        const u = await getUserById(id);
        showModal('User Details', `
            <div style="text-align:center;margin-bottom:20px;">
                ${getInitialsAvatar(u.name, 64)}
                <h3 style="margin-top:12px;">${u.name}</h3>
                <span class="role-badge ${u.role}">${u.role}</span>
            </div>
            <div class="detail-grid">
                <div class="detail-item"><span>Email</span><strong>${u.email}</strong></div>
                <div class="detail-item"><span>Phone</span><strong>${u.phone || '—'}</strong></div>
                <div class="detail-item"><span>Status</span><strong>${u.is_active ? '✅ Active' : '❌ Inactive'}</strong></div>
                <div class="detail-item"><span>Verified</span><strong>${u.is_verified ? '✅ Yes' : '❌ No'}</strong></div>
                <div class="detail-item"><span>Joined</span><strong>${formatDate(u.created_at)}</strong></div>
                <div class="detail-item"><span>Location</span><strong>${u.location ? (u.location.address || `${u.location.latitude},${u.location.longitude}`) : '—'}</strong></div>
            </div>
        `);
    } catch (e) {
        showModal('User Details', `<p style="color:red;">Error: ${e.message}</p>`);
    }
};

window.toggleUserStatus = function(id, isActive, name) {
    const action = isActive ? 'deactivate' : 'activate';
    showConfirm(`${isActive ? 'Deactivate' : 'Activate'} User`,
        `Are you sure you want to ${action} <strong>${name}</strong>?`,
        async () => {
            try {
                isActive ? await deactivateUser(id) : await activateUser(id);
                showToast(`User ${action}d successfully`, 'success');
                loadUsersPage({
                    search: document.getElementById('userSearch').value,
                    role: document.getElementById('userRoleFilter').value,
                });
            } catch (e) { showToast('Error: ' + e.message, 'error'); }
        }
    );
};

window.showAddUserModal = function() {
    showModal('Add New User', `
        <form id="addUserForm">
            <div class="form-group">
                <label>Full Name</label>
                <input type="text" id="newUserName" placeholder="John Doe" required>
            </div>
            <div class="form-group">
                <label>Email</label>
                <input type="email" id="newUserEmail" placeholder="user@example.com" required>
            </div>
            <div class="form-group">
                <label>Password</label>
                <input type="password" id="newUserPassword" placeholder="Min 6 characters" minlength="6" required>
            </div>
            <div class="form-group">
                <label>Role</label>
                <select id="newUserRole">
                    <option value="customer">Customer</option>
                    <option value="provider">Provider</option>
                    <option value="admin">Admin</option>
                </select>
            </div>
            <div class="form-group">
                <label>Phone (optional)</label>
                <input type="tel" id="newUserPhone" placeholder="+91 9xxxxxxxxx">
            </div>
            <div style="display:flex;gap:12px;justify-content:flex-end;margin-top:8px;">
                <button type="button" class="btn btn-secondary" onclick="closeModal()">Cancel</button>
                <button type="submit" class="btn btn-primary">Create User</button>
            </div>
        </form>
    `);
    document.getElementById('addUserForm').onsubmit = async function(e) {
        e.preventDefault();
        const btn = this.querySelector('[type=submit]');
        btn.textContent = 'Creating...'; btn.disabled = true;
        try {
            await createUser({
                name: document.getElementById('newUserName').value,
                email: document.getElementById('newUserEmail').value,
                password: document.getElementById('newUserPassword').value,
                role: document.getElementById('newUserRole').value,
                phone: document.getElementById('newUserPhone').value,
            });
            showToast('User created successfully!', 'success');
            closeModal();
            loadUsersPage();
        } catch (e) {
            showToast('Error: ' + e.message, 'error');
            btn.textContent = 'Create User'; btn.disabled = false;
        }
    };
};

// ─── PROVIDERS PAGE ───────────────────────────────────────────────────────────
async function loadProvidersPage({ status = '' } = {}) {
    const tbody = document.getElementById('providersTable');
    if (!tbody) return;
    tbody.innerHTML = '<tr><td colspan="5" class="empty-cell"><div class="spinner" style="margin:auto;"></div></td></tr>';
    try {
        const providers = await getProviders({ status });
        renderProvidersTable(providers);
    } catch (err) {
        showToast('Error loading providers: ' + err.message, 'error');
        tbody.innerHTML = '<tr><td colspan="5" class="empty-cell">Error loading providers</td></tr>';
    }
}

function getProviderProfile(p) { return p.profiles || p['profiles!user_id'] || {}; }
function getProviderCategory(p) { return p.categories || p['categories!category_id'] || {}; }

function buildProviderRow(p) {
    const profile = getProviderProfile(p);
    const cat = getProviderCategory(p);
    const name = profile.name || 'Unknown';
    return `
    <tr>
        <td>
            <div class="user-cell">
                ${getInitialsAvatar(name, 34)}
                <span>${name}</span>
            </div>
        </td>
        <td>${cat.name || '<span style="color:#94a3b8">N/A</span>'}</td>
        <td>
            <div class="rating">
                <i class="fas fa-star" style="color:#FFC107;"></i>
                <span>${Number(p.rating || 0).toFixed(1)} (${p.total_reviews || 0})</span>
            </div>
        </td>
        <td><span class="status-badge ${p.verification_status}">${p.verification_status}</span></td>
        <td>
            <button class="btn btn-sm btn-secondary" onclick="viewProvider('${p.id}')"><i class="fas fa-eye"></i></button>
        </td>
    </tr>`;
}

function renderProvidersTable(providers) {
    const tbody = document.getElementById('providersTable');
    if (!tbody) return;
    if (!providers.length) {
        tbody.innerHTML = '<tr><td colspan="5" class="empty-cell">No providers found</td></tr>';
        return;
    }
    tbody.innerHTML = providers.map(buildProviderRow).join('');
}

window.viewProvider = async function(id) {
    showModal('Provider Details', '<div style="text-align:center;padding:20px;"><div class="spinner" style="margin:auto;"></div></div>', 'lg');
    try {
        const { data: p } = await supabaseClient
            .from('service_providers')
            .select(`*, profiles!user_id(name,email,phone,profile_photo), categories!category_id(name,icon,color)`)
            .eq('id', id).single();
        const profile = p.profiles || p['profiles!user_id'] || {};
        const cat = p.categories || p['categories!category_id'] || {};
        const name = profile.name || 'Unknown';
        const vstatus = p.verification_status;
        showModal('Provider Details', `
            <div style="text-align:center;margin-bottom:20px;">
                ${getInitialsAvatar(name, 64)}
                <h3 style="margin-top:12px;">${name}</h3>
                <span class="status-badge ${vstatus}">${vstatus}</span>
            </div>
            <div class="detail-grid">
                <div class="detail-item"><span>Email</span><strong>${profile.email || '—'}</strong></div>
                <div class="detail-item"><span>Phone</span><strong>${profile.phone || '—'}</strong></div>
                <div class="detail-item"><span>Category</span><strong>${cat.name || '—'}</strong></div>
                <div class="detail-item"><span>Hourly Rate</span><strong>₹${p.hourly_rate || 0}/hr</strong></div>
                <div class="detail-item"><span>Experience</span><strong>${p.experience || 0} year(s)</strong></div>
                <div class="detail-item"><span>Rating</span><strong>⭐ ${Number(p.rating||0).toFixed(1)} (${p.total_reviews||0} reviews)</strong></div>
                <div class="detail-item"><span>Total Bookings</span><strong>${p.total_bookings || 0}</strong></div>
                <div class="detail-item"><span>Joined</span><strong>${formatDate(p.created_at)}</strong></div>
            </div>
            ${p.description ? `<div class="detail-item" style="margin-top:12px;"><span>Bio</span><p style="margin-top:4px;color:#475569;">${p.description}</p></div>` : ''}
            ${p.skills?.length ? `<div class="detail-item" style="margin-top:12px;"><span>Skills</span><div style="display:flex;flex-wrap:wrap;gap:6px;margin-top:6px;">${p.skills.map(s=>`<span class="role-badge customer">${s}</span>`).join('')}</div></div>` : ''}
            ${vstatus === 'pending' ? `
            <div style="display:flex;gap:12px;margin-top:24px;justify-content:center;">
                <button class="btn btn-success" onclick="approveProvider('${p.id}')"><i class="fas fa-check"></i> Approve</button>
                <button class="btn btn-danger" onclick="rejectProvider('${p.id}')"><i class="fas fa-times"></i> Reject</button>
            </div>` : `
            <div style="display:flex;gap:12px;margin-top:24px;justify-content:center;">
                ${vstatus === 'approved' ? `<button class="btn btn-danger" onclick="rejectProvider('${p.id}')"><i class="fas fa-times"></i> Revoke Approval</button>` : `<button class="btn btn-success" onclick="approveProvider('${p.id}')"><i class="fas fa-check"></i> Approve</button>`}
            </div>`}
        `, 'lg');
    } catch (e) {
        showModal('Provider Details', `<p style="color:red;">Error: ${e.message}</p>`);
    }
};

window.approveProvider = async function(id) {
    try {
        await updateProviderStatus(id, 'approved');
        showToast('Provider approved!', 'success');
        closeModal();
        loadProvidersPage({ status: currentProviderTab === 'all' ? '' : currentProviderTab });
    } catch(e) { showToast('Error: ' + e.message, 'error'); }
};
window.rejectProvider = async function(id) {
    try {
        await updateProviderStatus(id, 'rejected');
        showToast('Provider rejected.', 'info');
        closeModal();
        loadProvidersPage({ status: currentProviderTab === 'all' ? '' : currentProviderTab });
    } catch(e) { showToast('Error: ' + e.message, 'error'); }
};

// ─── BOOKINGS PAGE ────────────────────────────────────────────────────────────
async function loadBookingsPage({ status = '' } = {}) {
    const tbody = document.getElementById('bookingsTable');
    if (!tbody) return;
    tbody.innerHTML = '<tr><td colspan="7" class="empty-cell"><div class="spinner" style="margin:auto;"></div></td></tr>';
    try {
        const bookings = await getBookings({ status });
        renderBookingsTable(bookings);
    } catch (err) {
        showToast('Error loading bookings: ' + err.message, 'error');
        tbody.innerHTML = '<tr><td colspan="7" class="empty-cell">Error loading bookings</td></tr>';
    }
}

function renderBookingsTable(bookings) {
    const tbody = document.getElementById('bookingsTable');
    if (!tbody) return;
    if (!bookings.length) {
        tbody.innerHTML = '<tr><td colspan="7" class="empty-cell">No bookings found</td></tr>';
        return;
    }
    tbody.innerHTML = bookings.map(b => {
        const customer = b.customer?.name || '—';
        const provProfile = b.provider?.profiles || b.provider?.['profiles!user_id'] || {};
        const provName = provProfile.name || '—';
        const amount = b.price?.totalAmount || b.price?.total_amount || 0;
        return `
        <tr>
            <td>#${b.id.slice(-6).toUpperCase()}</td>
            <td>${customer}</td>
            <td>${provName}</td>
            <td>${b.scheduled_date || '—'}</td>
            <td><span class="status-badge ${b.status}">${b.status}</span></td>
            <td>₹${Number(amount).toLocaleString('en-IN')}</td>
            <td>
                <button class="btn btn-sm btn-secondary" onclick="viewBooking('${b.id}')"><i class="fas fa-eye"></i></button>
            </td>
        </tr>`;
    }).join('');
}

window.viewBooking = async function(id) {
    showModal('Booking Details', '<div style="text-align:center;padding:20px;"><div class="spinner" style="margin:auto;"></div></div>', 'lg');
    try {
        const bookings = await getBookings({});
        const b = bookings.find(x => x.id === id);
        if (!b) throw new Error('Booking not found');
        const customer = b.customer || {};
        const provProfile = b.provider?.profiles || b.provider?.['profiles!user_id'] || {};
        const amount = b.price?.totalAmount || b.price?.total_amount || 0;
        const catName = b.category?.name || '—';
        showModal('Booking Details', `
            <div class="detail-grid">
                <div class="detail-item"><span>Booking ID</span><strong>#${b.id.slice(-8).toUpperCase()}</strong></div>
                <div class="detail-item"><span>Status</span><strong><span class="status-badge ${b.status}">${b.status}</span></strong></div>
                <div class="detail-item"><span>Customer</span><strong>${customer.name || '—'}</strong></div>
                <div class="detail-item"><span>Customer Email</span><strong>${customer.email || '—'}</strong></div>
                <div class="detail-item"><span>Provider</span><strong>${provProfile.name || '—'}</strong></div>
                <div class="detail-item"><span>Category</span><strong>${catName}</strong></div>
                <div class="detail-item"><span>Date</span><strong>${b.scheduled_date || '—'}</strong></div>
                <div class="detail-item"><span>Time</span><strong>${b.scheduled_time || '—'}</strong></div>
                <div class="detail-item"><span>Amount</span><strong>₹${Number(amount).toLocaleString('en-IN')}</strong></div>
                <div class="detail-item"><span>Created</span><strong>${formatDate(b.created_at)}</strong></div>
            </div>
            ${b.description ? `<div class="detail-item" style="margin-top:12px;"><span>Description</span><p style="margin-top:4px;color:#475569;">${b.description}</p></div>` : ''}
            <div style="margin-top:20px;">
                <label style="font-weight:500;font-size:14px;display:block;margin-bottom:8px;">Update Status</label>
                <div style="display:flex;gap:10px;align-items:center;">
                    <select id="bookingStatusSelect" style="padding:10px;border:1px solid #e5e7eb;border-radius:8px;font-family:inherit;flex:1;">
                        <option value="pending" ${b.status==='pending'?'selected':''}>Pending</option>
                        <option value="accepted" ${b.status==='accepted'?'selected':''}>Accepted</option>
                        <option value="in-progress" ${b.status==='in-progress'?'selected':''}>In Progress</option>
                        <option value="completed" ${b.status==='completed'?'selected':''}>Completed</option>
                        <option value="cancelled" ${b.status==='cancelled'?'selected':''}>Cancelled</option>
                    </select>
                    <button class="btn btn-primary" onclick="saveBookingStatus('${b.id}')">Save</button>
                </div>
            </div>
        `, 'lg');
    } catch (e) {
        showModal('Booking Details', `<p style="color:red;">Error: ${e.message}</p>`);
    }
};

window.saveBookingStatus = async function(id) {
    const newStatus = document.getElementById('bookingStatusSelect').value;
    try {
        await updateBookingStatus(id, newStatus);
        showToast('Booking status updated!', 'success');
        closeModal();
        const filterVal = document.getElementById('bookingStatusFilter').value;
        loadBookingsPage({ status: filterVal });
    } catch (e) { showToast('Error: ' + e.message, 'error'); }
};

// ─── CATEGORIES PAGE ──────────────────────────────────────────────────────────
async function loadCategoriesPage() {
    const grid = document.getElementById('categoriesGrid');
    if (!grid) return;
    grid.innerHTML = '<div style="text-align:center;padding:40px;"><div class="spinner" style="margin:auto;"></div></div>';
    try {
        currentCategoryList = await getCategories();
        renderCategoriesGrid(currentCategoryList);
    } catch (err) {
        showToast('Error loading categories: ' + err.message, 'error');
        grid.innerHTML = '<div class="empty-state"><p>Error loading categories</p></div>';
    }
}

const CAT_ICON_MAP = {
    electrical:'bolt', plumbing:'faucet', appliance:'tv', computer:'laptop',
    maintenance:'tools', tutoring:'graduation-cap', beauty:'spa', parlour:'spa',
    automotive:'car', default:'handshake',
};
function getCatIcon(iconOrObj) {
    if (typeof iconOrObj === 'object' && iconOrObj !== null) {
        let icon = iconOrObj.icon || iconOrObj.category_icon || '';
        let name = (iconOrObj.name || iconOrObj.category_name || '').toLowerCase();
        if ((!icon || icon === 'default') && name.includes('beauty')) return 'spa';
        return CAT_ICON_MAP[icon] || icon || CAT_ICON_MAP.default;
    }
    return CAT_ICON_MAP[iconOrObj] || iconOrObj || CAT_ICON_MAP.default;
}

function renderCategoriesGrid(categories) {
    const grid = document.getElementById('categoriesGrid');
    if (!grid) return;
    if (!categories.length) {
        grid.innerHTML = '<div class="empty-state"><i class="fas fa-tags"></i><h3>No categories yet</h3><p>Add your first category</p></div>';
        return;
    }
    grid.innerHTML = categories.map(c => `
        <div class="category-card">
            <div class="category-icon" style="background:${c.color}20;color:${c.color}">
                <i class="fas fa-${getCatIcon(c)}"></i>
            </div>
            <h4>${c.name}</h4>
            <p>${c.description || 'No description'}</p>
            <div class="category-stats">
                <span><i class="fas fa-user-tie"></i> ${c.total_providers || 0} providers</span>
                <span><i class="fas fa-dollar-sign"></i> ₹${c.average_rate || 0}/hr avg</span>
            </div>
            <div class="category-actions" style="margin-top:16px;display:flex;gap:8px;">
                <button class="btn btn-sm btn-secondary" onclick="editCategory('${c.id}')"><i class="fas fa-edit"></i> Edit</button>
                <button class="btn btn-sm btn-danger" onclick="deleteCategoryConfirm('${c.id}','${(c.name||'').replace(/'/g,"\\'")}')"><i class="fas fa-trash"></i></button>
            </div>
        </div>
    `).join('');
}

window.showAddCategoryModal = function() {
    showModal('Add Category', buildCategoryForm(null));
    document.getElementById('categoryForm').onsubmit = async function(e) {
        e.preventDefault();
        const btn = this.querySelector('[type=submit]');
        btn.textContent = 'Saving...'; btn.disabled = true;
        try {
            await createCategory({
                name: document.getElementById('catName').value,
                icon: document.getElementById('catIcon').value || 'default',
                color: document.getElementById('catColor').value || '#2196F3',
                description: document.getElementById('catDesc').value,
                commission_rate: parseFloat(document.getElementById('catCommission').value) || 10,
            });
            showToast('Category created!', 'success');
            closeModal();
            loadCategoriesPage();
        } catch (e) {
            showToast('Error: ' + e.message, 'error');
            btn.textContent = 'Save Category'; btn.disabled = false;
        }
    };
};

window.editCategory = function(id) {
    const cat = currentCategoryList.find(c => c.id === id);
    if (!cat) return;
    showModal('Edit Category', buildCategoryForm(cat));
    document.getElementById('categoryForm').onsubmit = async function(e) {
        e.preventDefault();
        const btn = this.querySelector('[type=submit]');
        btn.textContent = 'Saving...'; btn.disabled = true;
        try {
            await updateCategory(id, {
                name: document.getElementById('catName').value,
                icon: document.getElementById('catIcon').value || 'default',
                color: document.getElementById('catColor').value,
                description: document.getElementById('catDesc').value,
                commission_rate: parseFloat(document.getElementById('catCommission').value) || 10,
            });
            showToast('Category updated!', 'success');
            closeModal();
            loadCategoriesPage();
        } catch (e) {
            showToast('Error: ' + e.message, 'error');
            btn.textContent = 'Save Changes'; btn.disabled = false;
        }
    };
};

function buildCategoryForm(cat) {
    return `
    <form id="categoryForm">
        <div class="form-group">
            <label>Name</label>
            <input type="text" id="catName" value="${cat?.name||''}" placeholder="e.g. Plumbing" required>
        </div>
        <div class="form-group">
            <label>Icon (Font Awesome keyword)</label>
            <input type="text" id="catIcon" value="${cat?.icon||''}" placeholder="e.g. faucet, bolt, tools">
        </div>
        <div class="form-group">
            <label>Color</label>
            <input type="color" id="catColor" value="${cat?.color||'#2196F3'}" style="height:42px;">
        </div>
        <div class="form-group">
            <label>Description</label>
            <textarea id="catDesc" rows="3" placeholder="Short description...">${cat?.description||''}</textarea>
        </div>
        <div class="form-group">
            <label>Platform Commission Rate (%)
                <span style="font-size:12px;color:#64748b;font-weight:400;"> — your cut per completed job in this category</span>
            </label>
            <input type="number" id="catCommission" min="0" max="100" step="0.5"
                value="${cat?.commission_rate ?? 10}"
                placeholder="e.g. 10">
        </div>
        <div style="display:flex;gap:12px;justify-content:flex-end;">
            <button type="button" class="btn btn-secondary" onclick="closeModal()">Cancel</button>
            <button type="submit" class="btn btn-primary">${cat ? 'Save Changes' : 'Save Category'}</button>
        </div>
    </form>`;
}

window.deleteCategoryConfirm = function(id, name) {
    showConfirm('Delete Category',
        `Delete category <strong>${name}</strong>? This cannot be undone.`,
        async () => {
            try {
                await deleteCategory(id);
                showToast('Category deleted.', 'success');
                loadCategoriesPage();
            } catch (e) { showToast('Error: ' + e.message, 'error'); }
        }
    );
};

// ─── REVIEWS PAGE ─────────────────────────────────────────────────────────────
async function loadReviewsPage() {
    const tbody = document.getElementById('reviewsTable');
    if (!tbody) return;
    tbody.innerHTML = '<tr><td colspan="6" class="empty-cell"><div class="spinner" style="margin:auto;"></div></td></tr>';
    try {
        const reviews = await getReviews();
        renderReviewsTable(reviews);
    } catch (err) {
        showToast('Error loading reviews: ' + err.message, 'error');
        tbody.innerHTML = '<tr><td colspan="6" class="empty-cell">Error loading reviews</td></tr>';
    }
}

function renderReviewsTable(reviews) {
    const tbody = document.getElementById('reviewsTable');
    if (!tbody) return;
    if (!reviews.length) {
        tbody.innerHTML = '<tr><td colspan="6" class="empty-cell">No reviews found</td></tr>';
        return;
    }
    tbody.innerHTML = reviews.map(r => {
        const customer = r.customer?.name || '—';
        const provProfile = r.provider?.profiles || r.provider?.['profiles!user_id'] || {};
        const provName = provProfile.name || '—';
        const stars = Array(5).fill(0).map((_, i) =>
            `<i class="fas fa-star" style="color:${i < r.rating ? '#FFC107' : '#e2e8f0'};font-size:12px;"></i>`
        ).join('');
        return `
        <tr>
            <td>${customer}</td>
            <td>${provName}</td>
            <td><div class="rating">${stars} <span style="margin-left:4px;">${r.rating}/5</span></div></td>
            <td style="max-width:200px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap;" title="${r.comment||''}">${r.comment || '—'}</td>
            <td>${formatDate(r.created_at)}</td>
            <td>
                <button class="btn btn-sm btn-danger" onclick="deleteReviewConfirm('${r.id}')">
                    <i class="fas fa-trash"></i>
                </button>
            </td>
        </tr>`;
    }).join('');
}

window.deleteReviewConfirm = function(id) {
    showConfirm('Delete Review', 'Are you sure you want to delete this review? This cannot be undone.', async () => {
        try {
            await deleteReview(id);
            showToast('Review deleted.', 'success');
            loadReviewsPage();
        } catch (e) { showToast('Error: ' + e.message, 'error'); }
    });
};

// ─── SETTINGS PAGE ────────────────────────────────────────────────────────────
async function loadSettingsPage() {
    try {
        const settings = await getSettings();

        // Populate form fields from platform_settings table
        const platformName = document.getElementById('settingPlatformName');
        const supportEmail = document.getElementById('settingSupportEmail');
        const commissionRate = document.getElementById('settingCommissionRate');
        const commissionDisplay = document.getElementById('settingCommissionDisplay');

        if (platformName) platformName.value = settings.platform_name || 'ProConnect';
        if (supportEmail) supportEmail.value = settings.support_email || 'support@proconnect.com';
        if (commissionRate) {
            commissionRate.value = settings.commission_rate || '10';
            if (commissionDisplay) commissionDisplay.textContent = (settings.commission_rate || '10') + '%';
        }
    } catch (err) {
        console.error('Settings load error:', err);
        // Table may not exist yet — show notice
        const settingsCard = document.getElementById('settingsFormCard');
        if (settingsCard) {
            settingsCard.insertAdjacentHTML('afterbegin',
                `<div style="background:#fef3c7;border:1px solid #f59e0b;border-radius:8px;padding:12px;margin-bottom:16px;font-size:13px;color:#92400e;">
                    ⚠️ Run <strong>004_platform_settings.sql</strong> in Supabase SQL Editor to enable settings persistence.
                </div>`
            );
        }
    }
}

async function saveSettingsForm(e) {
    e.preventDefault();
    const btn = e.target.querySelector('[type=submit]');
    btn.textContent = 'Saving...'; btn.disabled = true;
    try {
        const platformName = document.getElementById('settingPlatformName')?.value;
        const supportEmail = document.getElementById('settingSupportEmail')?.value;
        const commissionRate = document.getElementById('settingCommissionRate')?.value;

        await Promise.all([
            platformName !== undefined ? saveSetting('platform_name', platformName) : Promise.resolve(),
            supportEmail !== undefined ? saveSetting('support_email', supportEmail) : Promise.resolve(),
            commissionRate !== undefined ? saveSetting('commission_rate', commissionRate) : Promise.resolve(),
        ]);
        showToast('Settings saved successfully!', 'success');
    } catch (err) {
        showToast('Error saving settings: ' + err.message, 'error');
    } finally {
        btn.textContent = 'Save Changes'; btn.disabled = false;
    }
}

// ─── EARNINGS PAGE ────────────────────────────────────────────────────────────

async function loadEarningsPage() {
    // Reset stat cards
    ['eTotalProfit','eTotalGross','eTotalPayouts','eTotalCompleted'].forEach(id => {
        const el = document.getElementById(id);
        if (el) el.innerHTML = '<div class="spinner" style="margin:auto;width:20px;height:20px;"></div>';
    });
    document.getElementById('earningsCategoryTable').innerHTML =
        '<tr><td colspan="6" class="empty-cell"><div class="spinner" style="margin:auto;"></div></td></tr>';
    document.getElementById('earningsTransactionsTable').innerHTML =
        '<tr><td colspan="8" class="empty-cell"><div class="spinner" style="margin:auto;"></div></td></tr>';

    try {
        const [categories, transactions] = await Promise.all([
            getEarningsByCategory(),
            getCompletedBookingsForEarnings(30),
        ]);

        // Totals
        const totalProfit    = categories.reduce((s, c) => s + Number(c.platform_profit || 0), 0);
        const totalGross     = categories.reduce((s, c) => s + Number(c.gross_revenue || 0), 0);
        const totalPayouts   = categories.reduce((s, c) => s + Number(c.provider_payouts || 0), 0);
        const totalCompleted = categories.reduce((s, c) => s + Number(c.total_bookings || 0), 0);

        const fmt = v => `₹${Number(v).toLocaleString('en-IN', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`;

        document.getElementById('eTotalProfit').textContent    = fmt(totalProfit);
        document.getElementById('eTotalGross').textContent     = fmt(totalGross);
        document.getElementById('eTotalPayouts').textContent   = fmt(totalPayouts);
        document.getElementById('eTotalCompleted').textContent = totalCompleted;

        renderEarningsCategoryTable(categories);
        renderEarningsTransactionsTable(transactions);
    } catch (err) {
        showToast('Error loading earnings: ' + err.message, 'error');
        ['eTotalProfit','eTotalGross','eTotalPayouts','eTotalCompleted'].forEach(id => {
            const el = document.getElementById(id);
            if (el) el.textContent = '—';
        });
    }
}

function renderEarningsCategoryTable(categories) {
    const tbody = document.getElementById('earningsCategoryTable');
    if (!tbody) return;
    if (!categories.length) {
        tbody.innerHTML = '<tr><td colspan="6" class="empty-cell">No categories found.</td></tr>';
        return;
    }
    const fmt = v => `₹${Number(v).toLocaleString('en-IN', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`;

    tbody.innerHTML = categories.map(cat => {
        const rate = Number(cat.commission_rate || 10);
        const color = cat.category_color || '#2196F3';
        return `
        <tr>
            <td>
                <div style="display:flex;align-items:center;gap:10px;">
                    <div style="width:32px;height:32px;border-radius:8px;background:${color}20;
                                display:flex;align-items:center;justify-content:center;">
                        <i class="fas fa-${getCatIcon(cat)}" style="color:${color};font-size:14px;"></i>
                    </div>
                    <strong>${cat.category_name}</strong>
                </div>
            </td>
            <td>
                <div style="display:flex;align-items:center;gap:8px;">
                    <input
                        type="number" min="0" max="100" step="0.5"
                        value="${rate}"
                        style="width:72px;padding:6px;border:1px solid #e2e8f0;border-radius:6px;text-align:center;font-family:inherit;"
                        data-cat-id="${cat.category_id}"
                        onchange="saveEarningsCommission(this)"
                        title="Commission rate for ${cat.category_name}"
                    >
                    <span style="color:#64748b;font-size:13px;">%</span>
                </div>
            </td>
            <td>${cat.total_bookings}</td>
            <td>${fmt(cat.gross_revenue)}</td>
            <td style="color:#4CAF50;font-weight:600;">${fmt(cat.platform_profit)}</td>
            <td style="color:#2196F3;">${fmt(cat.provider_payouts)}</td>
        </tr>`;
    }).join('');
}

window.saveEarningsCommission = async function(input) {
    const categoryId = input.getAttribute('data-cat-id');
    const rate = parseFloat(input.value);
    if (isNaN(rate) || rate < 0 || rate > 100) {
        showToast('Rate must be between 0 and 100', 'error');
        return;
    }
    try {
        await setCategoryCommissionRate(categoryId, rate);
        showToast(`Commission rate updated to ${rate}%`, 'success');
        // Reload to refresh all totals
        loadEarningsPage();
    } catch (err) {
        showToast('Error: ' + err.message, 'error');
    }
};

function renderEarningsTransactionsTable(bookings) {
    const tbody = document.getElementById('earningsTransactionsTable');
    if (!tbody) return;
    if (!bookings.length) {
        tbody.innerHTML = '<tr><td colspan="8" class="empty-cell">No completed transactions yet.</td></tr>';
        return;
    }
    const fmt = v => `₹${Number(v).toLocaleString('en-IN', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`;

    tbody.innerHTML = bookings.map(b => {
        const gross = Number(b.price?.totalAmount || b.price?.total_amount || 0);
        const commRate = Number(b.category?.commission_rate || 10) / 100;
        const cut = gross * commRate;
        const net = gross - cut;
        const customer = b.customer?.name || '—';
        const provProfile = b.provider?.profiles || b.provider?.['profiles!user_id'] || {};
        const provName = provProfile.name || '—';
        const catName = b.category?.name || '—';
        const catRate = Number(b.category?.commission_rate || 10);

        return `
        <tr>
            <td>${customer}</td>
            <td>${provName}</td>
            <td>${catName}</td>
            <td>${fmt(gross)}</td>
            <td><span style="background:#f1f5f9;padding:2px 8px;border-radius:12px;font-size:12px;font-weight:600;">${catRate}%</span></td>
            <td style="color:#4CAF50;font-weight:600;">${fmt(cut)}</td>
            <td style="color:#2196F3;">${fmt(net)}</td>
            <td>${formatDate(b.created_at)}</td>
        </tr>`;
    }).join('');
}


