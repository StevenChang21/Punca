import 'package:flutter/material.dart';
import 'package:punca_ai/config/app_theme.dart';
import 'package:punca_ai/features/student/main_scaffold.dart';

void main() {
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
      home: const MainScaffold(),
    );
  }
}
