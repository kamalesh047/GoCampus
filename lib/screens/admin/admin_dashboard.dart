import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart' as ex;

import '../../services/auth_service.dart';
import '../../services/notification_service.dart';
import '../../core/app_constants.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _currentIndex = 0;
  bool _isImporting = false;

  final TextEditingController _announceController = TextEditingController();

  // ----- TAB 0: MANAGEMENT (EXCEL IMPORT) -----
  Future<void> _importStudentsBatch() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() => _isImporting = true);
      try {
        var bytes = File(result.files.single.path!).readAsBytesSync();
        var excel = ex.Excel.decodeBytes(bytes);

        // We MUST use a secondary Firebase App to create Auth accounts without signing the Admin out!
        FirebaseApp tempApp = await Firebase.initializeApp(
          name: 'TempAuthApp',
          options: Firebase.app().options,
        );
        FirebaseAuth tempAuth = FirebaseAuth.instanceFor(app: tempApp);

        int importedCount = 0;

        for (var table in excel.tables.keys) {
          var sheet = excel.tables[table]!;
          // Skip header row
          for (int i = 1; i < sheet.rows.length; i++) {
            var row = sheet.rows[i];
            if (row.isEmpty || row[0] == null) continue;

            String name = row[0]?.value.toString() ?? 'Unknown';
            String mobile = row[1]?.value.toString() ?? '';
            String password = row[2]?.value.toString() ?? '123456';
            String busId = row[3]?.value.toString() ?? 'BUS-01';
            String routeId = row[4]?.value.toString() ?? 'ROUTE-01';
            String stopId = row[5]?.value.toString() ?? 'STOP-01';

            if (mobile.isNotEmpty) {
              try {
                // 1. Create native Firebase Auth Account
                UserCredential cred = await tempAuth.createUserWithEmailAndPassword(
                  email: '$mobile@gocampus.com',
                  password: password,
                );

                // 2. Insert into 'users' collection
                await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).set({
                  'name': name,
                  'mobile': mobile,
                  'password': password,
                  'role': 'student',
                  'busId': busId,
                  'routeId': routeId,
                  'stopId': stopId,
                });
                importedCount++;
              } catch (e) {
                // skip error
              }
            }
          }
        }
        await tempApp.delete(); // Destroy secondary instance

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('✅ Successfully imported and assigned $importedCount students!'),
            backgroundColor: Colors.green,
          ));
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error parsing excel: $e')));
      } finally {
        if (mounted) setState(() => _isImporting = false);
      }
    }
  }

  Widget _buildManagementTab() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.group_add, size: 80, color: Colors.blueAccent),
          const SizedBox(height: 24),
          const Text(
            "Mass Import & Assignment",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text(
            "Upload an Excel (.xlsx) file with columns:\n[Name, Mobile, Password, BusID, RouteID, StopID]",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 48),
          _isImporting
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton.icon(
                  onPressed: _importStudentsBatch,
                  icon: const Icon(Icons.upload_file),
                  label: const Text("UPLOAD EXCEL DATABASE", style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(20),
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                ),
        ],
      ),
    );
  }

  // ----- TAB 1: LIVE MAP TRACKING -----
  Widget _buildLiveMapTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('buses').where('status', isEqualTo: 'active').snapshots(),
      builder: (context, snapshot) {
        Set<Marker> markers = {
          const Marker(
            markerId: MarkerId('college'),
            position: LatLng(AppConstants.collegeLat, AppConstants.collegeLng),
            icon: BitmapDescriptor.defaultMarker,
            infoWindow: InfoWindow(title: "College Campus"),
          )
        };

        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            var data = doc.data() as Map<String, dynamic>;
            markers.add(
              Marker(
                markerId: MarkerId(doc.id),
                position: LatLng(data['latitude'] ?? 0.0, data['longitude'] ?? 0.0),
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
                infoWindow: InfoWindow(title: "Bus ${data['busNumber']}", snippet: "${data['speed']} km/h | Target: ${data['nextStop']}"),
              ),
            );
          }
        }

        return GoogleMap(
          initialCameraPosition: const CameraPosition(
            target: LatLng(AppConstants.collegeLat, AppConstants.collegeLng),
            zoom: 12,
          ),
          markers: markers,
          myLocationEnabled: false,
        );
      },
    );
  }

  // ----- TAB 2: ANNOUNCEMENTS -----
  void _sendBroadcast() async {
    if (_announceController.text.trim().isEmpty) return;
    
    await NotificationService.pushAdminAnnouncement(_announceController.text.trim());
    _announceController.clear();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Broadcast Sent!'), backgroundColor: Colors.green),
      );
      FocusScope.of(context).unfocus();
    }
  }

  Widget _buildAnnouncementsTab() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text("Live Broadcast", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text("Push mandatory notifications instantly to all Active students and drivers.", style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 32),
          TextField(
            controller: _announceController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: "Enter urgent announcement for campus...",
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _sendBroadcast,
            icon: const Icon(Icons.campaign),
            label: const Text("SEND TO ALL NETWORKS", style: TextStyle(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(20),
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> tabs = [
      _buildManagementTab(),
      _buildLiveMapTab(),
      _buildAnnouncementsTab(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Command Center', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Provider.of<AuthService>(context, listen: false).signOut(),
          )
        ],
      ),
      body: tabs[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.manage_accounts), label: "Database"),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: "Live Radar"),
          BottomNavigationBarItem(icon: Icon(Icons.campaign), label: "Broadcast"),
        ],
      ),
    );
  }
}
