import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';

class LocationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<Position>? _positionStreamSubscription;

  /// Check and Request Permissions
  Future<bool> checkPermissions() async {
    bool serviceEnabled;
    LocationPermission permission;

    // 1. Check if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    // 2. Check for permissions
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  /// Get current location (one-time)
  Future<Position?> getCurrentLocation() async {
    final hasPermission = await checkPermissions();
    if (!hasPermission) return null;
    return await Geolocator.getCurrentPosition();
  }

  /// Start Safe-Walk (Location Sharing)
  Future<bool> startLocationSharing(String userId) async {
    final hasPermission = await checkPermissions();
    if (!hasPermission) {
      return false;
    }

    // Stop any existing stream
    await stopLocationSharing(userId);

    // iOS/Android specific settings for foreground service
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Update every 10 meters
    );

    try {
      _positionStreamSubscription =
          Geolocator.getPositionStream(
            locationSettings: locationSettings,
          ).listen(
            (Position position) {
              _updateUserLocation(userId, position);
            },
            onError: (e) {
              debugPrint("Location stream error: $e");
              stopLocationSharing(userId);
            },
          );

      // Update status to sharing
      await _firestore.collection('users').doc(userId).update({
        'isSharingLocation': true,
        'lastLocationUpdate': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      debugPrint("Error starting location sharing: $e");
      return false;
    }
  }

  /// Stop Safe-Walk
  Future<void> stopLocationSharing(String? userId) async {
    await _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;

    if (userId != null) {
      try {
        await _firestore.collection('users').doc(userId).update({
          'isSharingLocation': false,
        });
      } catch (e) {
        debugPrint("Error stopping location sharing: $e");
      }
    }
  }

  /// Update Firestore with new location
  Future<void> _updateUserLocation(String userId, Position position) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'currentLocation': {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'heading': position.heading,
          'speed': position.speed,
          'timestamp': FieldValue.serverTimestamp(),
          'sharing': true,
        },
        'lastLocationUpdate': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("Error updating location in Firestore: $e");
    }
  }

  Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }

  Future<bool> openAppSettings() async {
    return await Geolocator.openAppSettings();
  }
}
