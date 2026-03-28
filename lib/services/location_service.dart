import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LocationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<Position>? _positionStream;
  bool _isTracking = false;

  bool get isTracking => _isTracking;

  // Requests permissions and gets current location (useful for SOS features)
  Future<Position?> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }

    if (permission == LocationPermission.deniedForever) return null;

    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.bestForNavigation),
    );
  }

  // Requests permissions and starts streaming coordinates with Foreground Locks
  Future<void> startTrackingToFirestore(String busId) async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw Exception("GPS hardware is disabled. Please activate.");

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) throw Exception("Location permission required for telemetry.");
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception("Permanent permission denial. Go to Settings to allow Active Tracking.");
    }

    _isTracking = true;

    late LocationSettings locationSettings;
    
    if (defaultTargetPlatform == TargetPlatform.android) {
      locationSettings = AndroidSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 10,
        intervalDuration: const Duration(seconds: 4),
        // HARD BOUND to OS Kernel ensuring process doesn't die while driving
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationText: "Broadcasting GoCampus Bus Coordinates in Background...",
          notificationTitle: "Active Transit Tracking",
          enableWakeLock: true,
        ),
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS) {
      locationSettings = AppleSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 10,
        pauseLocationUpdatesAutomatically: false,
        activityType: ActivityType.automotiveNavigation,
      );
    } else {
      locationSettings = const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 10,
      );
    }
    
    Position? lastValidPosition;

    _positionStream = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) {
      
      double speedKph = position.speed * 3.6;

      // 1. Structural Filter Map Data Jumps or impossibilities
      if (speedKph > 160) return; // Impossible bus velocity filter
      
      // Prevent wild geographical bounds jumps
      if (lastValidPosition != null) {
          double jumpDist = Geolocator.distanceBetween(
              lastValidPosition!.latitude, lastValidPosition!.longitude,
              position.latitude, position.longitude
          );
          if (jumpDist > 1000) return; // Reject unphysical jumps completely
      }
      
      lastValidPosition = position;

      // 2. Transmit cleanly without blocking stream pipeline
      _firestore.collection('buses').doc(busId).update({
        'latitude': position.latitude,
        'longitude': position.longitude,
        'speed': speedKph,
        'status': 'active',
      }).catchError((e) {
        // Log telemetry dropped securely, don't crash
        debugPrint("Telemetry dropped: $e");
      });
    }, onError: (e) {
       _isTracking = false;
       throw Exception("Satellite hardware pipeline failed: $e");
    });
  }

  void stopTracking(String busId) {
    _positionStream?.cancel();
    _isTracking = false;
    
    _firestore.collection('buses').doc(busId).update({
      'status': 'inactive',
      'speed': 0,
    }).catchError((e) { /* Error stopping cleanly */ });
  }
}
