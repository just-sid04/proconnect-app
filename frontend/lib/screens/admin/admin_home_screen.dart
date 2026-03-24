import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../utils/theme.dart';
import '../auth/login_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  final ApiService _api = ApiService();
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _dashboard;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
    _pollTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (mounted) {
        _loadDashboard(silent: true);
      }
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadDashboard({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    final response = await _api.get('/admin/dashboard');
    if (!mounted) return;

    setState(() {
      _isLoading = silent ? _isLoading : false;
      if (response.success && response.data is Map<String, dynamic>) {
        _dashboard = response.data as Map<String, dynamic>;
      } else {
        _error = response.message.isNotEmpty
            ? response.message
            : 'Unable to load dashboard data.';
      }
    });
  }

  Future<void> _logout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.logout();
    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _showCollection({
    required String title,
    required String endpoint,
    required String type,
  }) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(sheetContext).size.height * 0.8,
            child: FutureBuilder<ApiResponse>(
              future: _api.get(endpoint),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final response = snapshot.data!;
                if (!response.success) {
                  return _SheetScaffold(
                    title: title,
                    child: Center(child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(response.message, textAlign: TextAlign.center),
                    )),
                  );
                }

                final dynamic rawData = response.data;
                final List<dynamic> items = rawData is List
                    ? rawData
                    : rawData is Map<String, dynamic>
                        ? (rawData['data'] as List<dynamic>? ??
                            rawData['items'] as List<dynamic>? ??
                            const [])
                        : const [];

                return _SheetScaffold(
                  title: title,
                  child: items.isEmpty
                      ? const Center(child: Text('No records found.'))
                      : ListView.separated(
                          itemCount: items.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final item = items[index] as Map<String, dynamic>;
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                item['name']?.toString() ??
                                    item['email']?.toString() ??
                                    item['id']?.toString() ??
                                    'Record ${index + 1}',
                              ),
                              subtitle: Text(_buildSubtitle(item)),
                              isThreeLine: true,
                              trailing: Wrap(
                                spacing: 4,
                                children: [
                                  IconButton(
                                    tooltip: 'View',
                                    onPressed: () => _showDetailsDialog(title, item),
                                    icon: const Icon(Icons.visibility_outlined),
                                  ),
                                  if (_canDelete(type, item))
                                    IconButton(
                                      tooltip: 'Delete',
                                      onPressed: () => _confirmDelete(type, item),
                                      icon: const Icon(Icons.delete_outline),
                                    ),
                                  if (type == 'users')
                                    IconButton(
                                      tooltip: item['isActive'] == false ? 'Unban' : 'Ban',
                                      onPressed: () => _toggleBanUser(item),
                                      icon: Icon(
                                        item['isActive'] == false
                                            ? Icons.lock_open_outlined
                                            : Icons.block_outlined,
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  bool _canDelete(String type, Map<String, dynamic> item) {
    if (type == 'users') return true;
    if (type == 'providers') return true;
    if (type == 'bookings') return true;
    if (type == 'reviews') return true;
    if (type == 'categories') return true;
    return false;
  }

  Future<void> _showDetailsDialog(String title, Map<String, dynamic> item) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$title Details'),
        content: SingleChildScrollView(
          child: SelectableText(const JsonEncoder.withIndent('  ').convert(item)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(String type, Map<String, dynamic> item) async {
    final id = item['id']?.toString();
    if (id == null || id.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Delete this $type record?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    String endpoint = '';
    switch (type) {
      case 'users':
        endpoint = '/users/$id';
        break;
      case 'providers':
        endpoint = '/providers/$id';
        break;
      case 'bookings':
        endpoint = '/bookings/$id';
        break;
      case 'reviews':
        endpoint = '/reviews/$id';
        break;
      case 'categories':
        endpoint = '/categories/$id';
        break;
    }
    if (endpoint.isEmpty) return;

    final response = await _api.delete(endpoint);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(response.success ? 'Deleted successfully' : response.message)),
    );
    await _loadDashboard(silent: true);
  }

  Future<void> _toggleBanUser(Map<String, dynamic> item) async {
    final id = item['id']?.toString();
    if (id == null || id.isEmpty) return;
    final isActive = item['isActive'] != false;
    final response = isActive
        ? await _api.put('/admin/users/$id/ban', body: {'reason': 'Banned by admin'})
        : await _api.put('/admin/users/$id/unban');
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(response.success ? 'User updated' : response.message)),
    );
    await _loadDashboard(silent: true);
  }

  Future<void> _showPendingVerifications() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _PendingVerificationsSheet(
        api: _api,
        onUpdated: _loadDashboard,
      ),
    );
    if (!mounted) return;
    _loadDashboard();
  }

  String _buildSubtitle(Map<String, dynamic> item) {
    final parts = <String>[];
    final email = item['email']?.toString();
    final role = item['role']?.toString();
    final status = item['status']?.toString();
    final createdAt = item['createdAt']?.toString();
    final verificationStatus = item['verificationStatus']?.toString();

    if (email != null && email.isNotEmpty) parts.add(email);
    if (role != null && role.isNotEmpty) parts.add('Role: $role');
    if (status != null && status.isNotEmpty) parts.add('Status: $status');
    if (verificationStatus != null && verificationStatus.isNotEmpty) {
      parts.add('Verification: $verificationStatus');
    }
    if (createdAt != null && createdAt.isNotEmpty) parts.add(createdAt);

    if (item['customer'] is Map<String, dynamic>) {
      final customer = item['customer'] as Map<String, dynamic>;
      parts.add('Customer: ${customer['name'] ?? 'Unknown'}');
    }

    if (item['provider'] is Map<String, dynamic>) {
      final provider = item['provider'] as Map<String, dynamic>;
      final providerUser = provider['user'] as Map<String, dynamic>?;
      parts.add('Provider: ${providerUser?['name'] ?? provider['id'] ?? 'Unknown'}');
    }

    if (item['user'] is Map<String, dynamic>) {
      final user = item['user'] as Map<String, dynamic>;
      parts.add('Applicant: ${user['name'] ?? 'Unknown'}');
      if ((user['email']?.toString().isNotEmpty ?? false)) {
        parts.add(user['email'].toString());
      }
    }

    return parts.isEmpty ? 'No additional details' : parts.join('\n');
  }

  @override
  Widget build(BuildContext context) {
    final stats = (_dashboard?['stats'] as Map<String, dynamic>?) ?? const {};
    final users = (stats['users'] as Map<String, dynamic>?) ?? const {};
    final providers = (stats['providers'] as Map<String, dynamic>?) ?? const {};
    final bookings = (stats['bookings'] as Map<String, dynamic>?) ?? const {};
    final revenue = (stats['revenue'] as Map<String, dynamic>?) ?? const {};

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboard,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(_error!, textAlign: TextAlign.center),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadDashboard,
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final crossAxisCount = constraints.maxWidth < 700 ? 1 : 2;
                          return GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: crossAxisCount == 1 ? 2.4 : 1.15,
                            children: [
                          _StatCard(
                            title: 'Total Users',
                            value: '${users['total'] ?? 0}',
                            subtitle: 'New this week: ${users['newThisWeek'] ?? 0}',
                            icon: Icons.people,
                            color: AppTheme.primaryColor,
                          ),
                          _StatCard(
                            title: 'Providers',
                            value: '${providers['total'] ?? 0}',
                            subtitle: 'Pending verification: ${providers['pendingVerification'] ?? 0}',
                            icon: Icons.work,
                            color: AppTheme.secondaryColor,
                          ),
                          _StatCard(
                            title: 'Bookings',
                            value: '${bookings['total'] ?? 0}',
                            subtitle: 'Pending: ${bookings['pending'] ?? 0}',
                            icon: Icons.calendar_today,
                            color: AppTheme.accentColor,
                          ),
                          _StatCard(
                            title: 'Revenue',
                            value: '\$${(revenue['total'] ?? 0).toString()}',
                            subtitle: 'This month: \$${(revenue['thisMonth'] ?? 0).toString()}',
                            icon: Icons.attach_money,
                            color: Colors.green,
                          ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Quick Actions',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      _ActionCard(
                        icon: Icons.verified_user,
                        title: 'Verify Providers',
                        subtitle: 'Approve or reject pending provider applications',
                        onTap: _showPendingVerifications,
                      ),
                      const SizedBox(height: 12),
                      _ActionCard(
                        icon: Icons.people_outline,
                        title: 'Manage Customers',
                        subtitle: 'Browse all customer users',
                        onTap: () => _showCollection(
                          title: 'Customers',
                          endpoint: '/admin/users?role=customer',
                          type: 'users',
                        ),
                      ),
                      const SizedBox(height: 12),
                      _ActionCard(
                        icon: Icons.engineering_outlined,
                        title: 'Manage Providers',
                        subtitle: 'View provider profiles separately',
                        onTap: () => _showCollection(
                          title: 'Providers',
                          endpoint: '/admin/providers',
                          type: 'providers',
                        ),
                      ),
                      const SizedBox(height: 12),
                      _ActionCard(
                        icon: Icons.calendar_today_outlined,
                        title: 'Manage Bookings',
                        subtitle: 'Inspect all booking records',
                        onTap: () => _showCollection(
                          title: 'Bookings',
                          endpoint: '/admin/bookings',
                          type: 'bookings',
                        ),
                      ),
                      const SizedBox(height: 12),
                      _ActionCard(
                        icon: Icons.category,
                        title: 'Manage Categories',
                        subtitle: 'Review active service categories',
                        onTap: () => _showCollection(
                          title: 'Categories',
                          endpoint: '/categories',
                          type: 'categories',
                        ),
                      ),
                      const SizedBox(height: 12),
                      _ActionCard(
                        icon: Icons.reviews,
                        title: 'Reports & Reviews',
                        subtitle: 'Inspect the latest review activity',
                        onTap: () => _showCollection(
                          title: 'Reviews',
                          endpoint: '/admin/reviews',
                          type: 'reviews',
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}

class _PendingVerificationsSheet extends StatefulWidget {
  final ApiService api;
  final Future<void> Function() onUpdated;

  const _PendingVerificationsSheet({
    required this.api,
    required this.onUpdated,
  });

  @override
  State<_PendingVerificationsSheet> createState() => _PendingVerificationsSheetState();
}

class _PendingVerificationsSheetState extends State<_PendingVerificationsSheet> {
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _error;
  List<dynamic> _items = const [];

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final response = await widget.api.get('/admin/verifications/pending');
    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (response.success && response.data is List) {
        _items = response.data as List<dynamic>;
      } else {
        _error = response.message.isNotEmpty
            ? response.message
            : 'Unable to load pending verifications.';
      }
    });
  }

  Future<void> _verifyProvider(Map<String, dynamic> provider, String status) async {
    final notesController = TextEditingController(
      text: provider['verificationNotes']?.toString() ?? '',
    );

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('${status == 'approved' ? 'Approve' : 'Reject'} Provider'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              provider['user']?['name']?.toString() ?? 'Unknown provider',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                hintText: 'Add review notes for this provider',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  status == 'approved' ? AppTheme.secondaryColor : AppTheme.errorColor,
              foregroundColor: Colors.white,
            ),
            child: Text(status == 'approved' ? 'Approve' : 'Reject'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _isSubmitting = true;
    });

    final response = await widget.api.put(
      '/admin/providers/${provider['id']}/verify',
      body: {
        'status': status,
        'notes': notesController.text.trim(),
      },
    );

    if (!mounted) return;

    setState(() {
      _isSubmitting = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          response.success
              ? 'Provider ${status == 'approved' ? 'approved' : 'rejected'} successfully.'
              : (response.message.isNotEmpty
                  ? response.message
                  : 'Unable to update verification status.'),
        ),
        backgroundColor: response.success ? AppTheme.successColor : AppTheme.errorColor,
      ),
    );

    if (response.success) {
      await _loadItems();
      await widget.onUpdated();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.85,
        child: _SheetScaffold(
          title: 'Pending Verifications',
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(_error!, textAlign: TextAlign.center),
                      ),
                    )
                  : _items.isEmpty
                      ? const Center(child: Text('No pending provider applications.'))
                      : Stack(
                          children: [
                            RefreshIndicator(
                              onRefresh: _loadItems,
                              child: ListView.separated(
                                padding: const EdgeInsets.all(16),
                                itemCount: _items.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  final provider = _items[index] as Map<String, dynamic>;
                                  final user = provider['user'] as Map<String, dynamic>?;
                                  final skills = (provider['skills'] as List<dynamic>? ?? const [])
                                      .map((skill) => skill.toString())
                                      .join(', ');

                                  return Card(
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              CircleAvatar(
                                                backgroundColor:
                                                    AppTheme.primaryColor.withOpacity(0.1),
                                                child: Text(
                                                  (user?['name']?.toString().isNotEmpty ?? false)
                                                      ? user!['name'].toString()[0].toUpperCase()
                                                      : 'P',
                                                  style: const TextStyle(
                                                    color: AppTheme.primaryColor,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      user?['name']?.toString() ?? 'Unknown provider',
                                                      style: const TextStyle(
                                                        fontWeight: FontWeight.w700,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      user?['email']?.toString() ?? 'No email',
                                                      style: const TextStyle(
                                                        color: AppTheme.textSecondary,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            provider['description']?.toString().isNotEmpty == true
                                                ? provider['description'].toString()
                                                : 'No description provided.',
                                          ),
                                          const SizedBox(height: 12),
                                          Wrap(
                                            spacing: 8,
                                            runSpacing: 8,
                                            children: [
                                              _InfoChip(label: 'Experience: ${provider['experience'] ?? 0} yrs'),
                                              _InfoChip(label: 'Rate: \$${provider['hourlyRate'] ?? 0}/hr'),
                                              _InfoChip(label: 'Area: ${provider['serviceArea'] ?? 0} miles'),
                                            ],
                                          ),
                                          if (skills.isNotEmpty) ...[
                                            const SizedBox(height: 12),
                                            Text(
                                              skills,
                                              style: const TextStyle(
                                                color: AppTheme.textSecondary,
                                              ),
                                            ),
                                          ],
                                          const SizedBox(height: 16),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: OutlinedButton.icon(
                                                  onPressed: _isSubmitting
                                                      ? null
                                                      : () => _verifyProvider(provider, 'rejected'),
                                                  icon: const Icon(Icons.close),
                                                  label: const Text('Reject'),
                                                  style: OutlinedButton.styleFrom(
                                                    foregroundColor: AppTheme.errorColor,
                                                    side: const BorderSide(
                                                      color: AppTheme.errorColor,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: ElevatedButton.icon(
                                                  onPressed: _isSubmitting
                                                      ? null
                                                      : () => _verifyProvider(provider, 'approved'),
                                                  icon: const Icon(Icons.check),
                                                  label: const Text('Approve'),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: AppTheme.secondaryColor,
                                                    foregroundColor: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            if (_isSubmitting)
                              Positioned.fill(
                                child: Container(
                                  color: Colors.black12,
                                  child: const Center(child: CircularProgressIndicator()),
                                ),
                              ),
                          ],
                        ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;

  const _InfoChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppTheme.primaryColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SheetScaffold extends StatelessWidget {
  final String title;
  final Widget child;

  const _SheetScaffold({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(child: child),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: color.withOpacity(0.9)),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppTheme.primaryColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
