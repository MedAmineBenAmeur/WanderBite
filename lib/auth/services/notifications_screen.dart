import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:WanderBite/core/constants/app_constants.dart';
import 'package:WanderBite/auth/services/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  String? _selectedCategory;
  bool _isDescending = true;

  @override
  Widget build(BuildContext context) {
    final notificationService = Provider.of<NotificationService>(context);
    List<StoredNotification> notifications = _selectedCategory != null
        ? notificationService.getNotificationsByCategory(_selectedCategory!)
        : notificationService.getNotifications();

    if (_isDescending) {
      notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    } else {
      notifications.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon:
                Icon(_isDescending ? Icons.arrow_downward : Icons.arrow_upward),
            onPressed: () {
              setState(() {
                _isDescending = !_isDescending;
              });
            },
            tooltip: 'Sort ${_isDescending ? "Newest" : "Oldest"} First',
          ),
          if (notifications.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Clear Notifications'),
                    content: const Text(
                        'Are you sure you want to clear all notifications?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          notificationService.clearNotifications();
                          Navigator.pop(context);
                        },
                        child: const Text('Clear'),
                      ),
                    ],
                  ),
                );
              },
              tooltip: 'Clear All Notifications',
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                const Text('Filter: '),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _selectedCategory,
                  items: <String>['All', 'Media', 'Map', 'Event']
                      .map((String value) {
                    return DropdownMenuItem<String>(
                      value: value == 'All' ? null : value.toLowerCase(),
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedCategory = newValue;
                    });
                  },
                  hint: const Text('All'),
                ),
                const Spacer(),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Sound'),
                    Switch(
                      value: notificationService.isSoundEnabled,
                      onChanged: (value) => notificationService.toggleSound(),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Vibrate'),
                    Switch(
                      value: notificationService.isVibrationEnabled,
                      onChanged: (value) =>
                          notificationService.toggleVibration(),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: notifications.isEmpty
                ? const Center(
                    child: Text(
                      'No notifications available.',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final notification = notifications[index];
                      return Dismissible(
                        key: Key(notification.id.toString()),
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 16),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        direction: DismissDirection.endToStart,
                        onDismissed: (direction) {
                          notificationService
                              .deleteNotification(notification.id);
                        },
                        child: Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          child: ListTile(
                            leading: Icon(
                              _getIconForPayload(notification.payload),
                              color: Theme.of(context).primaryColor,
                            ),
                            title: Text(notification.title),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(notification.body),
                                const SizedBox(height: 4),
                                Text(
                                  DateFormat.yMMMd()
                                      .add_jm()
                                      .format(notification.timestamp),
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            onTap: () =>
                                _handleNotificationTap(context, notification),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForPayload(String? payload) {
    switch (payload) {
      case 'media':
        return Icons.perm_media;
      case 'map':
        return Icons.map;
      case 'event':
        return Icons.calendar_today;
      default:
        return Icons.notifications;
    }
  }

  void _handleNotificationTap(
      BuildContext context, StoredNotification notification) {
    String? route;
    switch (notification.payload) {
      case 'media':
        route = AppConstants.multimediaRoute;
        break;
      case 'map':
        route = AppConstants.mapsRoute;
        break;
      case 'event':
        route = AppConstants.calendarRoute;
        break;
    }
    if (route != null) {
      Navigator.pushNamed(context, route);
    }
  }
}
