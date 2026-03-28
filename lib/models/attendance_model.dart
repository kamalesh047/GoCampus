import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceModel {
  final String id;
  final String studentId;
  final String tripId;
  final String status;
  final DateTime timestamp;

  AttendanceModel({
    required this.id,
    required this.studentId,
    required this.tripId,
    required this.status,
    required this.timestamp,
  });

  factory AttendanceModel.fromMap(Map<String, dynamic> data, String id) {
    return AttendanceModel(
      id: id,
      studentId: data['studentId'] ?? '',
      tripId: data['tripId'] ?? '',
      status: data['status'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'tripId': tripId,
      'status': status,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}
