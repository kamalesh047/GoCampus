import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    // 1. Request iOS / Android 13+ Permissions
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus != AuthorizationStatus.authorized) {
      return;
    }

    // 2. Initialize Local Notifications (For foreground display)
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    await _localNotifications.initialize(
      settings: const InitializationSettings(android: androidSettings),
    );

    // 3. Listen to Foreground Messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        _showLocalNotification(
          message.notification!.title ?? 'GoCampus',
          message.notification!.body ?? '',
        );
      }
    });
  }

  // Subscribe to topics (e.g., student subscribes to their "busId" topic)
  Future<void> subscribeToBusTopic(String busId) async {
    await _fcm.subscribeToTopic('bus_$busId');
  }

  // Unsubscribe (e.g., when route changes)
  Future<void> unsubscribeFromBusTopic(String busId) async {
    await _fcm.unsubscribeFromTopic('bus_$busId');
  }

  // Show Android Notification safely
  Future<void> _showLocalNotification(String title, String body) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'gocampus_alerts', // Channel ID
          'GoCampus Alerts', // Channel Name
          channelDescription: 'Important bus transit announcements',
          importance: Importance.max,
          priority: Priority.high,
          color: Colors.blueAccent,
        );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidDetails,
    );

    await _localNotifications.show(
      id: DateTime.now().millisecond,
      title: title,
      body: body,
      notificationDetails: platformChannelSpecifics,
    );
  }

  // ----- DATABASE TRIGGERS (In a production env, these would be Firebase Cloud Functions) -----
  // These helpers simulate pushing an FCM notification by logging it into the 'notifications' collection.

  static Future<void> pushTripStarted(String busId, String routeName) async {
    await FirebaseFirestore.instance.collection('notifications').add({
      'title': 'Bus Departing! 🚌',
      'body': 'Your bus for $routeName has started its trip.',
      'targetBusId': busId,
      'targetRole': 'student',
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> push10MinWarning(String busId) async {
    await FirebaseFirestore.instance.collection('notifications').add({
      'title': 'Bus Nearby! ⏳',
      'body': 'Your bus will arrive at your stop in approx. 10 minutes.',
      'targetBusId': busId,
      'targetRole': 'student',
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> pushArrivedAtStop(String busId, String stopName) async {
    await FirebaseFirestore.instance.collection('notifications').add({
      'title': 'Bus Arrived! 🛑',
      'body': 'The bus has arrived at $stopName.',
      'targetBusId': busId,
      'targetRole': 'student',
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> pushAdminAnnouncement(String message) async {
    await FirebaseFirestore.instance.collection('notifications').add({
      'title': 'College Announcement 📢',
      'body': message,
      'targetRole': 'all',
      'targetBusId': null,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> pushSOSAlert(String studentName, String busId) async {
    // Dispatch to Admins
    await FirebaseFirestore.instance.collection('notifications').add({
      'title': '🚨 SOS EMERGENCY TRIGGERED 🚨',
      'body': '$studentName from Bus $busId pressed the SOS button!',
      'targetRole': 'admin',
      'targetBusId': null,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Dispatch to Transport Incharge
    await FirebaseFirestore.instance.collection('notifications').add({
      'title': '🚨 SOS EMERGENCY TRIGGERED 🚨',
      'body': '$studentName from Bus $busId pressed the SOS button!',
      'targetRole': 'incharge',
      'targetBusId': null,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}
