import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:flutter/material.dart';

class NotificationService extends ChangeNotifier {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final _notificationsPlugin = AwesomeNotifications();
  List<StoredNotification> _notifications = [];
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;

  Future<void> initialize() async {
    try {
      await _notificationsPlugin.initialize(
        null,
        [
          NotificationChannel(
            channelKey: 'basic_channel',
            channelName: 'Basic Notifications',
            channelDescription: 'Channel for basic notifications',
            defaultColor: Colors.blue,
            ledColor: Colors.blue,
            importance: NotificationImportance.High,
            enableVibration: true,
          )
        ],
        debug: true,
      );
      
      await _notificationsPlugin.setListeners(
        onActionReceivedMethod: _onActionReceivedMethod,
      );

      await _loadNotifications();
      await _loadSettings();
    } catch (e) {
      print('Error initializing notifications: $e');
    }
  }

  @pragma('vm:entry-point')
  static Future<void> _onActionReceivedMethod(ReceivedAction receivedAction) async {
    final payload = receivedAction.payload;
    if (payload != null) {
      // Handle the action
      print('Notification action received: ${receivedAction.buttonKeyPressed}');
      print('Payload: $payload');
    }
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _soundEnabled = prefs.getBool('notification_sound') ?? true;
      _vibrationEnabled = prefs.getBool('notification_vibration') ?? true;
    } catch (e) {
      print('Error loading notification settings: $e');
    }
  }

  Future<void> saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notification_sound', _soundEnabled);
      await prefs.setBool('notification_vibration', _vibrationEnabled);
    } catch (e) {
      print('Error saving notification settings: $e');
    }
  }

  void toggleSound() {
    _soundEnabled = !_soundEnabled;
    saveSettings();
    notifyListeners();
  }

  void toggleVibration() {
    _vibrationEnabled = !_vibrationEnabled;
    saveSettings();
    notifyListeners();
  }

  bool get isSoundEnabled => _soundEnabled;
  bool get isVibrationEnabled => _vibrationEnabled;

  Future<void> _loadNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = prefs.getString('notifications');
      if (notificationsJson != null) {
        final List<dynamic> decoded = jsonDecode(notificationsJson);
        _notifications =
            decoded.map((item) => StoredNotification.fromJson(item)).toList();
      }
    } catch (e) {
      print('Error loading notifications: $e');
    }
  }

  Future<void> _saveNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson =
          jsonEncode(_notifications.map((n) => n.toJson()).toList());
      await prefs.setString('notifications', notificationsJson);
    } catch (e) {
      print('Error saving notifications: $e');
    }
  }

  List<StoredNotification> getNotifications() => _notifications;

  List<StoredNotification> getNotificationsByCategory(String category) {
    return _notifications.where((n) => n.payload == category).toList();
  }

  void deleteNotification(int id) {
    _notifications.removeWhere((n) => n.id == id);
    _saveNotifications();
    notifyListeners();
  }

  void clearNotifications() {
    _notifications.clear();
    _saveNotifications();
    notifyListeners();
  }

  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      final id = DateTime.now().millisecondsSinceEpoch.remainder(100000);
      await _notificationsPlugin.createNotification(
        content: NotificationContent(
          id: id,
          channelKey: 'basic_channel',
          title: title,
          body: body,
          payload: {'data': payload ?? ''},
          notificationLayout: NotificationLayout.Default,
          category: NotificationCategory.Message,
        ),
        actionButtons: [
          NotificationActionButton(
            key: 'DISMISS',
            label: 'Dismiss',
            actionType: ActionType.DismissAction,
          ),
        ],
      );
      
      final notification = StoredNotification(
        id: id,
        title: title,
        body: body,
        payload: payload,
        timestamp: DateTime.now(),
      );
      _notifications.insert(0, notification);
      await _saveNotifications();
      notifyListeners();
    } catch (e) {
      print('Error showing notification: $e');
    }
  }

  void notifyMediaAction(String action) {
    showNotification(
      title: 'Media Update',
      body: 'Media action: $action',
      payload: 'media',
    );
  }

  void notifyMapAction(String action) {
    showNotification(
      title: 'Map Update',
      body: 'Map action: $action',
      payload: 'map',
    );
  }

  void notifyEventAction(String action) {
    showNotification(
      title: 'Event Update',
      body: 'Event action: $action',
      payload: 'event',
    );
  }
}

class StoredNotification {
  final int id;
  final String title;
  final String body;
  final String? payload;
  final DateTime timestamp;

  StoredNotification({
    required this.id,
    required this.title,
    required this.body,
    this.payload,
    required this.timestamp,
  });

  factory StoredNotification.fromJson(Map<String, dynamic> json) {
    return StoredNotification(
      id: json['id'],
      title: json['title'],
      body: json['body'],
      payload: json['payload'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'payload': payload,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
