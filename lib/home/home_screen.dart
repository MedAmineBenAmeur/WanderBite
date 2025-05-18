import 'dart:io';
import 'package:flutter/material.dart';
import 'package:WanderBite/core/constants/app_constants.dart';
import 'package:WanderBite/core/themes/theme_provider.dart';
import 'package:WanderBite/auth/models/user_model.dart';
import 'package:WanderBite/auth/services/auth_service.dart';
import 'package:WanderBite/auth/services/notification_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _username = 'User';
  String? _userEmail;
  String? _profileImagePath;
  final _authService = AuthService();
  User? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final username = prefs.getString(AppConstants.userNameKey);
      final userEmail = prefs.getString('user_email');
      final user = await _authService.getCurrentUser();

      setState(() {
        _username = username ?? 'User';
        _userEmail = userEmail;
        _currentUser = user;
        if (user != null) {
          _profileImagePath = user.profileImagePath;
        }
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading user data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.isLoggedInKey, false);

    if (mounted) {
      Navigator.pushReplacementNamed(context, AppConstants.loginRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final notificationService = Provider.of<NotificationService>(context);
    final themeType = themeProvider.themeType;
    final bool isTravelTheme = themeType == AppConstants.travelTheme;
    final notificationCount = notificationService.getNotifications().length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: () {
                  Navigator.pushNamed(context, AppConstants.notificationsRoute);
                },
                tooltip: 'Notifications',
              ),
              if (notificationCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '$notificationCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(_username),
              accountEmail: Text(_userEmail ?? 'user@example.com'),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                backgroundImage: _profileImagePath != null
                    ? FileImage(File(_profileImagePath!))
                    : null,
                child: _profileImagePath == null
                    ? const Icon(Icons.person, size: 40, color: Colors.grey)
                    : null,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('My Profile'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppConstants.profileRoute);
              },
            ),
            ListTile(
              leading: const Icon(Icons.map),
              title: const Text('Maps'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppConstants.mapsRoute);
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Calendar'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppConstants.calendarRoute);
              },
            ),
            ListTile(
              leading: const Icon(Icons.perm_media),
              title: const Text('Media'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppConstants.multimediaRoute);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Theme Selection'),
              onTap: () {
                Navigator.pop(context);
                _showThemeSelectionDialog();
              },
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage(
                          isTravelTheme
                              ? 'assets/travel_banner.jpg'
                              : 'assets/recipe_banner.jpg',
                        ),
                        fit: BoxFit.cover,
                      ),
                      color: Theme.of(context).primaryColor,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.7),
                          ],
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome, $_username!',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              isTravelTheme
                                  ? 'Discover amazing places around the world.'
                                  : 'Discover delicious recipes from around the world.',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 40,
                                  backgroundColor: Colors.grey.shade200,
                                  backgroundImage: _profileImagePath != null
                                      ? FileImage(File(_profileImagePath!))
                                      : null,
                                  child: _profileImagePath == null
                                      ? const Icon(Icons.person,
                                          size: 40, color: Colors.grey)
                                      : null,
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _username,
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _userEmail ?? 'Not available',
                                        style: TextStyle(
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            OutlinedButton(
                              onPressed: () {
                                Navigator.pushNamed(
                                        context, AppConstants.profileRoute)
                                    .then((_) => _loadUserData());
                              },
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(40.0),
                              ),
                              child: const Text('Manage My Profile'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Quick Access',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildFeatureCard(
                              context,
                              Icons.map,
                              'Maps',
                              () => Navigator.pushNamed(
                                  context, AppConstants.mapsRoute),
                            ),
                            _buildFeatureCard(
                              context,
                              Icons.calendar_today,
                              'Calendar',
                              () => Navigator.pushNamed(
                                  context, AppConstants.calendarRoute),
                            ),
                            _buildFeatureCard(
                              context,
                              Icons.perm_media,
                              'Media',
                              () => Navigator.pushNamed(
                                  context, AppConstants.multimediaRoute),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        Text(
                          'About This App',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        Card(
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isTravelTheme
                                      ? 'Your Ultimate Travel Companion'
                                      : 'Your Ultimate Recipe Guide',
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  isTravelTheme
                                      ? 'This app helps you discover amazing destinations, plan your trips with our interactive map, schedule your itinerary with the calendar, and document your journey with photos, videos, and voice notes.'
                                      : 'This app helps you discover delicious recipes, locate cooking ingredients with our interactive map, schedule your meal planning with the calendar, and document your cooking experiences with photos, videos, and voice notes.',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 3,
        child: Container(
          width: 100,
          height: 100,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 32,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showThemeSelectionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Theme'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildThemeOption(
                  context,
                  'Travel Theme',
                  Icons.travel_explore,
                  AppConstants.travelTheme,
                ),
                const SizedBox(height: 16),
                _buildThemeOption(
                  context,
                  'Recipe Theme',
                  Icons.restaurant_menu,
                  AppConstants.recipeTheme,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    String title,
    IconData icon,
    String themeType,
  ) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isSelected = themeProvider.themeType == themeType;

    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? Theme.of(context).primaryColor : null,
      ),
      title: Text(title),
      trailing: isSelected
          ? Icon(
              Icons.check_circle,
              color: Theme.of(context).primaryColor,
            )
          : null,
      onTap: () {
        themeProvider.setTheme(themeType);
        Navigator.of(context).pop();
      },
    );
  }
}
