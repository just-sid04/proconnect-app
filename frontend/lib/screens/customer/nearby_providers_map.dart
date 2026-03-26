import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/provider_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/theme.dart';
import '../../models/provider_model.dart';
import 'provider_details_screen.dart';

class NearbyProvidersMap extends StatefulWidget {
  const NearbyProvidersMap({super.key});

  @override
  State<NearbyProvidersMap> createState() => _NearbyProvidersMapState();
}

class _NearbyProvidersMapState extends State<NearbyProvidersMap> {
  final MapController _mapController = MapController();
  final _supabase = Supabase.instance.client;
  double _searchRadius = 10.0;
  bool _isInitialLoad = true;
  RealtimeChannel? _trackChannel;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initMap());
  }

  @override
  void dispose() {
    _trackChannel?.unsubscribe();
    super.dispose();
  }

  Future<void> _initMap() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final pp = Provider.of<ProviderProvider>(context, listen: false);

    // 1. Get user's location
    double lat = auth.user?.location?.latitude ?? 0;
    double lng = auth.user?.location?.longitude ?? 0;

    // Default to some location if user has none (e.g., center of Mumbai)
    if (lat == 0) lat = 19.0760;
    if (lng == 0) lng = 72.8777;

    _mapController.move(LatLng(lat, lng), 13);

    // 2. Load nearby providers
    await pp.loadNearbyProviders(
      latitude: lat,
      longitude: lng,
      radius: _searchRadius,
      refresh: true,
    );

    // 3. Subscribe to real-time updates for these providers
    _subscribeToProfiles();

    setState(() => _isInitialLoad = false);
  }

  void _subscribeToProfiles() {
    _trackChannel?.unsubscribe();
    
    // We listen to all profile changes for now, but we could filter by provider role
    _trackChannel = _supabase
        .channel('public:profiles')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'profiles',
          callback: (payload) {
            final pp = Provider.of<ProviderProvider>(context, listen: false);
            final updatedProfileId = payload.newRecord['id'];
            
            // Check if this profile is one of our displayed providers
            final index = pp.providers.indexWhere((p) => p.userId == updatedProfileId);
            if (index != -1) {
              // Update the provider's location in the list
              // In a real app, we might want a more efficient way to update markers
              // For now, we'll re-load or manually update the provider object
              pp.loadNearbyProviders(
                latitude: _mapController.camera.center.latitude,
                longitude: _mapController.camera.center.longitude,
                radius: _searchRadius,
                refresh: true,
              );
            }
          },
        )
        .subscribe();
  }

  @override
  Widget build(BuildContext context) {
    final pp = Provider.of<ProviderProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final userLat = auth.user?.location?.latitude ?? 19.0760;
    final userLng = auth.user?.location?.longitude ?? 72.8777;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Nearby Providers'),
        backgroundColor: Colors.white.withOpacity(0.9),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _initMap(),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: LatLng(userLat, userLng),
              initialZoom: 13,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.proconnect.app',
              ),
              // Nearby Providers Markers
              MarkerLayer(
                markers: pp.providers.map((p) {
                  final profile = p.user;
                  final lat = profile?.location?.latitude ?? 0;
                  final lng = profile?.location?.longitude ?? 0;
                  
                  return Marker(
                    point: LatLng(lat, lng),
                    width: 60,
                    height: 60,
                    child: GestureDetector(
                      onTap: () => _showProviderDetails(p),
                      child: _buildMarker(p),
                    ),
                  );
                }).toList(),
              ),
              // User Marker
              MarkerLayer(
                markers: [
                  Marker(
                    point: LatLng(userLat, userLng),
                    width: 40,
                    height: 40,
                    child: const Icon(Icons.person_pin_circle, color: Colors.blue, size: 40),
                  ),
                ],
              ),
            ],
          ),
          
          if (pp.isLoading && _isInitialLoad)
            const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),

          // Radius Slider
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Search Radius', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('${_searchRadius.toInt()} km'),
                    ],
                  ),
                  Slider(
                    value: _searchRadius,
                    min: 1,
                    max: 50,
                    divisions: 10,
                    onChanged: (val) {
                      setState(() => _searchRadius = val);
                    },
                    onChangeEnd: (val) => _initMap(),
                    activeColor: AppTheme.primaryColor,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarker(ServiceProvider p) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.primaryColor, width: 2),
            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
          ),
          child: CircleAvatar(
            radius: 18,
            backgroundImage: p.profileImage.isNotEmpty ? NetworkImage(p.profileImage) : null,
            child: p.profileImage.isEmpty ? Text(p.displayName[0]) : null,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            '₹${p.hourlyRate.toInt()}',
            style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  void _showProviderDetails(ServiceProvider p) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                ),
              ),
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: p.profileImage.isNotEmpty ? NetworkImage(p.profileImage) : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.displayName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        Text(p.category?.name ?? 'Provider', style: TextStyle(color: Colors.grey[600])),
                        Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 16),
                            Text(' ${p.rating} (${p.totalReviews})', style: const TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(width: 8),
                            if (p.distance != null)
                              Text('• ${(p.distance!).toStringAsFixed(1)} km away', style: const TextStyle(color: Colors.blue)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(p.description, maxLines: 3, overflow: TextOverflow.ellipsis),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProviderDetailsScreen(providerId: p.id))),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('View Profile & Book'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
