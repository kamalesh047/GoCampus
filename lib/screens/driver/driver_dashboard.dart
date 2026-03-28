import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/location_service.dart';
import '../../models/bus_model.dart';
import '../../models/stop_model.dart';
import '../../models/trip_model.dart';
import '../../models/attendance_model.dart';

class DriverDashboard extends StatefulWidget {
  const DriverDashboard({super.key});

  @override
  State<DriverDashboard> createState() => _DriverDashboardState();
}

class _DriverDashboardState extends State<DriverDashboard> {
  final LocationService _locationService = LocationService();
  String? _activeTripId;
  bool _isLoading = false;

  void _startTrip(String busId, String driverId, String routeId) async {
    setState(() => _isLoading = true);
    try {
      final firestoreService = Provider.of<FirestoreService>(context, listen: false);

      // 1. Create a trip lifecycle document
      TripModel trip = TripModel(
        id: "TRIP_${DateTime.now().millisecondsSinceEpoch}",
        busId: busId,
        driverId: driverId,
        routeId: routeId,
        startTime: DateTime.now(),
        totalStudents: 0,
      );
      
      // 2. Transmit to server directly wrapped in batch
      await firestoreService.startTrip(trip);

      // 3. Instruct Location Service to awaken background OS constraints
      await _locationService.startTrackingToFirestore(busId);

      if (mounted) {
        setState(() {
          _activeTripId = trip.id;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Trip Started | GPS Telemetry Linked', style: TextStyle(fontWeight: FontWeight.bold)), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error initiating route: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _endTrip(String busId) async {
    setState(() => _isLoading = true);
    try {
      final firestoreService = Provider.of<FirestoreService>(context, listen: false);

      // 1. Shut off location stream
      _locationService.stopTracking(busId);

      // 2. Shut down trip doc if active
      if (_activeTripId != null) {
        await firestoreService.endTrip(_activeTripId!, busId);
      }

      if (mounted) {
        setState(() {
          _activeTripId = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Trip Terminated Safely', style: TextStyle(fontWeight: FontWeight.bold)), backgroundColor: Colors.blueAccent),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Terminate Exception: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    final user = Provider.of<AuthService>(context, listen: false).currentUserData;
    if (user?.busId != null) {
      _locationService.stopTracking(user!.busId!);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    final user = authService.currentUserData;

    if (user == null || user.busId == null || user.routeId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Driver Dashboard')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
               const Icon(Icons.departure_board, size: 60, color: Colors.grey),
               const SizedBox(height: 20),
               const Text("Administrative Data Error: No Assigned Route", style: TextStyle(fontWeight: FontWeight.bold)),
               const SizedBox(height: 20),
               OutlinedButton(onPressed: () => authService.signOut(), child: const Text("Logout"))
            ]
          )
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Driver Hub - Bus ${user.busId}'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              if (_locationService.isTracking) _locationService.stopTracking(user.busId!);
              authService.signOut();
            },
          )
        ],
      ),
      body: StreamBuilder<BusModel>(
        stream: firestoreService.streamBus(user.busId!),
        builder: (context, busSnapshot) {
          if (busSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.indigo));
          }

          if (busSnapshot.hasError || !busSnapshot.hasData) {
             return Center(
               child: Column(
                 mainAxisAlignment: MainAxisAlignment.center,
                 children: [
                   const Icon(Icons.cloud_off, size: 60, color: Colors.redAccent),
                   const SizedBox(height: 16),
                   Text("Server Connectivity Error:\n${busSnapshot.error ?? 'Unknown'}", textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
                 ],
               ),
             );
          }

          BusModel liveBus = busSnapshot.data!;
          
          // Cross-pollinate state locally gracefully
          if (liveBus.activeTripId != null && _activeTripId != liveBus.activeTripId) {
             WidgetsBinding.instance.addPostFrameCallback((_) {
                 if (mounted) setState(() => _activeTripId = liveBus.activeTripId);
             });
          } else if (liveBus.activeTripId == null && _activeTripId != null) {
             WidgetsBinding.instance.addPostFrameCallback((_) {
                 if (mounted) setState(() => _activeTripId = null);
             });
          }

          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Real-time State Monitors
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: _activeTripId != null ? Colors.indigo.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _activeTripId != null ? Colors.indigo : Colors.grey.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                     children: [
                       Column(
                         children: [
                           const Icon(Icons.speed, size: 40, color: Colors.orange),
                           const SizedBox(height: 8),
                           Text(liveBus.speed.toStringAsFixed(0), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                           const Text("KM/H", style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                         ],
                       ),
                       Container(width: 1, height: 80, color: Colors.grey.withValues(alpha: 0.3)),
                       
                       // Nested Stream binding total expected boardings live
                       StreamBuilder<List<AttendanceModel>>(
                          stream: _activeTripId != null ? firestoreService.streamActiveAttendance(_activeTripId!) : null,
                          builder: (context, attSnap) {
                             int attending = attSnap.data?.length ?? 0;
                             
                             return Column(
                               children: [
                                 Icon(Icons.people_alt, size: 40, color: attending > 0 ? Colors.green : Colors.blueGrey),
                                 const SizedBox(height: 8),
                                 Text("$attending", style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                                 const Text("CONFIRMED", style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                               ],
                             );
                          }
                       )
                     ],
                  ),
                ),
                const SizedBox(height: 24),

                // Next Stop Informational Feed
                StreamBuilder<List<StopModel>>(
                  stream: firestoreService.streamStopsForRoute(user.routeId!),
                  builder: (context, stopsSnap) {
                    if (stopsSnap.hasError) return const Center(child: Text("Route Integrity Compromised"));
                    
                    String nextStopName = "Awaiting Tracking";
                    if (stopsSnap.hasData && stopsSnap.data!.isNotEmpty) {
                      try {
                        nextStopName = stopsSnap.data!.firstWhere((s) => s.id == liveBus.nextStop).stopName;
                      } catch (e) {
                         // Default to first stop if nextStop is invalid or null
                        nextStopName = stopsSnap.data!.first.stopName;
                      }
                    }

                    return Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.blueAccent,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.near_me, color: Colors.white, size: 30),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("NEXT STOP (TARGET)", style: TextStyle(color: Colors.white70, fontSize: 12)),
                                Text(nextStopName, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const Spacer(),

                // Power Controls
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (_activeTripId == null)
                  ElevatedButton(
                    onPressed: () => _startTrip(user.busId!, user.uid, user.routeId!),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    child: const Text("START TRIP", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                  )
                else
                  ElevatedButton(
                    onPressed: () => _endTrip(user.busId!),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    child: const Text("TERMINATE TRIP", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                  ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }
}
