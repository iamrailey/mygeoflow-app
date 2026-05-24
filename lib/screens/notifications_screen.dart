import 'package:flutter/material.dart';
import 'dart:convert';
import '../services/api_service.dart';
import 'package:http/http.dart' as http;

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;
  String? _errorMessage;

  IconData _getIcon(String? type) {
    switch (type) {
      case 'submitted':
        return Icons.upload_file;
      case 'under_review':
        return Icons.access_time;
      case 'verified':
        return Icons.verified;
      case 'resolved':
        return Icons.check_circle;
      case 'location':
        return Icons.location_on;
      default:
        return Icons.notifications;
    }
  }

  Color _getColor(String? type) {
    switch (type) {
      case 'submitted':
        return Colors.blue;
      case 'under_review':
        return Colors.orange;
      case 'verified':
        return Colors.green;
      case 'resolved':
        return Colors.teal;
      case 'location':
        return Colors.red;
      default:
        return const Color(0xFF0288D1);
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = await ApiService.getToken();
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/notifications'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _notifications = data
              .map((item) => {
            'id': item['id'],
            'title': item['title'] ?? 'Notification',
            'message': item['message'] ?? '',
            'time': item['created_at'] ?? '',
            'type': item['type'] ?? '',
            'isRead': item['is_read'] == true || item['is_read'] == 1,
          })
              .toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load notifications.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Network error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      final token = await ApiService.getToken();
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/notifications/mark-all-read'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _notifications = _notifications.map((n) => {...n, 'isRead': true}).toList();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All notifications marked as read.'),
            backgroundColor: Color(0xFF0288D1),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to mark notifications as read.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _markOneAsRead(int index) async {
    final notif = _notifications[index];
    if (notif['isRead'] == true) return;

    // Optimistically mark as read immediately so UI responds instantly
    setState(() {
      _notifications[index] = {...notif, 'isRead': true};
    });

    try {
      final token = await ApiService.getToken();
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/notifications/${notif['id']}/mark-read'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      // If API call fails, revert the optimistic update
      if (response.statusCode != 200) {
        setState(() {
          _notifications[index] = {...notif, 'isRead': false};
        });
      }
    } catch (_) {
      // Revert on network error
      setState(() {
        _notifications[index] = {...notif, 'isRead': false};
      });
    }
  }

  String _formatTime(String raw) {
    try {
      final dt = DateTime.parse(raw).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);

      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) {
        final h = diff.inHours;
        final m = diff.inMinutes % 60;
        return m > 0 ? '${h}h ${m}m ago' : '${h}h ago';
      }
      if (diff.inDays == 1) return 'Yesterday';
      if (diff.inDays < 7) return '${diff.inDays} days ago';
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) => n['isRead'] == false).length;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFB3E5FC),
              Color(0xFFE1F5FE),
              Color(0xFFFFFFFF),
            ],
            stops: [0.0, 0.45, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── Custom AppBar ──────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                child: Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: Color(0xFF0288D1),
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                    const Spacer(),
                    Image.asset('assets/logo.png', height: 40),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.settings_outlined, color: Color(0xFF0288D1)),
                      onPressed: () => Navigator.pushNamed(context, '/settings'),
                    ),
                  ],
                ),
              ),

              // ── Header row ─────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Notifications',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF01579B),
                          ),
                        ),
                        if (unreadCount > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0288D1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$unreadCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.refresh, color: Color(0xFF0288D1), size: 20),
                          onPressed: _fetchNotifications,
                          tooltip: 'Refresh',
                        ),
                        TextButton(
                          onPressed: unreadCount > 0 ? _markAllAsRead : null,
                          child: Text(
                            'Mark all as read',
                            style: TextStyle(
                              color: unreadCount > 0
                                  ? const Color(0xFF0288D1)
                                  : const Color(0xFFB3E5FC),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Body ───────────────────────────────────────────────────
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFF0288D1)))
                    : _errorMessage != null
                    ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.wifi_off, color: Color(0xFF81D4FA), size: 48),
                      const SizedBox(height: 12),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: Color(0xFF0277BD)),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _fetchNotifications,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0288D1),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                )
                    : _notifications.isEmpty
                    ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.notifications_off,
                          color: Color(0xFF81D4FA), size: 48),
                      SizedBox(height: 12),
                      Text(
                        'No notifications yet',
                        style: TextStyle(color: Color(0xFF0277BD), fontSize: 14),
                      ),
                    ],
                  ),
                )
                    : RefreshIndicator(
                  color: const Color(0xFF0288D1),
                  onRefresh: _fetchNotifications,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _notifications.length,
                    separatorBuilder: (context, index) =>
                    const Divider(height: 1, color: Color(0xFF81D4FA)),
                    itemBuilder: (context, index) {
                      final notif = _notifications[index];
                      final bool isRead = notif['isRead'] as bool;
                      final String type = notif['type'] ?? '';

                      return Container(
                        decoration: BoxDecoration(
                          color: isRead
                              ? Colors.white.withOpacity(0.55)
                              : const Color(0xFFE1F5FE),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isRead
                                ? const Color(0xFFB3E5FC)
                                : const Color(0xFF81D4FA),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0288D1).withOpacity(0.07),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        // ✅ onTap is on ListTile directly — GestureDetector removed
                        child: ListTile(
                          onTap: () => _markOneAsRead(index),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 12,
                          ),
                          leading: CircleAvatar(
                            backgroundColor: _getColor(type).withOpacity(0.15),
                            child: Icon(
                              _getIcon(type),
                              color: _getColor(type),
                              size: 22,
                            ),
                          ),
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  notif['title'],
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: isRead
                                        ? FontWeight.normal
                                        : FontWeight.bold,
                                    color: const Color(0xFF01579B),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _formatTime(notif['time']),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF0288D1),
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
                                color: Color(0xFF0277BD),
                              ),
                            ),
                          ),
                          trailing: !isRead
                              ? Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: Color(0xFF0288D1),
                              shape: BoxShape.circle,
                            ),
                          )
                              : null,
                        ),
                      );
                    },
                  ),
                ),
              ),

              // ── Footer ─────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(
                  _notifications.isEmpty
                      ? 'No new notifications yet'
                      : '$unreadCount unread notification${unreadCount == 1 ? '' : 's'}',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF81D4FA)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}