import 'package:flutter/material.dart';
import 'screens/session_screen.dart';
import 'screens/writeups_screen.dart';
import 'screens/settings_screen.dart';

void main() {
  runApp(const CodeAuditCaptureApp());
}

class CodeAuditCaptureApp extends StatelessWidget {
  const CodeAuditCaptureApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Code Audit Capture',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const SessionScreen(),
    );
  }
}
