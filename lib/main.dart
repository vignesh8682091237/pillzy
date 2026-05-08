import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/splash_screen.dart';
import 'screens/entry_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.init();
  
  final prefs = await SharedPreferences.getInstance();
  final profileStr = prefs.getString('current_profile');
  Map<String, dynamic>? savedProfile;
  if (profileStr != null) {
    savedProfile = jsonDecode(profileStr);
  }

  runApp(MyApp(savedProfile: savedProfile));
}

class MyApp extends StatelessWidget {
  final Map<String, dynamic>? savedProfile;
  const MyApp({super.key, this.savedProfile});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pillzy',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      initialRoute: savedProfile != null ? '/home' : '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/entry': (context) => const EntryScreen(),
        '/login': (context) => const LoginScreen(),
        '/home': (context) => HomeScreen(profileData: savedProfile ?? {}),
      },
    );
  }
}
