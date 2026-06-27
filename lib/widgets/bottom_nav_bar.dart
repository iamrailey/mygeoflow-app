import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../screens/home_screen.dart';
import '../screens/manage_leaks_screen.dart';
import '../screens/notifications_screen.dart';
import '../screens/assigned_reports_screen.dart';
import '../services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  int _unreadCount = 0;
  bool _darkTheme = false;
  String _userRole = 'reporter';

  @override
  void initState() {
    super.initState();
    _loadTheme();
    _fetchUnreadCount();
    _fetchUserRole();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _darkTheme = prefs.getBool('darkTheme') ?? false);
  }

  Future<void> _fetchUserRole() async {
    try {
      final token = await ApiService.getToken();
      final res = await http.get(
        Uri.parse('${ApiService.baseUrl}/user'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _userRole = data['role'] ?? 'reporter';
          // Clamp index in case we switched from a role with more tabs
          if (_currentIndex >= _screens.length) {
            _currentIndex = 0;
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _fetchUnreadCount() async {
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
          _unreadCount = data
              .where((n) => n['is_read'] == false || n['is_read'] == 0)
              .length;
        });
      }
    } catch (_) {}
  }

  bool get _isInspector => _userRole == 'inspector';

  // Smooth tab switch callback passed down to HomeScreen so inspectors
  // can jump straight to Assignments without rebuilding the whole stack.
  void _goToAssignments() {
    setState(() => _currentIndex = 1);
  }

  List<Widget> get _screens => _isInspector
      ? [
          HomeScreen(onViewAssignments: _goToAssignments),
          const AssignedReportsScreen(),
          const NotificationsScreen(),
        ]
      : [
          const HomeScreen(),
          const ManageLeaksScreen(),
          const NotificationsScreen(),
        ];

  void _onTabTapped(int index) {
    setState(() => _currentIndex = index);
    if (index == 2) {
      // Tapped notifications — clear badge optimistically
      setState(() => _unreadCount = 0);
    } else {
      _fetchUnreadCount();
    }
  }

  Widget _notifIcon() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        const Icon(Icons.notifications_outlined),
        if (_unreadCount > 0)
          Positioned(
            top: -4,
            right: -4,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
            ),
          ),
      ],
    );
  }

  Color get _navBg =>
      _darkTheme ? const Color(0xFF1E2A3A) : Colors.white;

  Color get _selectedColor =>
      _darkTheme ? const Color(0xFF64B5F6) : Colors.black;

  Color get _unselectedColor =>
      _darkTheme ? const Color(0xFF90A4AE) : Colors.grey;

  Color get _borderColor =>
      _darkTheme ? const Color(0xFF2A4A6B) : const Color(0xFFE0E0E0);

  @override
  Widget build(BuildContext context) {
    final items = _isInspector
        ? [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              label: 'Home',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.assignment_outlined),
              label: 'Assignments',
            ),
            BottomNavigationBarItem(
              icon: _notifIcon(),
              label: 'Notifications',
            ),
          ]
        : [
            const BottomNavigationBarItem(
              icon: Icon(Icons.camera_alt_outlined),
              label: 'Report Leak',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.edit_outlined),
              label: 'Manage Leaks',
            ),
            BottomNavigationBarItem(
              icon: _notifIcon(),
              label: 'Notifications',
            ),
          ];

    // Safety clamp — avoids index out of range if role loads after build
    final safeIndex = _currentIndex.clamp(0, items.length - 1);

    return Scaffold(
      body: _screens[safeIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: _navBg,
          border: Border(
            top: BorderSide(color: _borderColor, width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(_darkTheme ? 0.25 : 0.08),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: safeIndex,
          onTap: _onTabTapped,
          backgroundColor: _navBg,
          selectedItemColor: _selectedColor,
          unselectedItemColor: _unselectedColor,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          items: items,
        ),
      ),
    );
  }
}
