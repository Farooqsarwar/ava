import 'package:ai_voice_agent/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase with hardcoded credentials
  await Supabase.initialize(
    url: 'https://imcdzywexvrdixyeztai.supabase.co', // Replace with your Supabase URL
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImltY2R6eXdleHZyZGl4eWV6dGFpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE5ODI2NDQsImV4cCI6MjA3NzU1ODY0NH0.cp1tMJooun8L3aCYLdVMKEgF9g0XnXWYAdlkxoqeo2Q', // Replace with your Supabase anon key
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AVA - AI Voice Agent',
      theme: ThemeData(
        primaryColor: const Color(0xFF2563EB),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}