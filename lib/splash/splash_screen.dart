import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:WanderBite/core/constants/app_constants.dart';
import 'package:WanderBite/auth/services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _navigateToNextScreen();
  }

  Future<void> _navigateToNextScreen() async {
    // Simulate loading resources
    await Future.delayed(const Duration(seconds: AppConstants.splashDuration));

    // Check if user is logged in
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool(AppConstants.isLoggedInKey) ?? false;

    // Check if any users exist
    final userCount = await _authService.getUserCount();
    final hasUsers = userCount > 0;

    if (mounted) {
      if (isLoggedIn) {
        Navigator.pushReplacementNamed(context, AppConstants.homeRoute);
      } else {
        // If no users exist and user is not logged in, go directly to signup
        if (!hasUsers) {
          Navigator.pushReplacementNamed(context, AppConstants.signupRoute);
        } else {
          Navigator.pushReplacementNamed(context, AppConstants.loginRoute);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).primaryColor.withOpacity(0.8),
            ],
          ),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App logo or icon
            Icon(
              Icons.travel_explore,
              size: 120,
              color: Colors.white,
            ),
            SizedBox(height: 20),
            // App name
            Text(
              AppConstants.appName,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 30),
            // Loading indicator
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
