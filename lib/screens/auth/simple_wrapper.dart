import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import '../admin/admin_dashboard.dart';
import '../teacher/teacher_home.dart';
import '../student/student_home.dart';
import 'login_screen.dart';

class SimpleAuthWrapper extends StatelessWidget {
  const SimpleAuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        print(
            'SimpleAuthWrapper: Connection state: ${snapshot.connectionState}');
        print('SimpleAuthWrapper: Has data: ${snapshot.hasData}');

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasData) {
          final uid = snapshot.data!.uid;
          print('SimpleAuthWrapper: User authenticated with UID: $uid');

          return FutureBuilder<UserRole?>(
            future: authService.getUserRole(uid),
            builder: (context, roleSnapshot) {
              print(
                  'SimpleAuthWrapper: Role future state: ${roleSnapshot.connectionState}');
              print('SimpleAuthWrapper: Role data: ${roleSnapshot.data}');

              if (roleSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Loading your dashboard...'),
                      ],
                    ),
                  ),
                );
              }

              if (roleSnapshot.hasData && roleSnapshot.data != null) {
                final role = roleSnapshot.data!;
                print('SimpleAuthWrapper: Navigating to role: $role');

                switch (role) {
                  case UserRole.admin:
                    print('SimpleAuthWrapper: Returning AdminDashboard');
                    return const AdminDashboard();
                  case UserRole.teacher:
                    print('SimpleAuthWrapper: Returning TeacherHomeScreen');
                    return const TeacherHomeScreen();
                  case UserRole.student:
                    print('SimpleAuthWrapper: Returning StudentHomeScreen');
                    return const StudentHomeScreen();
                }
              }

              if (roleSnapshot.hasError) {
                print(
                    'SimpleAuthWrapper: Error getting role: ${roleSnapshot.error}');
                return Scaffold(
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error, color: Colors.red, size: 64),
                        SizedBox(height: 16),
                        Text('Error loading user role'),
                        Text('${roleSnapshot.error}'),
                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => authService.signOut(),
                          child: Text('Sign Out'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // No role found
              print('SimpleAuthWrapper: No role found, signing out');
              return Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.warning, color: Colors.orange, size: 64),
                      SizedBox(height: 16),
                      Text('User role not found'),
                      Text('Please contact your administrator'),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => authService.signOut(),
                        child: Text('Sign Out'),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        }

        print('SimpleAuthWrapper: No user authenticated, showing login');
        return const LoginScreen();
      },
    );
  }
}
