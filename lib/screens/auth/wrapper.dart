import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import '../admin/admin_dashboard.dart';
import '../teacher/teacher_home.dart';
import '../student/student_home.dart';
import 'login_screen.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  UserRole? _cachedRole;
  String? _cachedUid;

  Future<UserRole?> _getUserRoleWithIntegrity(
      AuthService authService, String uid) async {
    try {
      print('Starting role detection for uid: $uid');

      // First, ensure user data integrity
      await authService.ensureUserDataIntegrity(uid);
      print('Data integrity check completed for uid: $uid');

      // Then get the role
      final role = await authService.getUserRole(uid);
      print('Got role for uid $uid: $role');

      return role;
    } catch (e) {
      print('Error in _getUserRoleWithIntegrity: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        print('AuthWrapper StreamBuilder state: ${snapshot.connectionState}');
        print('AuthWrapper has data: ${snapshot.hasData}');
        print('AuthWrapper data: ${snapshot.data?.uid}');

        // Show loading while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          print('AuthWrapper showing loading - waiting for auth state');
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // User is signed in
        if (snapshot.hasData && snapshot.data != null) {
          final currentUid = snapshot.data!.uid;
          print('User is authenticated with uid: $currentUid');

          // Clear cache if different user
          if (_cachedUid != currentUid) {
            _cachedRole = null;
            _cachedUid = currentUid;
            print('Cleared cache for new user: $currentUid');
          }

          // Use cached role if available for immediate display
          if (_cachedRole != null) {
            print('Using cached role: $_cachedRole');
            // Still check for role in background but show cached version immediately
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _getUserRoleWithIntegrity(authService, currentUid)
                  .then((newRole) {
                if (newRole != null && newRole != _cachedRole && mounted) {
                  setState(() {
                    _cachedRole = newRole;
                  });
                }
              });
            });
            return _buildRoleScreen(_cachedRole!);
          }

          return FutureBuilder<UserRole?>(
            future: _getUserRoleWithIntegrity(authService, currentUid),
            builder: (context, roleSnapshot) {
              print('FutureBuilder state: ${roleSnapshot.connectionState}');
              print('FutureBuilder has data: ${roleSnapshot.hasData}');
              print('FutureBuilder data: ${roleSnapshot.data}');
              print('FutureBuilder error: ${roleSnapshot.error}');

              if (roleSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Setting up your dashboard...'),
                      ],
                    ),
                  ),
                );
              }

              if (roleSnapshot.hasData && roleSnapshot.data != null) {
                _cachedRole = roleSnapshot.data!;
                print('Building role screen for role: ${roleSnapshot.data!}');
                return _buildRoleScreen(roleSnapshot.data!);
              }

              if (roleSnapshot.hasError) {
                print('Error in role detection: ${roleSnapshot.error}');
                return Scaffold(
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: Colors.red),
                        SizedBox(height: 16),
                        Text('Error loading user data'),
                        SizedBox(height: 8),
                        Text('${roleSnapshot.error}'),
                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {}); // Retry
                          },
                          child: Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // If role not found, show error and provide option to sign out
              print('Role not found for user: $currentUid');
              return Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person_off, size: 64, color: Colors.orange),
                      SizedBox(height: 16),
                      Text('User role not found'),
                      SizedBox(height: 8),
                      Text('Please contact your administrator'),
                      SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              setState(() {}); // Retry
                            },
                            child: Text('Retry'),
                          ),
                          SizedBox(width: 16),
                          ElevatedButton(
                            onPressed: () {
                              authService.signOut();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                            child: Text('Sign Out'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        }

        // User is not signed in - clear cache
        print('User not authenticated, showing login screen');
        _cachedRole = null;
        _cachedUid = null;
        return const LoginScreen();
      },
    );
  }

  Widget _buildRoleScreen(UserRole role) {
    print('_buildRoleScreen called with role: $role');
    switch (role) {
      case UserRole.admin:
        print('Returning AdminDashboard');
        return const AdminDashboard();
      case UserRole.teacher:
        print('Returning TeacherHomeScreen');
        return const TeacherHomeScreen();
      case UserRole.student:
        print('Returning StudentHomeScreen');
        return const StudentHomeScreen();
    }
  }
}
