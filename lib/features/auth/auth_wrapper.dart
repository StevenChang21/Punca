import 'package:flutter/material.dart';
import 'package:punca_ai/core/services/auth_service.dart';
import 'package:punca_ai/features/auth/login_screen.dart';
import 'package:punca_ai/features/teacher/teacher_scaffold.dart';
import 'package:punca_ai/features/student/main_scaffold.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return StreamBuilder(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        // 1. Loading State
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // 2. Error State
        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(child: Text("Authentication Error")),
          );
        }

        // 3. Authenticated -> Check Role
        if (snapshot.hasData) {
          final user = snapshot.data!;
          return FutureBuilder<String?>(
            future: authService.getUserRole(user.uid),
            builder: (context, roleSnapshot) {
              if (roleSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              final role = roleSnapshot.data;
              if (role == 'Teacher') {
                return const TeacherScaffold();
              }
              // Default to Student Dashboard
              return const MainScaffold();
            },
          );
        }

        // 4. Not Authenticated -> Login
        return const LoginScreen();
      },
    );
  }
}
