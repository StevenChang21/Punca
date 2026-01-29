import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // Uncomment after running flutterfire configure
import 'package:punca_ai/config/app_theme.dart';
import 'package:punca_ai/features/auth/auth_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const PuncaApp());
}

class PuncaApp extends StatelessWidget {
  const PuncaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Punca AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const AuthWrapper(),
    );
  }
}
