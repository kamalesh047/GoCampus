import 'package:cloud_firestore/cloud_firestore.dart';

class TripModel {
  final String id;
  final String busId;
  final String driverId;
  final String routeId;
  final DateTime startTime;
  final DateTime? endTime;
  final int totalStudents;

  TripModel({
    required this.id,
    required this.busId,
    required this.driverId,
    required this.routeId,
    required this.startTime,
    this.endTime,
    required this.totalStudents,
  });

  factory TripModel.fromMap(Map<String, dynamic> data, String id) {
    return TripModel(
      id: id,
      busId: data['busId'] ?? '',
      driverId: data['driverId'] ?? '',
      routeId: data['routeId'] ?? '',
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: (data['endTime'] as Timestamp?)?.toDate(),
      totalStudents: data['totalStudents'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'busId': busId,
      'driverId': driverId,
      'routeId': routeId,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': endTime != null ? Timestamp.fromDate(endTime!) : null,
      'totalStudents': totalStudents,
    };
  }
}
