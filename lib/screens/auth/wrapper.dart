import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import '../admin/admin_dashboard.dart';
import '../teacher/teacher_home.dart';
import '../student/student_home.dart';
import 'login_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        // Show loading while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // User is signed in
        if (snapshot.hasData && snapshot.data != null) {
          return FutureBuilder<UserRole?>(
            future: authService.getUserRole(snapshot.data!.uid),
            builder: (context, roleSnapshot) {
              if (roleSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              if (roleSnapshot.hasData) {
                if (roleSnapshot.data == UserRole.admin) {
                  return const AdminDashboard();
                } else if (roleSnapshot.data == UserRole.teacher) {
                  return const TeacherHomeScreen();
                } else if (roleSnapshot.data == UserRole.student) {
                  return const StudentHomeScreen();
                }
              }

              // If role not found, sign out and go to login
              authService.signOut();
              return const LoginScreen();
            },
          );
        }

        // User is not signed in
        return const LoginScreen();
      },
    );
  }
}
