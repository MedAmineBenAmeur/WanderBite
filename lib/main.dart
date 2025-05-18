import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:WanderBite/core/constants/app_constants.dart';
import 'package:WanderBite/auth/services/notification_service.dart';
import 'package:WanderBite/core/themes/theme_provider.dart';
import 'package:WanderBite/splash/splash_screen.dart';
import 'package:WanderBite/auth/login_screen.dart';
import 'package:WanderBite/auth/signup_screen.dart';
import 'package:WanderBite/home/home_screen.dart';
import 'package:WanderBite/maps/maps_screen.dart';
import 'package:WanderBite/calendar/calendar_screen.dart';
import 'package:WanderBite/multimedia/multimedia_screen.dart';
import 'package:WanderBite/profile/profile_screen.dart';
import 'package:WanderBite/profile/user_data_view_screen.dart';
import 'package:WanderBite/auth/services/notifications_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        Provider(create: (context) => NotificationService()..initialize()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: AppConstants.appName,
            theme: themeProvider.currentTheme,
            initialRoute: AppConstants.splashRoute,
            routes: {
              AppConstants.splashRoute: (context) => const SplashScreen(),
              AppConstants.loginRoute: (context) => const LoginScreen(),
              AppConstants.signupRoute: (context) => const SignupScreen(),
              AppConstants.homeRoute: (context) => const HomeScreen(),
              AppConstants.mapsRoute: (context) => const MapsScreen(),
              AppConstants.calendarRoute: (context) => const CalendarScreen(),
              AppConstants.multimediaRoute: (context) =>
                  const MultimediaScreen(),
              AppConstants.profileRoute: (context) => const ProfileScreen(),
              AppConstants.userDataViewRoute: (context) =>
                  const UserDataViewScreen(),
              AppConstants.notificationsRoute: (context) =>
                  const NotificationsScreen(),
            },
            onUnknownRoute: (settings) => MaterialPageRoute(
              builder: (context) => const UnknownRouteScreen(),
            ),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}

class UnknownRouteScreen extends StatelessWidget {
  const UnknownRouteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('404: Page not found'),
            ElevatedButton(
              onPressed: () => Navigator.pushNamedAndRemoveUntil(
                context,
                AppConstants.homeRoute,
                (route) => false,
              ),
              child: const Text('Go to Home'),
            ),
          ],
        ),
      ),
    );
  }
}
