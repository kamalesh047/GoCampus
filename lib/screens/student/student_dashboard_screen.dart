import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';

import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/map_service.dart';
import '../../services/location_service.dart';
import '../../services/notification_service.dart';
import '../../services/eta_service.dart';
import '../../models/bus_model.dart';
import '../../models/stop_model.dart';
import '../../models/attendance_model.dart';
import '../../models/sos_alert_model.dart';

// Helper class for animating LatLng natively without heavy 3rd-party dependencies
class LatLngTween extends Tween<LatLng> {
  LatLngTween({required LatLng begin, required LatLng end}) : super(begin: begin, end: end);

  @override
  LatLng lerp(double t) {
    return LatLng(
      begin!.latitude + (end!.latitude - begin!.latitude) * t,
      begin!.longitude + (end!.longitude - begin!.longitude) * t,
    );
  }
}

class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> with TickerProviderStateMixin, WidgetsBindingObserver {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  
  BusModel? _currentBus;
  List<StopModel> _routeStops = [];
  StopModel? _myStop;
  
  EtaResult? _etaResult;
  bool _isSosLoading = false;
  bool _hasSent10MinWarning = false;
  
  // Connections & Stability Streams
  StreamSubscription? _busSubscription;
  StreamSubscription? _stopsSubscription;
  Timer? _watchdogTimer;
  DateTime? _lastBusUpdate;
  String _connectionStatus = "Connecting...";
  
  // Smooth Marker Animation Variables
  AnimationController? _markerAnimController;
  Animation<LatLng>? _markerAnimation;
  LatLng? _oldBusPosition;
  LatLng? _currentBusRenderPosition;

  bool _isInitializing = true;
  String? _fatalErrorMsg;

  @override
  void initState() {
    super.initState();
    // 1-second map interpolation rendering constraint for buttery smoothness
    _markerAnimController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _markerAnimController!.addListener(() {
      if (_markerAnimation != null && mounted) {
        setState(() {
          _currentBusRenderPosition = _markerAnimation!.value;
          _updateMapMarkers(); // Draw dynamically
        });
      }
    });

    // Subscribe to OS-level background/foreground app state transitions for battery/stream saving
    WidgetsBinding.instance.addObserver(this);

    _requestPermissions();
    _loadData();
    _initWatchdog();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // Cleanly pause open network sockets when minimized
      _busSubscription?.pause();
      _stopsSubscription?.pause();
      _watchdogTimer?.cancel();
    } else if (state == AppLifecycleState.resumed) {
      // Re-trigger live tracking loops once app wakes
      _busSubscription?.resume();
      _stopsSubscription?.resume();
      _initWatchdog();
    }
  }

  void _initWatchdog() {
    _watchdogTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _lastBusUpdate == null) return;
      
      final diff = DateTime.now().difference(_lastBusUpdate!);
      String newStatus = "";
      
      if (diff.inSeconds <= 6) {
        newStatus = "Online";
      } else if (diff.inSeconds > 6 && diff.inSeconds <= 15) {
        newStatus = "Updating location...";
      } else {
        newStatus = "Offline / Reconnecting";
      }

      if (_connectionStatus != newStatus) {
        setState(() {
          _connectionStatus = newStatus;
        });
      }
    });
  }

  Future<void> _requestPermissions() async {
    await Geolocator.requestPermission();
  }

  void _loadData() {
    final authService = Provider.of<AuthService>(context, listen: false);
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    
    final user = authService.currentUserData;
    // Strong Null Safety
    if (user == null || user.busId == null || user.routeId == null || user.busId!.isEmpty) {
      setState(() {
        _fatalErrorMsg = "No Bus or Route is assigned to your ID yet. Contact Transport Administration.";
        _isInitializing = false;
      });
      return;
    }

    _stopsSubscription = firestoreService.streamStopsForRoute(user.routeId!).listen((stops) {
      if (mounted) {
        setState(() {
          _routeStops = stops;
          try {
            _myStop = stops.firstWhere((s) => s.id == user.stopId);
          } catch(e) {
            _myStop = null;
          }
          if (_currentBusRenderPosition != null && _myStop != null && _polylines.isEmpty) {
            _cachePolylineOnce(); // Optimize Streams Context (Calculate single API pull)
          }
          _updateMapMarkers();
        });
      }
    }, onError: (e) {
      debugPrint("Stops Stream Exception Captured: $e");
    });

    _busSubscription = firestoreService.streamBus(user.busId!).listen((bus) {
      if (mounted) {
        _lastBusUpdate = DateTime.now();
        bool firstLoad = _currentBus == null;
        _currentBus = bus;
        
        final newLatLng = LatLng(bus.latitude, bus.longitude);

        // Smooth Map Jitter Control: Tween constraint bridging DB gaps
        if (_oldBusPosition != null && _currentBusRenderPosition != null) {
          _markerAnimation = LatLngTween(begin: _currentBusRenderPosition!, end: newLatLng)
                                .animate(CurvedAnimation(parent: _markerAnimController!, curve: Curves.easeInOut));
          _markerAnimController!.forward(from: 0.0);
        } else {
           _currentBusRenderPosition = newLatLng;
           _updateMapMarkers();
        }

        _oldBusPosition = newLatLng;
        _updateETA(bus);
        
        // Prevent jarring manual camera snapping during mid-frame animation
        if (_mapController != null && bus.status == 'active' && firstLoad) {
           _mapController!.animateCamera(CameraUpdate.newLatLngZoom(newLatLng, 16));
        }

        if (_isInitializing) {
           setState(() => _isInitializing = false);
        }
        
        if (firstLoad && _myStop != null && _polylines.isEmpty) {
           _cachePolylineOnce();
        }
      }
    }, onError: (e) {
       setState(() {
         // Gracefully flag network dropout rather than raw crashing
         _connectionStatus = "Offline / Reconnecting";
       });
    });
  }

  Future<void> _cachePolylineOnce() async {
    // Limits intense compute/drawing calculations to pure layout initializations
    if (_myStop == null || _currentBusRenderPosition == null) return;
    
    final MapService mapService = MapService();
    final points = await mapService.getRoutePolyline(
      _currentBusRenderPosition!,
      LatLng(_myStop!.latitude, _myStop!.longitude),
    );

    if (mounted && points.isNotEmpty) {
      setState(() {
        _polylines.clear();
        _polylines.add(
          Polyline(
            polylineId: const PolylineId('bus_route_cached'),
            points: points,
            color: Colors.black87,
            width: 4,
            patterns: [PatternItem.dash(20), PatternItem.gap(10)], // Clean Uber Aesthetic
          ),
        );
      });
    }
  }

  void _updateETA(BusModel bus) {
    _etaResult = EtaService.calculateETA(bus, _myStop, _routeStops);
    
    if (_etaResult != null && 
        _etaResult!.minutes > 0 && 
        _etaResult!.minutes <= 10 && 
        !_hasSent10MinWarning && 
        bus.status == 'active') {
      _hasSent10MinWarning = true;
      NotificationService.push10MinWarning(bus.id);
    }
  }

  void _updateMapMarkers() {
    _markers.clear();

    // Layer 1: Stop markers across route
    for (var stop in _routeStops) {
      _markers.add(
        Marker(
          markerId: MarkerId(stop.id),
          position: LatLng(stop.latitude, stop.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            stop.id == _myStop?.id ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueAzure,
          ),
          infoWindow: InfoWindow(title: stop.stopName),
        ),
      );
    }

    // Layer 2: Animated Bus Marker driven by Ticker interpolation
    if (_currentBusRenderPosition != null && _currentBus != null && _currentBus!.status == 'active') {
      _markers.add(
        Marker(
          markerId: const MarkerId('live_bus'),
          position: _currentBusRenderPosition!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
          infoWindow: InfoWindow(
            title: 'Bus ${_currentBus!.busNumber}', 
            snippet: 'Speed Monitor: ${_currentBus!.speed.toStringAsFixed(1)} km/h',
          ),
          anchor: const Offset(0.5, 0.5),
          zIndexInt: 10,
        ),
      );
    }
  }

  Future<void> _recordAttendance(String status) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    final user = authService.currentUserData;
    
    if (user == null || _currentBus == null) return;

    // Hardened Structural Integrity Bounds prevents dead trip syncing
    if (_currentBus!.activeTripId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Wait for the driver to start the trip before boarding.'), backgroundColor: Colors.orange));
      }
      return;
    }

    String liveTripId = _currentBus!.activeTripId!;

    AttendanceModel att = AttendanceModel(
      id: "${user.uid}_${DateTime.now().millisecondsSinceEpoch}",
      studentId: user.uid,
      tripId: liveTripId,
      status: status,
      timestamp: DateTime.now(),
    );

    try {
      await firestoreService.markAttendance(att);
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Success: Driver notified of your $status status!'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            backgroundColor: Colors.black87,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Firebase Request Failed. Ensure Network Connectivity.'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _triggerSOS() async {
    setState(() => _isSosLoading = true);
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final firestoreService = Provider.of<FirestoreService>(context, listen: false);
      final user = authService.currentUserData;

      if (user == null) throw Exception("User data missing");

      final locationService = LocationService();
      final position = await locationService.getCurrentLocation();
      
      if (position == null) throw Exception("Please enable Location Permissions.");

      SosAlertModel alert = SosAlertModel(
        id: "SOS_${user.uid}_${DateTime.now().millisecondsSinceEpoch}",
        studentId: user.uid,
        studentName: user.name,
        latitude: position.latitude,
        longitude: position.longitude,
        resolved: false,
        timestamp: DateTime.now(),
      );

      await firestoreService.triggerSos(alert);
      await NotificationService.pushSOSAlert(user.name, user.busId ?? "Unknown");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🚨 SOS DISPATCHED TO ADMIN 🚨', style: TextStyle(fontWeight: FontWeight.bold)), 
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('SOS Failed: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSosLoading = false);
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _watchdogTimer?.cancel();
    _markerAnimController?.dispose();
    _busSubscription?.cancel();
    _stopsSubscription?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Widget _buildStatusPill() {
    Color bulbColor = Colors.grey;
    if (_connectionStatus == "Online") bulbColor = Colors.green;
    if (_connectionStatus == "Updating location...") bulbColor = Colors.orange;
    if (_connectionStatus.contains("Offline")) bulbColor = Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(shape: BoxShape.circle, color: bulbColor),
          ),
          const SizedBox(width: 8),
          Text(
            _connectionStatus.toUpperCase(),
            style: TextStyle(color: Colors.grey[800], fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_fatalErrorMsg != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('GoCampus Planner'), backgroundColor: Colors.white, elevation: 0),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.no_transfer, size: 80, color: Colors.grey),
                const SizedBox(height: 24),
                Text(_fatalErrorMsg!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.w500)),
                const SizedBox(height: 32),
                 OutlinedButton(
                   onPressed: () => Provider.of<AuthService>(context, listen: false).signOut(),
                   child: const Text('Logout'),
                 )
              ],
            ),
          ),
        )
      );
    }

    if (_isInitializing) {
      return const Scaffold(
        body: Center(
          child: Column(
             mainAxisAlignment: MainAxisAlignment.center,
             children: [
               CircularProgressIndicator(color: Colors.black87),
               SizedBox(height: 20),
               Text("Acquiring Satellite Lock...", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))
             ],
          )
        ),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('GoCampus Tracker', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (_isSosLoading)
            const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.red))))
          else
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.sos_outlined, color: Colors.white, size: 20),
              ),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text("TRIGGER SOS?"),
                    content: const Text("Deploy extreme immediate GPS tracking protocol to management?"),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL", style: TextStyle(color: Colors.grey))),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _triggerSOS();
                        },
                        child: const Text("CONFIRM 🚨", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  )
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black87),
            onPressed: () => Provider.of<AuthService>(context, listen: false).signOut(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          // 1. Google Map Foundation
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: LatLng(13.0489, 80.0572),
              zoom: 14,
            ),
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            onMapCreated: (controller) => _mapController = controller,
          ),

          // Connectivity Pill Layer
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 60.0), // Below App Bar
                child: _buildStatusPill(),
              ),
            ),
          ),
          
          // 2. Interactive App Card
          Align(
            alignment: Alignment.bottomCenter,
            child: _buildUberBottomSheet(),
          )
        ],
      ),
    );
  }

  Widget _buildUberBottomSheet() {
    String displayStatus = _etaResult?.displayStatus ?? "Finding Bus...";
    String nextStopName = _currentBus != null && _routeStops.isNotEmpty ? 
      _routeStops.firstWhere((s) => s.id == _currentBus!.nextStop, orElse: () => _routeStops.last).stopName : "Fetching...";
      
    // Lock controls locally if offline or trip isn't active
    bool isOffline = _connectionStatus.contains("Offline");
    bool isTripActive = _currentBus?.activeTripId != null;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, -5)
          )
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Grabber Handle
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // Key Identifier Node
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                   Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: Colors.grey[200]!)
                    ),
                    child: Center(
                      child: Text(
                        _currentBus?.busNumber ?? '...',
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isOffline ? "Lost Connection" : (!isTripActive ? "Offline" : displayStatus),
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                            color: (_currentBus?.status == 'active' && !isOffline) ? Colors.black87 : Colors.grey,
                          ),
                        ),
                        if (_etaResult?.minutes != null && _etaResult!.minutes > 0)
                          Text(
                            'Assign Drop: ${_myStop?.stopName ?? "Pending"}',
                            style: TextStyle(color: Colors.grey[600], fontSize: 14, fontWeight: FontWeight.w500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              Divider(height: 1, color: Colors.grey[200]),
              const SizedBox(height: 16),
              
              // Secondary Insight Node
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.location_on, color: Colors.blueAccent, size: 20),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Approaching Node',
                          style: TextStyle(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.bold),
                        ),
                        Text(
                          nextStopName,
                          style: const TextStyle(fontSize: 16, color: Colors.black87, fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  )
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Action Controllers
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        side: BorderSide(color: Colors.grey[300]!),
                      ),
                      onPressed: isOffline ? null : () => _recordAttendance('not_coming'),
                      child: const Text("Skip Stop", style: TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isOffline ? Colors.grey : Colors.black87,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      onPressed: isOffline ? null : () => _recordAttendance('coming'),
                      child: const Text("I'm Boarding", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
