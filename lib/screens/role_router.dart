import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

// Dashboard Screens
import 'admin/admin_dashboard.dart';
import 'driver/driver_dashboard.dart';
import 'student/student_dashboard_screen.dart';
import 'incharge/incharge_dashboard.dart';

class RoleRouter extends StatelessWidget {
  const RoleRouter({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          return Consumer<AuthService>(
            builder: (context, authService, child) {
              if (authService.currentUserData == null) {
                // Fetch user data from Firestore if not already loaded
                authService.fetchUserData(snapshot.data!.uid);
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              final role = authService.currentUserData!.role;

              switch (role.toLowerCase()) {
                case 'admin':
                  return const AdminDashboard();
                case 'incharge':
                  return const InchargeDashboard();
                case 'driver':
                  return const DriverDashboard();
                case 'student':
                  return const StudentDashboardScreen();
                default:
                  return Scaffold(
                    body: Center(
                      child: Text('Unknown role "$role" for this account.'),
                    ),
                  );
              }
            },
          );
        }

        // If not logged in, show Login Form
        return const LoginScreen();
      },
    );
  }
}
