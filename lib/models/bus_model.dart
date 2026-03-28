

class BusModel {
  final String id;
  final String busNumber;
  final String driverId;
  final String routeId;
  final double latitude;
  final double longitude;
  final double speed;
  final String currentStop;
  final String nextStop;
  final int passengerCount;
  final String status;
  final String? activeTripId;

  BusModel({
    required this.id,
    required this.busNumber,
    required this.driverId,
    required this.routeId,
    required this.latitude,
    required this.longitude,
    required this.speed,
    required this.currentStop,
    required this.nextStop,
    required this.passengerCount,
    required this.status,
    this.activeTripId,
  });

  factory BusModel.fromMap(Map<String, dynamic> data, String id) {
    return BusModel(
      id: id,
      busNumber: data['busNumber'] ?? '',
      driverId: data['driverId'] ?? '',
      routeId: data['routeId'] ?? '',
      latitude: (data['latitude'] ?? 0.0).toDouble(),
      longitude: (data['longitude'] ?? 0.0).toDouble(),
      speed: (data['speed'] ?? 0.0).toDouble(),
      currentStop: data['currentStop'] ?? '',
      nextStop: data['nextStop'] ?? '',
      passengerCount: data['passengerCount'] ?? 0,
      status: data['status'] ?? 'inactive',
      activeTripId: data['activeTripId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'busNumber': busNumber,
      'driverId': driverId,
      'routeId': routeId,
      'latitude': latitude,
      'longitude': longitude,
      'speed': speed,
      'currentStop': currentStop,
      'nextStop': nextStop,
      'passengerCount': passengerCount,
      'status': status,
      'activeTripId': activeTripId,
    };
  }
}
