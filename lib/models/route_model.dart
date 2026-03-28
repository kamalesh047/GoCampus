class RouteModel {
  final String id;
  final String routeName;
  final String busId;
  final List<String> stopIds;

  RouteModel({
    required this.id,
    required this.routeName,
    required this.busId,
    required this.stopIds,
  });

  factory RouteModel.fromMap(Map<String, dynamic> data, String id) {
    return RouteModel(
      id: id,
      routeName: data['routeName'] ?? '',
      busId: data['busId'] ?? '',
      stopIds: List<String>.from(data['stopIds'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'routeName': routeName,
      'busId': busId,
      'stopIds': stopIds,
    };
  }
}
