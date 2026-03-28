import 'package:geolocator/geolocator.dart';
import '../models/bus_model.dart';
import '../models/stop_model.dart';

class EtaResult {
  final int minutes;
  final String displayStatus;
  final double distance;

  EtaResult({
    required this.minutes,
    required this.displayStatus,
    required this.distance,
  });
}

class EtaService {
  /// Calculates ETA in minutes and provides a human-readable real-time status dynamically.
  static EtaResult calculateETA(
      BusModel? bus, StopModel? myStop, List<StopModel> routeStops) {
    
    if (bus == null || myStop == null || bus.status != 'active') {
      return EtaResult(minutes: -1, displayStatus: 'Offline', distance: 0);
    }

    // Dynamic Euclidean Distance Formula using native underlying geolocator math
    double distanceMeters = Geolocator.distanceBetween(
      bus.latitude,
      bus.longitude,
      myStop.latitude,
      myStop.longitude,
    );

    // 1. Check if Reached Stop (< 50 meters constraint)
    if (distanceMeters < 50) {
      return EtaResult(
          minutes: 0, displayStatus: 'Bus Reached 📍', distance: distanceMeters);
    }

    // 2. Traversal constraints (Check if bus departed stop)
    int busNextStopIndex = routeStops.indexWhere((s) => s.id == bus.nextStop);
    int myStopIndex = routeStops.indexWhere((s) => s.id == myStop.id);

    if (busNextStopIndex > myStopIndex &&
        myStopIndex != -1 &&
        busNextStopIndex != -1) {
      return EtaResult(
          minutes: 0, displayStatus: 'Bus Departed', distance: distanceMeters);
    }

    // 3. Extrapolate based on hardware sensor speed
    // If bus is standing still or moving slow, fallback to roughly 15 km/h to avoid huge ETAs
    double speedMs = bus.speed > 5 ? (bus.speed * 1000 / 3600) : 4.16;
    double travelSeconds = distanceMeters / speedMs;

    // 4. Incorporate stop node delays
    int remainingStops = 0;
    if (busNextStopIndex != -1 &&
        myStopIndex != -1 &&
        myStopIndex >= busNextStopIndex) {
      remainingStops = myStopIndex - busNextStopIndex;
    }

    double stopDelays = remainingStops * 60.0; // Assume 1 min idle per stop
    int totalMinutes = ((travelSeconds + stopDelays) / 60).ceil();

    if (totalMinutes <= 2) {
      return EtaResult(
          minutes: totalMinutes,
          displayStatus: 'Arriving! 🚌',
          distance: distanceMeters);
    }

    return EtaResult(
        minutes: totalMinutes,
        displayStatus: '$totalMinutes mins',
        distance: distanceMeters);
  }
}
