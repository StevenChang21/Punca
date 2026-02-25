import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Import dotenv
import 'firebase_options.dart';
import 'package:punca_ai/config/app_theme.dart';
import 'package:punca_ai/features/auth/auth_wrapper.dart';
import 'package:punca_ai/core/services/language_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env"); // Load environment variables
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await LanguagePreferences.init();
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
