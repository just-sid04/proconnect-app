/**
 * ProConnect Admin Dashboard — Supabase Data Layer
 * All data access functions — directly queries Supabase (no REST backend).
 */

// ─── AUTH ────────────────────────────────────────────────────────────────────

async function checkAuth() {
    const { data: { session } } = await supabaseClient.auth.getSession();
    if (!session) {
        window.location.href = 'login.html';
        return null;
    }
    // Ensure the logged-in user is an admin
    const { data: profile } = await supabaseClient
        .from('profiles')
        .select('id, name, email, role, profile_photo')
        .eq('id', session.user.id)
        .single();
    if (!profile || profile.role !== 'admin') {
        await supabaseClient.auth.signOut();
        window.location.href = 'login.html';
        return null;
    }
    return profile;
}

async function logoutUser() {
    await supabaseClient.auth.signOut();
    window.location.href = 'login.html';
}

// ─── DASHBOARD STATS ─────────────────────────────────────────────────────────

async function getDashboardStats() {
    const [usersRes, providersRes, bookingsRes, revenueRes] = await Promise.all([
        supabaseClient.from('profiles').select('id', { count: 'exact', head: true }),
        supabaseClient.from('service_providers').select('id', { count: 'exact', head: true }),
        supabaseClient.from('bookings').select('id', { count: 'exact', head: true }),
        supabaseClient.from('bookings').select('price').eq('status', 'completed'),
    ]);

    let revenue = 0;
    if (revenueRes.data) {
        revenue = revenueRes.data.reduce((sum, b) => {
            const total = b.price?.totalAmount || b.price?.total_amount || 0;
            return sum + Number(total);
        }, 0);
    }

    return {
        users: usersRes.count || 0,
        providers: providersRes.count || 0,
        bookings: bookingsRes.count || 0,
        revenue,
    };
}

async function getRecentBookings() {
    const { data } = await supabaseClient
        .from('bookings')
        .select(`
            id, status, price, scheduled_date,
            customer:profiles!customer_id(name),
            provider:service_providers!provider_id(
                profiles!user_id(name)
            )
        `)
        .order('created_at', { ascending: false })
        .limit(5);
    return data || [];
}

async function getPendingVerifications() {
    const { data } = await supabaseClient
        .from('service_providers')
        .select(`
            id, verification_status, rating, total_reviews,
            profiles!user_id(name, email, profile_photo),
            categories!category_id(name)
        `)
        .eq('verification_status', 'pending')
        .order('created_at', { ascending: false })
        .limit(5);
    return data || [];
}

// ─── NOTIFICATIONS ────────────────────────────────────────────────────────────

async function getNotifications() {
    const since = new Date(Date.now() - 48 * 60 * 60 * 1000).toISOString();
    const [bookingsRes, signupsRes, providersRes] = await Promise.all([
        supabaseClient.from('bookings').select('id, status, created_at, customer:profiles!customer_id(name)')
            .gte('created_at', since).order('created_at', { ascending: false }).limit(5),
        supabaseClient.from('profiles').select('id, name, role, created_at')
            .gte('created_at', since).order('created_at', { ascending: false }).limit(5),
        supabaseClient.from('service_providers').select('id, created_at, profiles!user_id(name)')
            .eq('verification_status', 'pending').gte('created_at', since)
            .order('created_at', { ascending: false }).limit(5),
    ]);

    const notifications = [];
    (bookingsRes.data || []).forEach(b => notifications.push({
        type: 'booking', icon: 'calendar-check', color: '#2196F3',
        text: `New booking from ${b.customer?.name || 'Unknown'}`,
        time: b.created_at,
    }));
    (signupsRes.data || []).forEach(u => notifications.push({
        type: 'signup', icon: 'user-plus', color: '#4CAF50',
        text: `${u.name} signed up as ${u.role}`,
        time: u.created_at,
    }));
    (providersRes.data || []).forEach(p => notifications.push({
        type: 'provider', icon: 'user-tie', color: '#FF9800',
        text: `${p.profiles?.name || 'A provider'} registered — awaiting verification`,
        time: p.created_at,
    }));

    notifications.sort((a, b) => new Date(b.time) - new Date(a.time));
    return notifications.slice(0, 10);
}

// ─── USERS ────────────────────────────────────────────────────────────────────

async function getUsers({ search = '', role = '' } = {}) {
    let query = supabaseClient
        .from('profiles')
        .select('*')
        .order('created_at', { ascending: false });
    if (search) query = query.ilike('name', `%${search}%`);
    if (role) query = query.eq('role', role);
    const { data, error } = await query;
    if (error) throw error;
    return data || [];
}

async function getUserById(id) {
    const { data, error } = await supabaseClient
        .from('profiles').select('*').eq('id', id).single();
    if (error) throw error;
    return data;
}

async function createUser({ name, email, password, role, phone = '' }) {
    // Uses regular signUp (anon key compatible). auth.admin.createUser requires service role key.
    const { data, error } = await supabaseClient.auth.signUp({
        email, password,
        options: { data: { name, role, phone } },
    });
    if (error) throw error;
    return data.user;
}

async function deactivateUser(id) {
    const { error } = await supabaseClient
        .from('profiles').update({ is_active: false }).eq('id', id);
    if (error) throw error;
}

async function activateUser(id) {
    const { error } = await supabaseClient
        .from('profiles').update({ is_active: true }).eq('id', id);
    if (error) throw error;
}

// ─── PROVIDERS ────────────────────────────────────────────────────────────────

async function getProviders({ status = '' } = {}) {
    let query = supabaseClient
        .from('service_providers')
        .select(`
            id, verification_status, is_verified, rating, total_reviews,
            total_bookings, hourly_rate, description, skills, experience,
            created_at,
            profiles!user_id(id, name, email, profile_photo, phone),
            categories!category_id(id, name, icon, color)
        `)
        .order('created_at', { ascending: false });
    if (status) query = query.eq('verification_status', status);
    const { data, error } = await query;
    if (error) throw error;
    return data || [];
}

async function getProviderDocuments(providerId) {
    const { data, error } = await supabaseClient
        .from('service_providers')
        .select('documents')
        .eq('id', providerId)
        .single();
    if (error) throw error;
    return data.documents || [];
}

async function getSignedUrls(bucket, paths, expires = 3600) {
    if (!paths || !paths.length) return [];
    // Paths are usually full URLs or relative paths stored in DB.
    // If they are full URLs from Supabase, we need to extract the relative path.
    const relativePaths = paths.map(p => {
        if (p.includes('/storage/v1/object/')) {
            const parts = p.split(`/storage/v1/object/public/${bucket}/`);
            if (parts.length > 1) return parts[1];
            // Handle private bucket URLs if they are different
            const privateParts = p.split(`/storage/v1/object/authenticated/${bucket}/`);
            if (privateParts.length > 1) return privateParts[1];
            // If it's just the filename or partial path, return as is
        }
        return p;
    });

    const { data, error } = await supabaseClient.storage.from(bucket).createSignedUrls(relativePaths, expires);
    if (error) throw error;
    return data.map(item => item.signedUrl);
}

async function updateProviderStatus(id, status) {
    const { error } = await supabaseClient
        .from('service_providers')
        .update({
            verification_status: status,
            is_verified: status === 'approved',
        })
        .eq('id', id);
    if (error) throw error;
}

// ─── BOOKINGS ─────────────────────────────────────────────────────────────────

async function getBookings({ status = '' } = {}) {
    let query = supabaseClient
        .from('bookings')
        .select(`
            id, status, scheduled_date, scheduled_time, price,
            description, notes, created_at,
            customer:profiles!customer_id(id, name, email, profile_photo),
            provider:service_providers!provider_id(
                id, hourly_rate,
                profiles!user_id(name, email, profile_photo)
            ),
            category:categories!category_id(name)
        `)
        .order('created_at', { ascending: false });
    if (status) query = query.eq('status', status);
    const { data, error } = await query;
    if (error) throw error;
    return data || [];
}

async function updateBookingStatus(id, status) {
    const { error } = await supabaseClient
        .from('bookings').update({ status }).eq('id', id);
    if (error) throw error;
}

// ─── CATEGORIES ───────────────────────────────────────────────────────────────

async function getCategories() {
    const { data, error } = await supabaseClient
        .from('categories')
        .select('*')
        .order('name', { ascending: true });
    if (error) throw error;
    return data || [];
}

async function createCategory({ name, icon, color, description, services, commission_rate }) {
    const { data, error } = await supabaseClient
        .from('categories')
        .insert({
            name, icon: icon || 'default', color: color || '#2196F3',
            description, services: services || [],
            commission_rate: commission_rate ?? 10,
        })
        .select().single();
    if (error) throw error;
    return data;
}

async function updateCategory(id, { name, icon, color, description, commission_rate }) {
    const { error } = await supabaseClient
        .from('categories')
        .update({ name, icon, color, description, commission_rate: commission_rate ?? 10 })
        .eq('id', id);
    if (error) throw error;
}

async function deleteCategory(id) {
    const { error } = await supabaseClient.from('categories').delete().eq('id', id);
    if (error) throw error;
}

// ─── REVIEWS ──────────────────────────────────────────────────────────────────

async function getReviews() {
    const { data, error } = await supabaseClient
        .from('reviews')
        .select(`
            id, rating, comment, created_at,
            customer:profiles!customer_id(name, profile_photo),
            provider:service_providers!provider_id(
                profiles!user_id(name)
            )
        `)
        .order('created_at', { ascending: false });
    if (error) throw error;
    return data || [];
}

async function deleteReview(id) {
    const { error } = await supabaseClient.from('reviews').delete().eq('id', id);
    if (error) throw error;
}

// ─── PLATFORM SETTINGS ────────────────────────────────────────────────────────

async function getSettings() {
    const { data, error } = await supabaseClient
        .from('platform_settings')
        .select('key, value, label')
        .order('key', { ascending: true });
    if (error) throw error;
    const map = {};
    (data || []).forEach(row => { map[row.key] = row.value; });
    return map;
}

async function saveSetting(key, value) {
    const { error } = await supabaseClient
        .from('platform_settings')
        .upsert({ key, value, updated_at: new Date().toISOString() }, { onConflict: 'key' });
    if (error) throw error;
}

// ─── EARNINGS ─────────────────────────────────────────────────────────────────

async function getEarningsByCategory() {
    // Try the view first; fall back to joining manually if view doesn't exist yet
    try {
        const { data, error } = await supabaseClient
            .from('admin_earnings_by_category')
            .select('*');
        if (error) throw error;
        return data || [];
    } catch (_) {
        // Fallback: manual join if view not yet created
        const { data: cats } = await supabaseClient
            .from('categories')
            .select('id, name, icon, color, commission_rate');
        const { data: bookings } = await supabaseClient
            .from('bookings')
            .select('category_id, price')
            .eq('status', 'completed');
        const catMap = {};
        (cats || []).forEach(c => {
            catMap[c.id] = {
                category_id: c.id, category_name: c.name,
                category_icon: c.icon, category_color: c.color,
                commission_rate: c.commission_rate ?? 10,
                total_bookings: 0, gross_revenue: 0,
                platform_profit: 0, provider_payouts: 0,
            };
        });
        (bookings || []).forEach(b => {
            const gross = Number(b.price?.totalAmount || b.price?.total_amount || 0);
            const entry = catMap[b.category_id];
            if (!entry) return;
            const rate = entry.commission_rate / 100;
            entry.total_bookings++;
            entry.gross_revenue += gross;
            entry.platform_profit += gross * rate;
            entry.provider_payouts += gross * (1 - rate);
        });
        return Object.values(catMap);
    }
}

async function setCategoryCommissionRate(categoryId, rate) {
    const { error } = await supabaseClient
        .from('categories')
        .update({ commission_rate: Number(rate) })
        .eq('id', categoryId);
    if (error) throw error;
}

async function getCompletedBookingsForEarnings(limit = 30) {
    const { data, error } = await supabaseClient
        .from('bookings')
        .select(`
            id, price, scheduled_date, created_at,
            customer:profiles!customer_id(name),
            provider:service_providers!provider_id(
                profiles!user_id(name)
            ),
            category:categories!category_id(name, commission_rate)
        `)
        .eq('status', 'completed')
        .order('created_at', { ascending: false })
        .limit(limit);
    if (error) throw error;
    return data || [];
}

