import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:WanderBite/core/constants/app_constants.dart';
import 'package:WanderBite/auth/services/notification_service.dart';
import 'package:WanderBite/core/themes/theme_provider.dart';
import 'package:WanderBite/multimedia/audio_recorder_screen.dart';
import 'package:WanderBite/multimedia/photo_capture_screen.dart';
import 'package:WanderBite/multimedia/video_player_screen.dart';

class MultimediaScreen extends StatefulWidget {
  const MultimediaScreen({Key? key}) : super(key: key);

  @override
  State<MultimediaScreen> createState() => _MultimediaScreenState();
}

class _MultimediaScreenState extends State<MultimediaScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final bool isTravelTheme =
        themeProvider.themeType == AppConstants.travelTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isTravelTheme ? 'Travel Documentation' : 'Recipe Documentation',
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.mic), text: 'Audio'),
            Tab(icon: Icon(Icons.photo_camera), text: 'Photo'),
            Tab(icon: Icon(Icons.video_library), text: 'Video'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          AudioRecorderScreen(
            onAction: (action) => _handleMediaAction(context, action),
          ),
          PhotoCaptureScreen(
            onAction: (action) => _handleMediaAction(context, action),
          ),
          VideoPlayerScreen(
            onAction: (action) => _handleMediaAction(context, action),
          ),
        ],
      ),
    );
  }

  void _handleMediaAction(BuildContext context, String action) {
    final notificationService =
        Provider.of<NotificationService>(context, listen: false);
    notificationService.notifyMediaAction(action);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Media action: $action')),
    );
  }
}
