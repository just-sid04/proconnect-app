import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'demand_map_screen.dart';
import '../../providers/analytics_provider.dart';
import '../../utils/theme.dart';

class BusinessInsightsScreen extends StatefulWidget {
  const BusinessInsightsScreen({super.key});

  @override
  State<BusinessInsightsScreen> createState() => _BusinessInsightsScreenState();
}

class _BusinessInsightsScreenState extends State<BusinessInsightsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AnalyticsProvider>().loadProviderStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final analytics = context.watch<AnalyticsProvider>();
    final stats = analytics.providerStats;

    return Scaffold(
      backgroundColor: AppTheme.navyDeep,
      appBar: AppBar(
        title: Text('Business Insights', 
            style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: analytics.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : analytics.error != null
              ? Center(child: Text('Error: ${analytics.error}', style: const TextStyle(color: Colors.white)))
              : stats == null
                  ? const Center(child: Text('No data available', style: TextStyle(color: Colors.white)))
                  : _buildContent(stats),
    );
  }

  Widget _buildContent(Map<String, dynamic> stats) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryGrid(stats),
          const SizedBox(height: 32),
          _buildEarningsChart(),
          const SizedBox(height: 32),
          _buildPerformanceSection(stats),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSummaryGrid(Map<String, dynamic> stats) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.4,
      children: [
        _MetricCard(
          label: 'Total Earnings',
          value: '₹${stats['total_earnings'] ?? 0}',
          icon: Icons.account_balance_wallet_rounded,
          color: AppTheme.successColor,
        ),
        _MetricCard(
          label: 'Bookings',
          value: '${stats['total_bookings'] ?? 0}',
          icon: Icons.receipt_long_rounded,
          color: AppTheme.primaryColor,
        ),
        _MetricCard(
          label: 'Avg Rating',
          value: '${(stats['avg_rating'] ?? 0.0).toStringAsFixed(1)}',
          icon: Icons.star_rounded,
          color: AppTheme.accentColor,
        ),
        _MetricCard(
          label: 'Profile Views',
          value: '${stats['profile_views'] ?? 0}',
          icon: Icons.visibility_rounded,
          color: Colors.purpleAccent,
        ),
      ],
    );
  }

  Widget _buildEarningsChart() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.navySurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Weekly Growth',
                  style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary)),
              const Icon(Icons.trending_up, color: AppTheme.successColor, size: 20),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 100,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(days[value.toInt() % 7], 
                            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
                        );
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: [
                  _makeBar(0, 45),
                  _makeBar(1, 60),
                  _makeBar(2, 35),
                  _makeBar(3, 80),
                  _makeBar(4, 55),
                  _makeBar(5, 90),
                  _makeBar(6, 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDemandMapButton() {
    return GestureDetector(
      onTap: () => Navigator.push(
          context, MaterialPageRoute(builder: (_) => const DemandMapScreen())),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(24),
          boxShadow: AppTheme.glowShadow(AppTheme.primaryColor),
        ),
        child: Row(
          children: [
            const Icon(Icons.map_rounded, color: Colors.white, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Demand Heatmap',
                      style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white)),
                  Text('Find high-demand zones near you',
                      style: GoogleFonts.inter(
                          fontSize: 12, color: Colors.white.withOpacity(0.8))),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white),
          ],
        ),
      ),
    );
  }

  BarChartGroupData _makeBar(int x, double y) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          gradient: AppTheme.primaryGradient,
          width: 14,
          borderRadius: BorderRadius.circular(4),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: 100,
            color: AppTheme.navyMid.withOpacity(0.3),
          ),
        ),
      ],
    );
  }

  Widget _buildPerformanceSection(Map<String, dynamic> stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Engagement Highlights',
            style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary)),
        const SizedBox(height: 16),
        _buildDemandMapButton(),
        const SizedBox(height: 16),
        _InsightPill(
          icon: Icons.speed_rounded,
          title: 'Conversion Rate',
          value: '12% higher than average',
          color: AppTheme.successColor,
        ),
        const SizedBox(height: 12),
        _InsightPill(
          icon: Icons.timer_rounded,
          title: 'Response Time',
          value: 'Under 15 mins (Fast)',
          color: AppTheme.accentColor,
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _MetricCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.navySurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const Spacer(),
          Text(value, 
              style: GoogleFonts.inter(
                  fontSize: 20, 
                  fontWeight: FontWeight.w800, 
                  color: AppTheme.textPrimary)),
          const SizedBox(height: 2),
          Text(label, 
              style: GoogleFonts.inter(
                  fontSize: 11, 
                  color: AppTheme.textSecondary)),
        ],
      ),
    );
  }
}

class _InsightPill extends StatelessWidget {
  final IconData icon;
  final String title, value;
  final Color color;
  const _InsightPill({required this.icon, required this.title, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.navySurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, 
                    style: GoogleFonts.inter(
                        fontSize: 14, 
                        fontWeight: FontWeight.w600, 
                        color: AppTheme.textPrimary)),
                Text(value, 
                    style: GoogleFonts.inter(
                        fontSize: 12, 
                        color: AppTheme.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
