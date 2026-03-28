import 'package:cloud_firestore/cloud_firestore.dart';

class SosAlertModel {
  final String id;
  final String studentId;
  final String studentName;
  final double latitude;
  final double longitude;
  final bool resolved;
  final DateTime timestamp;

  SosAlertModel({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.latitude,
    required this.longitude,
    required this.resolved,
    required this.timestamp,
  });

  factory SosAlertModel.fromMap(Map<String, dynamic> data, String id) {
    return SosAlertModel(
      id: id,
      studentId: data['studentId'] ?? '',
      studentName: data['studentName'] ?? '',
      latitude: (data['latitude'] ?? 0.0).toDouble(),
      longitude: (data['longitude'] ?? 0.0).toDouble(),
      resolved: data['resolved'] ?? false,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'latitude': latitude,
      'longitude': longitude,
      'resolved': resolved,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}
