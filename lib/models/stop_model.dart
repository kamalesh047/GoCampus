class StopModel {
  final String id;
  final String stopName;
  final double latitude;
  final double longitude;
  final String routeId;
  final int stopOrder;

  StopModel({
    required this.id,
    required this.stopName,
    required this.latitude,
    required this.longitude,
    required this.routeId,
    required this.stopOrder,
  });

  factory StopModel.fromMap(Map<String, dynamic> data, String id) {
    return StopModel(
      id: id,
      stopName: data['stopName'] ?? '',
      latitude: (data['latitude'] ?? 0.0).toDouble(),
      longitude: (data['longitude'] ?? 0.0).toDouble(),
      routeId: data['routeId'] ?? '',
      stopOrder: data['stopOrder'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'stopName': stopName,
      'latitude': latitude,
      'longitude': longitude,
      'routeId': routeId,
      'stopOrder': stopOrder,
    };
  }
}
