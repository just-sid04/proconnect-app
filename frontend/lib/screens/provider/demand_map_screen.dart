import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/analytics_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/theme.dart';

class DemandMapScreen extends StatefulWidget {
  const DemandMapScreen({super.key});

  @override
  State<DemandMapScreen> createState() => _DemandMapScreenState();
}

class _DemandMapScreenState extends State<DemandMapScreen> {
  final MapController _mapController = MapController();
  List<Map<String, dynamic>> _heatmapData = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadHeatmap());
  }

  Future<void> _loadHeatmap() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final bounds = _mapController.camera.visibleBounds;
      final analytics = context.read<AnalyticsProvider>();
      
      final data = await analytics.getHeatmapData(
        minLat: bounds.southWest.latitude,
        maxLat: bounds.northEast.latitude,
        minLng: bounds.southWest.longitude,
        maxLng: bounds.northEast.longitude,
      );

      setState(() => _heatmapData = data);
    } catch (e) {
      debugPrint('Heatmap Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final userPos = LatLng(
      auth.user?.location?.latitude ?? 19.0760,
      auth.user?.location?.longitude ?? 72.8777,
    );

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Demand Heatmap', 
          style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
        backgroundColor: Colors.white.withOpacity(0.9),
        elevation: 0,
        leading: const BackButton(color: AppTheme.navyDeep),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(right: 16.0),
                child: SizedBox(width: 20, height: 20, 
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryColor)),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.navyDeep),
            onPressed: _loadHeatmap,
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: userPos,
              initialZoom: 13,
              onPositionChanged: (pos, hasGesture) {
                if (!hasGesture) return;
                // Debounce or just load on stop? Let's just provide a button and load on initial
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.proconnect.app',
              ),
              // Heatmap Layer (Circles)
              CircleLayer(
                circles: _heatmapData.map((d) {
                  final intensity = (d['intensity'] as num).toDouble();
                  final color = intensity > 0.7 
                      ? Colors.red.withOpacity(0.5) 
                      : intensity > 0.4 
                          ? Colors.orange.withOpacity(0.4) 
                          : Colors.yellow.withOpacity(0.3);
                  
                  return CircleMarker(
                    point: LatLng(d['lat'], d['lng']),
                    radius: 100, // 100 meters fixed approx
                    useRadiusInMeter: true,
                    color: color,
                    borderColor: color.withOpacity(0.8),
                    borderStrokeWidth: 1,
                  );
                }).toList(),
              ),
              // Current Location Marker
              MarkerLayer(
                markers: [
                  Marker(
                    point: userPos,
                    width: 40,
                    height: 40,
                    child: const Icon(Icons.my_location, color: AppTheme.primaryColor, size: 30),
                  ),
                ],
              ),
            ],
          ),
          
          // Legend
          Positioned(
            bottom: 40,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Demand Intensity', 
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 12)),
                  const SizedBox(height: 12),
                  _buildLegendRow('High Demand', Colors.red),
                  const SizedBox(height: 8),
                  _buildLegendRow('Medium Demand', Colors.orange),
                  const SizedBox(height: 8),
                  _buildLegendRow('Emerging', Colors.yellow),
                ],
              ),
            ),
          ),

          // Tip
          Positioned(
            top: 100,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.navyDeep.withOpacity(0.8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb_outline, color: AppTheme.accentColor, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Move to High Demand zones to increase your booking chances by up to 40%.',
                      style: GoogleFonts.inter(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendRow(String label, Color color) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color.withOpacity(0.6), shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(label, style: GoogleFonts.inter(fontSize: 11, color: AppTheme.navyDeep)),
      ],
    );
  }
}
