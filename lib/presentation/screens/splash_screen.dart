import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _isNavigated = false; // Add a flag to prevent multiple navigations

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    await Future.delayed(const Duration(milliseconds: 500));

    // if (!mounted || _isNavigated) return; // Prevent multiple navigations
    setState(() {
      _isNavigated = true; // Set the flag to true after navigation
    });

    if (token != null && token.isNotEmpty) {
      Navigator.pushReplacementNamed(context, '/chat-ai');
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
