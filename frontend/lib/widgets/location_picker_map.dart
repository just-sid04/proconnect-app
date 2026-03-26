import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as geo;
import '../utils/theme.dart';

class LocationPickerMap extends StatefulWidget {
  final LatLng? initialLocation;
  final String? initialAddress;

  const LocationPickerMap({
    super.key,
    this.initialLocation,
    this.initialAddress,
  });

  @override
  State<LocationPickerMap> createState() => _LocationPickerMapState();
}

class _LocationPickerMapState extends State<LocationPickerMap> {
  late MapController _mapController;
  LatLng? _selectedLocation;
  String? _selectedAddress;
  bool _isLocating = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _selectedLocation = widget.initialLocation;
    _selectedAddress = widget.initialAddress;

    if (_selectedLocation == null) {
      _determinePosition();
    }
  }

  Future<void> _determinePosition() async {
    setState(() => _isLocating = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw 'Location services are disabled.';

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) throw 'Permission denied.';
      }

      Position position = await Geolocator.getCurrentPosition();
      final latLng = LatLng(position.latitude, position.longitude);
      
      setState(() {
        _selectedLocation = latLng;
        _isLocating = false;
      });
      
      _mapController.move(latLng, 15);
      _reverseGeocode(latLng);
    } catch (e) {
      setState(() => _isLocating = false);
      debugPrint('Error getting location: $e');
    }
  }

  Future<void> _reverseGeocode(LatLng location) async {
    try {
      List<geo.Placemark> placemarks = await geo.placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        setState(() {
          _selectedAddress = '${p.street}, ${p.subLocality}, ${p.locality}, ${p.postalCode}';
        });
      }
    } catch (e) {
      debugPrint('Error geocoding: $e');
    }
  }

  void _onTap(TapPosition tapPosition, LatLng point) {
    setState(() {
      _selectedLocation = point;
    });
    _reverseGeocode(point);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Location'),
        actions: [
          if (_selectedLocation != null)
            TextButton(
              onPressed: () => Navigator.pop(context, {
                'location': _selectedLocation,
                'address': _selectedAddress,
              }),
              child: const Text('CONFIRM', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _selectedLocation ?? const LatLng(0, 0),
              initialZoom: 15,
              onTap: _onTap,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.proconnect.app',
              ),
              if (_selectedLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _selectedLocation!,
                      width: 50,
                      height: 50,
                      child: const Icon(Icons.location_on, color: AppTheme.primaryColor, size: 40),
                    ),
                  ],
                ),
            ],
          ),
          
          // Current location button
          Positioned(
            bottom: 24,
            right: 16,
            child: FloatingActionButton(
              onPressed: _determinePosition,
              backgroundColor: AppTheme.primaryColor,
              child: _isLocating 
                ? const CircularProgressIndicator(color: Colors.white)
                : const Icon(Icons.my_location, color: Colors.white),
            ),
          ),

          // Address Overlay
          if (_selectedAddress != null)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, spreadRadius: 2)],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.map, color: AppTheme.secondaryColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _selectedAddress!,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
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
}
