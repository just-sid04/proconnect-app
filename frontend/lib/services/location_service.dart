import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LocationService {
  static final LocationService instance = LocationService._Internal();
  LocationService._Internal();

  StreamSubscription<Position>? _positionStream;
  final _supabase = Supabase.instance.client;

  /// Request permissions and check if location services are enabled
  Future<bool> checkPermissions() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }

    if (permission == LocationPermission.deniedForever) return false;

    return true;
  }

  /// Get the current position of the device
  Future<Position?> getCurrentPosition() async {
    try {
      if (!await checkPermissions()) return null;
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      debugPrint('Error getting current position: $e');
      return null;
    }
  }

  /// Start tracking the device location and updating the Supabase profile
  Future<void> startTracking({required String userId, bool isProvider = false}) async {
    if (_positionStream != null) return;
    if (!await checkPermissions()) return;

    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 50, // Update every 50 meters
    );

    _positionStream = Geolocator.getPositionStream(locationSettings: locationSettings)
        .listen((Position position) async {
      debugPrint('Location Update: ${position.latitude}, ${position.longitude}');
      
      try {
        // Update the profile with the new coordinates
        // We update the public.profiles table which has latitude and longitude fields
        await _supabase.from('profiles').update({
          'latitude': position.latitude,
          'longitude': position.longitude,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', userId);
        
        debugPrint('Supabase Location Updated successfully');
      } catch (e) {
        debugPrint('Error updating location in Supabase: $e');
      }
    });
  }

  /// Stop tracking the device location
  void stopTracking() {
    _positionStream?.cancel();
    _positionStream = null;
  }

  /// Get the distance between two points in kilometers
  double getDistanceBetween(double startLat, double startLng, double endLat, double endLng) {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng) / 1000.0;
  }
}
