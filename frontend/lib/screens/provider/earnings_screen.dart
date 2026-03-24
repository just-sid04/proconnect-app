import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/supabase_service.dart';
import '../../utils/theme.dart';

/// A self-contained earnings screen that queries Supabase directly.
/// This avoids any BookingProvider mapping issues by reading the raw
/// `price` JSONB column and `categories.commission_rate` in one query.
class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  bool _loading = true;
  String? _error;

  // Raw completed bookings from Supabase
  List<Map<String, dynamic>> _completedJobs = [];

  // Per-category commission rates { categoryId -> rate%}
  Map<String, double> _categoryRates = {};
  double _globalRate = 10.0;

  // Provider info
  String? _providerName;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAll());
  }

  // ─── Supabase Queries ───────────────────────────────────────────────────────

  Future<void> _loadAll() async {
    if (!mounted) return;
    setState(() { _loading = true; _error = null; });

    try {
      final sb = SupabaseService.instance.client;
      final authUser = Provider.of<AuthProvider>(context, listen: false).user;
      final userId = sb.auth.currentUser?.id;
      if (userId == null) throw Exception('Not authenticated');

      // 1. Get provider row ID + name
      final provRow = await sb
          .from('service_providers')
          .select('id, profiles!user_id(name)')
          .eq('user_id', userId)
          .maybeSingle();

      if (provRow == null) {
        setState(() { _loading = false; _error = 'No provider profile found.'; });
        return;
      }
      final providerId = (provRow as Map)['id'] as String;
      final provProfileMap = provRow['profiles'] ?? provRow['profiles!user_id'];
      _providerName = (provProfileMap is Map ? provProfileMap['name'] : null)
          ?? authUser?.name
          ?? 'Provider';

      // 2. Fetch completed bookings with raw price JSONB + category commission
      final bookingsRaw = await sb
          .from('bookings')
          .select(
            'id, price, scheduled_date, completed_at, created_at, description,'
            'customer:profiles!customer_id(name),'
            'category:categories!category_id(id, name, commission_rate)',
          )
          .eq('provider_id', providerId)
          .eq('status', 'completed')
          .order('completed_at', ascending: false);

      // 3. Fetch global commission fallback
      final globalRow = await sb
          .from('platform_settings')
          .select('value')
          .eq('key', 'commission_rate')
          .maybeSingle();

      if (!mounted) return;

      final rates = <String, double>{};
      for (final b in (bookingsRaw as List)) {
        final cat = b['category'];
        if (cat is Map) {
          final id = cat['id']?.toString() ?? '';
          final rate = double.tryParse(cat['commission_rate']?.toString() ?? '') ?? 10.0;
          if (id.isNotEmpty) rates[id] = rate;
        }
      }

      double globalRate = 10.0;
      if (globalRow != null) {
        globalRate = double.tryParse((globalRow as Map)['value']?.toString() ?? '10') ?? 10.0;
      }

      setState(() {
        _completedJobs = List<Map<String, dynamic>>.from(bookingsRaw as List);
        _categoryRates = rates;
        _globalRate = globalRate;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() { _loading = false; _error = e.toString(); });
    }
  }

  // ─── Price extraction (reads raw JSONB directly) ───────────────────────────

  double _gross(Map<String, dynamic> b) {
    final price = b['price'];
    if (price == null) return 0.0;
    // Try both camelCase and snake_case keys since older bookings may differ
    final total = (price['totalAmount'] ?? price['total_amount'] ?? 0);
    final materials = (price['materialsCost'] ?? price['materials_cost'] ?? 0);
    return (total as num).toDouble() + (materials as num).toDouble();
  }

  double _rate(Map<String, dynamic> b) {
    final cat = b['category'];
    if (cat is Map) {
      final catId = cat['id']?.toString() ?? '';
      if (_categoryRates.containsKey(catId)) return _categoryRates[catId]!;
      final rate = double.tryParse(cat['commission_rate']?.toString() ?? '');
      if (rate != null) return rate;
    }
    return _globalRate;
  }

  double _cut(Map<String, dynamic> b) => _gross(b) * (_rate(b) / 100.0);
  double _net(Map<String, dynamic> b) => _gross(b) - _cut(b);

  DateTime _date(Map<String, dynamic> b) =>
      DateTime.tryParse(b['completed_at']?.toString() ?? '') ??
      DateTime.tryParse(b['created_at']?.toString() ?? '') ??
      DateTime.now();

  String _customerName(Map<String, dynamic> b) {
    final c = b['customer'];
    return (c is Map ? c['name'] : null) ?? 'Customer';
  }

  String _catName(Map<String, dynamic> b) {
    final c = b['category'];
    return (c is Map ? c['name'] : null) ?? '—';
  }

  // ─── Aggregates ─────────────────────────────────────────────────────────────

  double get _totalGross  => _completedJobs.fold(0, (s, b) => s + _gross(b));
  double get _totalCut    => _completedJobs.fold(0, (s, b) => s + _cut(b));
  double get _totalNet    => _completedJobs.fold(0, (s, b) => s + _net(b));

  double get _monthNet {
    final now = DateTime.now();
    return _completedJobs
        .where((b) { final d = _date(b); return d.year == now.year && d.month == now.month; })
        .fold(0, (s, b) => s + _net(b));
  }

  double get _weekNet {
    final now = DateTime.now();
    final weekStart = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    return _completedJobs
        .where((b) => !_date(b).isBefore(weekStart))
        .fold(0, (s, b) => s + _net(b));
  }

  String _fmt(double v) =>
      NumberFormat.currency(symbol: '₹', decimalDigits: 2).format(v);

  // ─── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Earnings'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadAll),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : RefreshIndicator(
                  onRefresh: _loadAll,
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      _buildHeroCard(),
                      const SizedBox(height: 16),
                      _buildCommissionCard(),
                      const SizedBox(height: 16),
                      _buildStatRow(),
                      const SizedBox(height: 28),
                      const Text('Transaction History',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      if (_completedJobs.isEmpty)
                        _buildEmpty()
                      else
                        ..._completedJobs.map((b) => _buildTxTile(b)),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
    );
  }

  // ─── Sub-widgets ────────────────────────────────────────────────────────────

  Widget _buildError() => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.red),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton.icon(
                onPressed: _loadAll,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry')),
          ]),
        ),
      );

  Widget _buildEmpty() => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Column(children: [
            Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text('No completed transactions yet.',
                style: TextStyle(fontSize: 15, color: AppTheme.textSecondary)),
          ]),
        ),
      );

  Widget _buildHeroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryColor, Color(0xFF1565C0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(_providerName ?? 'Earnings',
            style: const TextStyle(fontSize: 14, color: Colors.white70)),
        const SizedBox(height: 2),
        const Text('Total Net Earnings (after platform commission)',
            style: TextStyle(fontSize: 11, color: Colors.white60)),
        const SizedBox(height: 8),
        Text(_fmt(_totalNet),
            style: const TextStyle(
                fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: _HeroStat(label: 'This Month', value: _fmt(_monthNet))),
          Expanded(child: _HeroStat(label: 'This Week', value: _fmt(_weekNet))),
        ]),
      ]),
    );
  }

  Widget _buildCommissionCard() {
    final rates = _categoryRates.values.toSet();
    final rateLabel = rates.length == 1
        ? '${rates.first.toStringAsFixed(1)}%'
        : '${_globalRate.toStringAsFixed(1)}% (default)';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.pie_chart_outline, color: Colors.orange, size: 18),
          const SizedBox(width: 8),
          Text('Platform Commission: $rateLabel',
              style: const TextStyle(
                  fontWeight: FontWeight.w600, color: Colors.orange, fontSize: 14)),
        ]),
        const SizedBox(height: 4),
        const Text('Set per category by admin. Changes reflect here immediately.',
            style: TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 14),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          _AmtLabel(label: 'Gross Revenue', value: _fmt(_totalGross), color: Colors.black87),
          _AmtLabel(label: 'Platform Cut', value: '-${_fmt(_totalCut)}', color: Colors.orange),
          _AmtLabel(label: 'Your Net', value: _fmt(_totalNet), color: Colors.green),
        ]),
      ]),
    );
  }

  Widget _buildStatRow() {
    final avg = _completedJobs.isEmpty ? 0.0 : _totalNet / _completedJobs.length;
    return Row(children: [
      Expanded(
        child: _StatCard(
          title: 'Completed',
          value: '${_completedJobs.length}',
          icon: Icons.check_circle,
          color: AppTheme.secondaryColor,
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: _StatCard(
          title: 'Avg Net/Job',
          value: _fmt(avg),
          icon: Icons.insights,
          color: AppTheme.infoColor,
        ),
      ),
    ]);
  }

  Widget _buildTxTile(Map<String, dynamic> b) {
    final gross = _gross(b);
    final cut = _cut(b);
    final net = _net(b);
    final rate = _rate(b);
    final date = _date(b);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green.shade50,
          child: const Icon(Icons.payments_outlined, color: Colors.green),
        ),
        title: Text(
          _customerName(b),
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Text(
          '${_catName(b)}  •  ${DateFormat('MMM dd, yyyy').format(date)}',
          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(_fmt(net),
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.green, fontSize: 15)),
            Text('${rate.toStringAsFixed(1)}% cut',
                style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Column(children: [
              _TxRow(label: 'Gross Amount', value: _fmt(gross), color: Colors.black87),
              _TxRow(
                  label: 'Platform Fee (${rate.toStringAsFixed(1)}%)',
                  value: '- ${_fmt(cut)}',
                  color: Colors.orange),
              const Divider(height: 16),
              _TxRow(label: 'Your Earnings', value: _fmt(net), color: Colors.green, bold: true),
            ]),
          ),
        ],
      ),
    );
  }
}

// ─── Small reusable widgets ───────────────────────────────────────────────────

class _HeroStat extends StatelessWidget {
  final String label, value;
  const _HeroStat({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.white70)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
        ],
      );
}

class _AmtLabel extends StatelessWidget {
  final String label, value;
  final Color color;
  const _AmtLabel({required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) => Column(children: [
        Text(value,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: color)),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
      ]);
}

class _StatCard extends StatelessWidget {
  final String title, value;
  final IconData icon;
  final Color color;
  const _StatCard({required this.title, required this.value, required this.icon, required this.color});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withAlpha(25),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(title,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: color.withAlpha(200))),
        ]),
      );
}

class _TxRow extends StatelessWidget {
  final String label, value;
  final Color color;
  final bool bold;
  const _TxRow({required this.label, required this.value, required this.color, this.bold = false});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
            Text(value,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                    color: color)),
          ],
        ),
      );
}
