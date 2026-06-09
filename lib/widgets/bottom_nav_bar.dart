import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../screens/home_screen.dart';
import '../screens/manage_leaks_screen.dart';
import '../screens/notifications_screen.dart';
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

  final List<Widget> _screens = [
    const HomeScreen(),
    const ManageLeaksScreen(),
    const NotificationsScreen(),
  ];

  @override
  @override
  void initState() {
    super.initState();
    _loadTheme();
    _fetchUnreadCount();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      _darkTheme = prefs.getBool('darkTheme') ?? false;
    });
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

  void _onTabTapped(int index) {
    setState(() => _currentIndex = index);
    // Refresh unread count when leaving notifications tab
    if (index != 2) {
      _fetchUnreadCount();
    } else {
      // Tapped notifications — clear badge optimistically, refresh after
      setState(() => _unreadCount = 0);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: _navBg,
          border: Border(
            top: BorderSide(
              color: _borderColor,
              width: 1,
            ),
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
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
          backgroundColor: _navBg,
          selectedItemColor: _selectedColor,
          unselectedItemColor: _unselectedColor,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          items: [
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
          ],
        ),
      ),
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

}