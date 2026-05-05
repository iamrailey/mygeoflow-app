import 'package:flutter/material.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  final List<Map<String, dynamic>> _notifications = const [
    {
      'title': 'Report Submitted',
      'message': 'Your leak report has been successfully submitted.',
      'time': 'Just now',
      'icon': Icons.check_circle,
      'color': Colors.blue,
      'isRead': false,
    },
    {
      'title': 'Report Under Review',
      'message': 'Your submitted leak is currently being reviewed by the utility team.',
      'time': 'Just now',
      'icon': Icons.access_time,
      'color': Colors.orange,
      'isRead': false,
    },
    {
      'title': 'Leak Verified',
      'message': 'The reported leak has been verified and marked as valid.',
      'time': 'Today, 10:30 AM',
      'icon': Icons.check_circle,
      'color': Colors.green,
      'isRead': true,
    },
    {
      'title': 'Leak Resolved',
      'message': 'The reported leak has been successfully resolved.',
      'time': 'Yesterday',
      'icon': Icons.check_circle,
      'color': Colors.red,
      'isRead': true,
    },
    {
      'title': 'Location Required',
      'message': 'Please enable GPS to submit accurate leak reports.',
      'time': 'Yesterday',
      'icon': Icons.location_on,
      'color': Colors.red,
      'isRead': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const Padding(
          padding: EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: Colors.grey,
            child: Icon(Icons.person, color: Colors.white),
          ),
        ),
        title: Image.asset('assets/logo.png', height: 40),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.black),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Header row
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Notifications',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text(
                    'Mark all as read',
                    style: TextStyle(color: Colors.black54),
                  ),
                ),
              ],
            ),
          ),

          // Notification list
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _notifications.length,
              separatorBuilder: (context, index) =>
              const Divider(height: 1, color: Colors.black12),
              itemBuilder: (context, index) {
                final notif = _notifications[index];
                return Container(
                  color: notif['isRead'] ? Colors.white : Colors.blue.shade50,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 4,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: (notif['color'] as Color).withValues(alpha: 0.15),
                      child: Icon(
                        notif['icon'] as IconData,
                        color: notif['color'] as Color,
                        size: 22,
                      ),
                    ),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          notif['title'],
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: notif['isRead']
                                ? FontWeight.normal
                                : FontWeight.bold,
                          ),
                        ),
                        Text(
                          notif['time'],
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.black45,
                          ),
                        ),
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        notif['message'],
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // No new notifications label
          const Padding(
            padding: EdgeInsets.all(12.0),
            child: Text(
              'No new notifications yet',
              style: TextStyle(
                fontSize: 12,
                color: Colors.black38,
              ),
            ),
          ),
        ],
      ),
    );
  }
}