import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String title;
  final String body;
  final String targetRole;
  final String? targetBusId;
  final DateTime timestamp;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.targetRole,
    this.targetBusId,
    required this.timestamp,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> data, String id) {
    return NotificationModel(
      id: id,
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      targetRole: data['targetRole'] ?? 'all',
      targetBusId: data['targetBusId'],
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'body': body,
      'targetRole': targetRole,
      'targetBusId': targetBusId,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}
