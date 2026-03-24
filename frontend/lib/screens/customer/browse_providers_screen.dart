import 'package:flutter/material.dart';
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
    final providerProvider = Provider.of<ProviderProvider>(context, listen: false);
    if (providerProvider.selectedCategory != null) {
      _selectedCategory = providerProvider.selectedCategory!.id;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (providerProvider.categories.isEmpty) {
        await providerProvider.loadCategories();
      }
      _loadProviders();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

    Future<void> _loadProviders({bool refresh = false}) async {
    final providerProvider = Provider.of<ProviderProvider>(context, listen: false);
    // Use local _selectedCategory if set, otherwise use provider's selected category
    final categoryToUse = _selectedCategory ?? providerProvider.selectedCategory?.id;
    await providerProvider.loadProviders(
      category: categoryToUse,
      verified: _showVerifiedOnly,
      minRating: _minRating,
      search: _searchController.text.isNotEmpty ? _searchController.text : null,
      refresh: refresh,
    );
  }

  @override
  Widget build(BuildContext context) {
    final providerProvider = Provider.of<ProviderProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Browse Providers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search providers...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _loadProviders(refresh: true);
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _loadProviders(refresh: true),
            ),
          ),
          // Category Filter Chips
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: providerProvider.categories.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: const Text('All'),
                      selected: _selectedCategory == null,
                      onSelected: (selected) {
                        providerProvider.setSelectedCategory(null);
                        setState(() {
                          _selectedCategory = null;
                        });
                        _loadProviders(refresh: true);
                      },
                    ),
                  );
                }
                final category = providerProvider.categories[index - 1];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(category.name),
                    selected: _selectedCategory == category.id,
                    onSelected: (selected) {
                      providerProvider.setSelectedCategory(selected ? category : null);
                      setState(() {
                        _selectedCategory = selected ? category.id : null;
                      });
                      _loadProviders(refresh: true);
                    },
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          // Providers List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _loadProviders(refresh: true),
              child: providerProvider.isLoading && providerProvider.providers.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : providerProvider.providers.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: providerProvider.providers.length +
                              (providerProvider.hasMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == providerProvider.providers.length) {
                              _loadProviders();
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }
                            final provider = providerProvider.providers[index];
                            return ProviderListCard(
                              provider: provider,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ProviderDetailsScreen(
                                      providerId: provider.id,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          const Text(
            'No providers found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Try adjusting your filters',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Filter Providers',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  CheckboxListTile(
                    title: const Text('Verified providers only'),
                    value: _showVerifiedOnly,
                    onChanged: (value) {
                      setState(() {
                        _showVerifiedOnly = value ?? false;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text('Minimum Rating'),
                  Slider(
                    value: _minRating ?? 0,
                    min: 0,
                    max: 5,
                    divisions: 5,
                    label: _minRating?.toString() ?? 'Any',
                    onChanged: (value) {
                      setState(() {
                        _minRating = value > 0 ? value : null;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _loadProviders(refresh: true);
                      },
                      child: const Text('Apply Filters'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class ProviderListCard extends StatelessWidget {
  final dynamic provider;
  final VoidCallback onTap;

  const ProviderListCard({
    super.key,
    required this.provider,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Profile Image
              CircleAvatar(
                radius: 35,
                backgroundImage: provider.profileImage.isNotEmpty
                    ? NetworkImage(provider.profileImage)
                    : null,
                child: provider.profileImage.isEmpty
                    ? const Icon(Icons.person, size: 35)
                    : null,
              ),
              const SizedBox(width: 16),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            provider.displayName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (provider.isVerified)
                          const Icon(
                            Icons.verified,
                            color: AppTheme.primaryColor,
                            size: 20,
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      provider.category?.name ?? 'Service Provider',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Rating and Price
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.accentColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star,
                                size: 14,
                                color: AppTheme.accentColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${provider.rating}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '\$${provider.hourlyRate}/hr',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Skills
                    Wrap(
                      spacing: 6,
                      children: provider.skills
                          .take(3)
                          .map<Widget>((skill) => Chip(
                                label: Text(
                                  skill,
                                  style: const TextStyle(fontSize: 10),
                                ),
                                padding: EdgeInsets.zero,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ))
                          .toList(),
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
