import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/bus_model.dart';
import '../models/route_model.dart';
import '../models/stop_model.dart';
import '../models/trip_model.dart';
import '../models/attendance_model.dart';
import '../models/notification_model.dart';
import '../models/sos_alert_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- BUSES ---
  Stream<BusModel> streamBus(String busId) {
    return _db.collection('buses').doc(busId).snapshots().map((doc) {
      if (!doc.exists) throw Exception("Bus tracking configuration missing or damaged.");
      return BusModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    });
  }

  // --- ROUTES & STOPS ---
  Future<RouteModel?> getRoute(String routeId) async {
    try {
      var doc = await _db.collection('routes').doc(routeId).get();
      if (doc.exists) {
        return RouteModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception("Infrastructure Error: Failed to retrieve designated route bounds.");
    }
  }

  Stream<List<StopModel>> streamStopsForRoute(String routeId) {
    return _db
        .collection('stops')
        .where('routeId', isEqualTo: routeId)
        .orderBy('stopOrder')
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => StopModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  // --- TRIPS ---
  Future<void> startTrip(TripModel trip) async {
    try {
      // Execute strict synchronous WriteBatch to bind tracking
      WriteBatch batch = _db.batch();
      batch.set(_db.collection('trips').doc(trip.id), trip.toMap());
      batch.update(_db.collection('buses').doc(trip.busId), {'activeTripId': trip.id});
      await batch.commit();
    } catch (e) {
      throw Exception("Network Sync Failure: Could not broadcast initial trip vectors.");
    }
  }

  Future<void> endTrip(String tripId, String busId) async {
    try {
      WriteBatch batch = _db.batch();
      batch.update(_db.collection('trips').doc(tripId), {'endTime': FieldValue.serverTimestamp()});
      batch.update(_db.collection('buses').doc(busId), {'activeTripId': FieldValue.delete()});
      await batch.commit();
    } catch (e) {
      throw Exception("Network Sync Failure: Secure terminus disconnection failed.");
    }
  }

  // --- ATTENDANCE ---
  Future<void> markAttendance(AttendanceModel attendance) async {
    try {
      await _db.collection('attendance').doc(attendance.id).set(attendance.toMap());
    } catch (e) {
      throw Exception("Data Error: Server rejected physical boarding confirmation string.");
    }
  }
  
  // High-performance driver boarding filter
  Stream<List<AttendanceModel>> streamActiveAttendance(String activeTripId) {
    return _db
        .collection('attendance')
        .where('tripId', isEqualTo: activeTripId)
        .where('status', isEqualTo: 'coming')
        .snapshots()
        .map((snap) => snap.docs.map((doc) => AttendanceModel.fromMap(doc.data(), doc.id)).toList());
  }

  // --- SOS ---
  Future<void> triggerSos(SosAlertModel alert) async {
    try {
      await _db.collection('sos_alerts').add(alert.toMap());
    } catch (e) {
      throw Exception("Critical: Administrative node unresponsive. Unable to transmit GPS SOS.");
    }
  }

  // --- NOTIFICATIONS ---
  Stream<List<NotificationModel>> streamNotifications(
    String role,
    String? busId,
  ) {
    return _db
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) {
          return snap.docs
              .map((doc) => NotificationModel.fromMap(doc.data(), doc.id))
              .where(
                (n) => n.targetRole == 'all' || n.targetRole == role || (n.targetBusId != null && n.targetBusId == busId),
              )
              .toList();
        });
  }
}
