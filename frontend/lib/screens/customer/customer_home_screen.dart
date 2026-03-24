import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/provider_provider.dart';
import '../../utils/theme.dart';
import 'booking_details_screen.dart';
import 'browse_providers_screen.dart';
import 'my_bookings_screen.dart';
import 'profile_screen.dart';
import 'provider_details_screen.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeTab(
        openBrowse: () => setState(() => _currentIndex = 1),
        openBookings: () => setState(() => _currentIndex = 2),
      ),
      const BrowseProvidersScreen(),
      const MyBookingsScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search_outlined),
            activeIcon: Icon(Icons.search),
            label: 'Browse',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined),
            activeIcon: Icon(Icons.calendar_today),
            label: 'Bookings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class HomeTab extends StatefulWidget {
  final VoidCallback openBrowse;
  final VoidCallback openBookings;

  const HomeTab({
    super.key,
    required this.openBrowse,
    required this.openBookings,
  });

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final providerProvider = Provider.of<ProviderProvider>(context, listen: false);
    final bookingProvider = Provider.of<BookingProvider>(context, listen: false);

    if (providerProvider.categories.isEmpty) {
      await providerProvider.loadCategories();
    }

    await providerProvider.loadProviders(refresh: true);
    await bookingProvider.loadBookings(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final providerProvider = Provider.of<ProviderProvider>(context);
    final bookingProvider = Provider.of<BookingProvider>(context);
    final featuredProviders = providerProvider.providers.take(5).toList();
    final activeBookings = bookingProvider.activeBookings.take(3).toList();

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Welcome back,',
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        authProvider.user?.name ?? 'Guest',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                CircleAvatar(
                  radius: 28,
                  backgroundImage: (authProvider.user?.profilePhoto?.isNotEmpty ?? false)
                      ? NetworkImage(authProvider.user!.profilePhoto!)
                      : null,
                  child: !(authProvider.user?.profilePhoto?.isNotEmpty ?? false)
                      ? const Icon(Icons.person)
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 24),
            InkWell(
              onTap: widget.openBrowse,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.dividerColor),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.search, color: AppTheme.textSecondary),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Search for services...',
                        style: TextStyle(color: AppTheme.textHint),
                      ),
                    ),
                    Icon(Icons.tune, color: AppTheme.textSecondary),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'Categories',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 108,
              child: providerProvider.isLoading && providerProvider.categories.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: providerProvider.categories.length,
                      itemBuilder: (context, index) {
                        final category = providerProvider.categories[index];
                        return _CategoryCard(
                          category: category,
                          onTap: () {
                            providerProvider.setSelectedCategory(category);
                            widget.openBrowse();
                          },
                        );
                      },
                    ),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Active Bookings',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                TextButton(
                  onPressed: widget.openBookings,
                  child: const Text('See All'),
                ),
              ],
            ),
            if (activeBookings.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No active bookings right now.'),
                ),
              )
            else
              ...activeBookings.map(
                (booking) => Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: booking.statusColor.withOpacity(0.1),
                      child: Icon(Icons.calendar_today, color: booking.statusColor),
                    ),
                    title: Text(
                      booking.provider?.displayName ?? 'Unknown Provider',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      '${booking.scheduledDate} at ${booking.scheduledTime}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Text(
                      booking.statusDisplay,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: booking.statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BookingDetailsScreen(bookingId: booking.id),
                        ),
                      );
                    },
                  ),
                ),
              ),
            const SizedBox(height: 28),
            const Text(
              'Top Rated Providers',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (featuredProviders.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No providers available yet.'),
                ),
              )
            else
              SizedBox(
                height: 220,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: featuredProviders.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final provider = featuredProviders[index];
                    return _ProviderCard(
                      provider: provider,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProviderDetailsScreen(providerId: provider.id),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final dynamic category;
  final VoidCallback onTap;

  const _CategoryCard({required this.category, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 92,
        margin: const EdgeInsets.only(right: 10),
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Color(int.parse(category.color.replaceFirst('#', '0xFF'))),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(_iconForCategory(category.icon), color: Colors.white, size: 30),
            ),
            const SizedBox(height: 8),
            Text(
              category.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconForCategory(String icon) {
    switch (icon) {
      case 'electrical':
        return Icons.electrical_services;
      case 'plumbing':
        return Icons.water_damage;
      case 'appliance':
        return Icons.kitchen;
      case 'computer':
        return Icons.computer;
      case 'maintenance':
        return Icons.home_repair_service;
      case 'tutoring':
        return Icons.school;
      case 'beauty':
        return Icons.spa;
      case 'automotive':
        return Icons.directions_car;
      default:
        return Icons.handyman;
    }
  }
}

class _ProviderCard extends StatelessWidget {
  final dynamic provider;
  final VoidCallback onTap;

  const _ProviderCard({required this.provider, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 170,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 88,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Center(
                child: CircleAvatar(
                  radius: 30,
                  backgroundImage: provider.profileImage.isNotEmpty
                      ? NetworkImage(provider.profileImage)
                      : null,
                  child: provider.profileImage.isEmpty
                      ? const Icon(Icons.person, size: 30)
                      : null,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    provider.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    provider.category?.name ?? 'Service Provider',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 16, color: AppTheme.accentColor),
                      const SizedBox(width: 4),
                      Text(provider.rating.toStringAsFixed(1)),
                      const SizedBox(width: 8),
                      Text(
                        '\$${provider.hourlyRate.toStringAsFixed(0)}/hr',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
