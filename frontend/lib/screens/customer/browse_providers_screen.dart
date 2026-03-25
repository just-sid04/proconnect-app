import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/provider_provider.dart';
import '../../utils/theme.dart';
import 'provider_details_screen.dart';

class BrowseProvidersScreen extends StatefulWidget {
  const BrowseProvidersScreen({super.key});
  @override
  State<BrowseProvidersScreen> createState() => _BrowseProvidersScreenState();
}

class _BrowseProvidersScreenState extends State<BrowseProvidersScreen> {
  final _searchController = TextEditingController();
  String? _selectedCategory;
  bool _showVerifiedOnly = false;
  double? _minRating;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      if (mounted) setState(() {});
    });
    final pp = Provider.of<ProviderProvider>(context, listen: false);
    if (pp.selectedCategory != null)
      _selectedCategory = pp.selectedCategory!.id;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (pp.categories.isEmpty) await pp.loadCategories();
      _load();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load({bool refresh = false}) async {
    final pp = Provider.of<ProviderProvider>(context, listen: false);
    await pp.loadProviders(
      category: _selectedCategory ?? pp.selectedCategory?.id,
      verified: _showVerifiedOnly,
      minRating: _minRating,
      search: _searchController.text.isNotEmpty ? _searchController.text : null,
      refresh: refresh,
    );
  }

  @override
  Widget build(BuildContext context) {
    final pp = Provider.of<ProviderProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.navyMid,
      body: SafeArea(
        child: Column(children: [
          // ── Top bar ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(children: [
              Expanded(
                child: Text('Browse Providers',
                    style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary)),
              ),
              _IconBtn(
                icon: Icons.tune_rounded,
                onTap: _showFilterSheet,
                badge: _showVerifiedOnly || _minRating != null,
              ),
            ]),
          ),

          // ── Search bar ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.navySurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.dividerColor),
              ),
              child: TextField(
                controller: _searchController,
                style: GoogleFonts.inter(
                    color: AppTheme.textPrimary, fontSize: 14),
                onSubmitted: (_) => _load(refresh: true),
                decoration: InputDecoration(
                  hintText: 'Search providers, skills...',
                  hintStyle: GoogleFonts.inter(color: AppTheme.textHint),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  prefixIcon: const Icon(Icons.search_rounded,
                      color: AppTheme.textSecondary),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded,
                              color: AppTheme.textSecondary, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            _load(refresh: true);
                          })
                      : null,
                ),
              ),
            ),
          ),

          // ── Category filter pills ─────────────────────────────────────────
          SizedBox(
            height: 52,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(20, 12, 8, 4),
              itemCount: pp.categories.length + 1,
              itemBuilder: (_, i) {
                if (i == 0) {
                  return _FilterPill(
                    label: 'All',
                    selected: _selectedCategory == null,
                    onTap: () {
                      pp.setSelectedCategory(null);
                      setState(() => _selectedCategory = null);
                      _load(refresh: true);
                    },
                  );
                }
                final cat = pp.categories[i - 1];
                return _FilterPill(
                  label: cat.name,
                  selected: _selectedCategory == cat.id,
                  onTap: () {
                    pp.setSelectedCategory(
                        _selectedCategory == cat.id ? null : cat);
                    setState(() => _selectedCategory =
                        _selectedCategory == cat.id ? null : cat.id);
                    _load(refresh: true);
                  },
                );
              },
            ),
          ),

          // ── Provider list ─────────────────────────────────────────────────
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _load(refresh: true),
              color: AppTheme.accentColor,
              backgroundColor: AppTheme.navySurface,
              child: pp.isLoading && pp.providers.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppTheme.primaryColor))
                  : pp.providers.isEmpty
                      ? _buildEmpty()
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                          itemCount: pp.providers.length + (pp.hasMore ? 1 : 0),
                          itemBuilder: (_, i) {
                            if (i == pp.providers.length) {
                              _load();
                              return const Padding(
                                padding: EdgeInsets.all(20),
                                child: Center(
                                    child: CircularProgressIndicator(
                                        color: AppTheme.primaryColor)),
                              );
                            }
                            final prov = pp.providers[i];
                            return ProviderListCard(
                              provider: prov,
                              onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => ProviderDetailsScreen(
                                          providerId: prov.id))),
                            );
                          },
                        ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildEmpty() => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.search_off_rounded,
              size: 72, color: AppTheme.textHint),
          const SizedBox(height: 16),
          Text('No providers found',
              style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary)),
          const SizedBox(height: 8),
          Text('Try adjusting your filters',
              style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textHint)),
        ]),
      );

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.navySurface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                    child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: AppTheme.dividerColor,
                      borderRadius: BorderRadius.circular(2)),
                )),
                const SizedBox(height: 20),
                Text('Filter Providers',
                    style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary)),
                const SizedBox(height: 20),
                // Verified toggle
                GestureDetector(
                  onTap: () => setSheetState(
                      () => _showVerifiedOnly = !_showVerifiedOnly),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _showVerifiedOnly
                          ? AppTheme.successColor.withAlpha(25)
                          : AppTheme.navyElevated,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _showVerifiedOnly
                            ? AppTheme.successColor
                            : AppTheme.dividerColor,
                        width: 1.5,
                      ),
                    ),
                    child: Row(children: [
                      Icon(Icons.verified_rounded,
                          color: _showVerifiedOnly
                              ? AppTheme.successColor
                              : AppTheme.textSecondary),
                      const SizedBox(width: 12),
                      Text('Verified providers only',
                          style: GoogleFonts.inter(
                              color: _showVerifiedOnly
                                  ? AppTheme.successColor
                                  : AppTheme.textPrimary,
                              fontWeight: FontWeight.w600)),
                      const Spacer(),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: _showVerifiedOnly
                              ? AppTheme.successColor
                              : AppTheme.navySurface,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: _showVerifiedOnly
                                  ? AppTheme.successColor
                                  : AppTheme.dividerColor),
                        ),
                        child: _showVerifiedOnly
                            ? const Icon(Icons.check,
                                size: 14, color: Colors.white)
                            : null,
                      ),
                    ]),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                    'Minimum Rating: ${_minRating?.toStringAsFixed(0) ?? 'Any'}',
                    style: GoogleFonts.inter(
                        color: AppTheme.textSecondary, fontSize: 13)),
                SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: AppTheme.accentColor,
                    thumbColor: AppTheme.accentColor,
                    inactiveTrackColor: AppTheme.navyElevated,
                    overlayColor: AppTheme.accentColor.withAlpha(30),
                  ),
                  child: Slider(
                    value: _minRating ?? 0,
                    min: 0,
                    max: 5,
                    divisions: 5,
                    label: _minRating?.toString() ?? 'Any',
                    onChanged: (v) =>
                        setSheetState(() => _minRating = v > 0 ? v : null),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _load(refresh: true);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text('Apply Filters',
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                ),
              ]),
        ),
      ),
    );
  }
}

// ─── Provider List Card ───────────────────────────────────────────────────────

class ProviderListCard extends StatefulWidget {
  final dynamic provider;
  final VoidCallback onTap;
  const ProviderListCard(
      {super.key, required this.provider, required this.onTap});
  @override
  State<ProviderListCard> createState() => _ProviderListCardState();
}

class _ProviderListCardState extends State<ProviderListCard> {
  bool _pressed = false;
  @override
  Widget build(BuildContext context) {
    final p = widget.provider;
    final hasPhoto = (p.profileImage as String).isNotEmpty;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.navySurface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.dividerColor, width: 1),
            boxShadow: AppTheme.cardShadow,
          ),
          child: Row(children: [
            // Avatar
            Stack(children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppTheme.primaryGradient,
                  border: Border.all(color: AppTheme.accentColor, width: 2),
                ),
                child: hasPhoto
                    ? ClipOval(
                        child: Image.network(p.profileImage, fit: BoxFit.cover))
                    : Center(
                        child: Text(
                        (p.displayName as String).isNotEmpty
                            ? (p.displayName as String)[0].toUpperCase()
                            : 'P',
                        style: GoogleFonts.inter(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Colors.white),
                      )),
              ),
              if (p.isVerified == true)
                Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: AppTheme.successColor,
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: AppTheme.navySurface, width: 2),
                      ),
                      child: const Icon(Icons.check,
                          size: 10, color: Colors.white),
                    )),
            ]),
            const SizedBox(width: 14),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Row(children: [
                    Expanded(
                        child: Text(p.displayName ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary))),
                    if (p.isVerified == true)
                      const Icon(Icons.verified_rounded,
                          color: AppTheme.primaryColor, size: 16),
                  ]),
                  const SizedBox(height: 3),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withAlpha(30),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(p.category?.name ?? 'Service',
                        style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryColor)),
                  ),
                  const SizedBox(height: 8),
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.accentColor.withAlpha(30),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(children: [
                        const Icon(Icons.star_rounded,
                            size: 13, color: AppTheme.accentColor),
                        const SizedBox(width: 3),
                        Text('${p.rating}',
                            style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.accentColor)),
                      ]),
                    ),
                    const SizedBox(width: 10),
                    Text('₹${(p.hourlyRate as double).toStringAsFixed(0)}/hr',
                        style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary)),
                    const Spacer(),
                  ]),
                  if ((p.skills as List).isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: (p.skills as List)
                          .take(3)
                          .map<Widget>((s) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppTheme.navyElevated,
                                  borderRadius: BorderRadius.circular(20),
                                  border:
                                      Border.all(color: AppTheme.dividerColor),
                                ),
                                child: Text(s.toString(),
                                    style: GoogleFonts.inter(
                                        fontSize: 10,
                                        color: AppTheme.textSecondary)),
                              ))
                          .toList(),
                    ),
                  ],
                ])),
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withAlpha(30),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.chevron_right_rounded,
                  color: AppTheme.primaryColor, size: 20),
            ),
          ]),
        ),
      ),
    );
  }
}

// ─── Small helpers ────────────────────────────────────────────────────────────

class _FilterPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterPill(
      {required this.label, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
          decoration: BoxDecoration(
            gradient: selected ? AppTheme.primaryGradient : null,
            color: selected ? null : AppTheme.navySurface,
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
                color: selected ? Colors.transparent : AppTheme.dividerColor,
                width: 1),
            boxShadow: selected
                ? AppTheme.glowShadow(AppTheme.primaryColor, blur: 10)
                : [],
          ),
          child: Text(label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppTheme.textSecondary,
              )),
        ),
      );
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool badge;
  const _IconBtn({required this.icon, required this.onTap, this.badge = false});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Stack(children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppTheme.navySurface,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: AppTheme.dividerColor),
            ),
            child: Icon(icon, color: AppTheme.textPrimary, size: 20),
          ),
          if (badge)
            Positioned(
                top: 6,
                right: 6,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                      color: AppTheme.accentColor, shape: BoxShape.circle),
                )),
        ]),
      );
}
