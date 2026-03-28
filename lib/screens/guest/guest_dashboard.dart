import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/app_constants.dart';
import '../../models/bus_model.dart';

class GuestDashboard extends StatefulWidget {
  const GuestDashboard({super.key});

  @override
  State<GuestDashboard> createState() => _GuestDashboardState();
}

class _GuestDashboardState extends State<GuestDashboard> {
  final TextEditingController _searchController = TextEditingController();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String _searchQuery = "";

  Widget _buildSearchResults() {
    return StreamBuilder<QuerySnapshot>(
      stream: _db.collection('buses').where('status', isEqualTo: 'active').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        // Client-side document filtering
        final buses = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final busNum = (data['busNumber'] ?? '').toString().toLowerCase();
          final routeId = (data['routeId'] ?? '').toString().toLowerCase();

          return busNum.contains(_searchQuery) || routeId.contains(_searchQuery);
        }).toList();

        if (buses.isEmpty) {
          return const Center(child: Text("No tracking active for your query.", style: TextStyle(color: Colors.grey)));
        }

        return ListView.builder(
          itemCount: buses.length,
          itemBuilder: (context, index) {
            final data = buses[index].data() as Map<String, dynamic>;
            final busModel = BusModel.fromMap(data, buses[index].id);

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: ListTile(
                leading: const Icon(Icons.directions_bus, color: Colors.blueAccent, size: 40),
                title: Text("Bus: ${busModel.busNumber} | ${busModel.routeId}", style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("Status: ${busModel.status.toUpperCase()} | Speed: ${busModel.speed.toStringAsFixed(0)} km/h"),
                trailing: Text(_getStopLabel(busModel), style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                onTap: () {
                  if (busModel.status == 'active') {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => GuestMapScreen(busId: busModel.id)));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Cannot track an offline bus.")));
                  }
                },
              ),
            );
          },
        );
      },
    );
  }

  String _getStopLabel(BusModel bus) {
    if (bus.status != 'active') return "OFFLINE";
    return "MOVING";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Guest Route Locator', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text("Find Your Campus Transport", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                const Text("Enter Bus Number or Route ID to see live locations.", style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 16),
                TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val.toLowerCase().trim()),
                  decoration: InputDecoration(
                    hintText: "Search e.g., 'BUS-01' or 'TN-01-AB-1234'",
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.grey[200],
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Align(alignment: Alignment.centerLeft, child: Text("Active Transports", style: TextStyle(fontWeight: FontWeight.w900, color: Colors.black54))),
          ),
          Expanded(
            child: _buildSearchResults(),
          ),
        ],
      ),
    );
  }
}

// ----- 2. GUEST LIVE MAP SCREEN -----
class GuestMapScreen extends StatelessWidget {
  final String busId;
  const GuestMapScreen({super.key, required this.busId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Live Radar: $busId", style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('buses').doc(busId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data == null || !snapshot.data!.exists) {
            return const Center(child: CircularProgressIndicator());
          }

          var liveBus = BusModel.fromMap(snapshot.data!.data() as Map<String, dynamic>, snapshot.data!.id);

          return Stack(
            children: [
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: LatLng(liveBus.latitude, liveBus.longitude),
                  zoom: 16,
                ),
                markers: {
                  Marker(
                    markerId: const MarkerId('live_bus_guest'),
                    position: LatLng(liveBus.latitude, liveBus.longitude),
                    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
                    infoWindow: InfoWindow(title: liveBus.busNumber, snippet: "${liveBus.speed.toStringAsFixed(1)} km/h"),
                  ),
                  const Marker(
                    markerId: MarkerId('college'),
                    position: LatLng(AppConstants.collegeLat, AppConstants.collegeLng),
                    icon: BitmapDescriptor.defaultMarker,
                    infoWindow: InfoWindow(title: "College Campus"),
                  )
                },
              ),
              // Floating info banner locking out heavy features like SOS/Attendance
              Positioned(
                bottom: 30,
                left: 20,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 15, offset: Offset(0, 5))],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text("GUEST VIEW MODE", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 2, fontSize: 10)),
                      const SizedBox(height: 8),
                      Text("Bus Speed: ${liveBus.speed.toStringAsFixed(1)} KM/H", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 8),
                      const Text("For accurate ETAs and Check-In features, please Login.", textAlign: TextAlign.center, style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                    ],
                  ),
                ),
              )
            ],
          );
        },
      ),
    );
  }
}
