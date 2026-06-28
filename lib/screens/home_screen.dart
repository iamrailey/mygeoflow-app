import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'camera_screen.dart';
import '../services/api_service.dart';
import 'notifications_screen.dart';
import 'package:http/http.dart' as http;

class HomeScreen extends StatefulWidget {
  final VoidCallback? onViewAssignments; // 👈 add this

  const HomeScreen({super.key, this.onViewAssignments}); // 👈 add this

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _unreadCount = 0;
  String _userName = 'User';
  String _userEmail = '';
  String? _avatarUrl;
  bool _snackbarShown = false;
  bool _darkTheme = false;

  @override
  void initState() {
    super.initState();
    _loadTheme();
    _fetchUserProfile();
    _fetchUnreadCount();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _darkTheme = prefs.getBool('darkTheme') ?? false);
  }

  Color get _bgStart      => _darkTheme ? const Color(0xFF1A1A2E) : const Color(0xFFB3E5FC);
  Color get _bgMid        => _darkTheme ? const Color(0xFF16213E) : const Color(0xFFE1F5FE);
  Color get _bgEnd        => _darkTheme ? const Color(0xFF0F3460) : const Color(0xFFFFFFFF);
  Color get _titleColor   => _darkTheme ? const Color(0xFF90CAF9) : const Color(0xFF01579B);
  Color get _subtitleColor=> _darkTheme ? const Color(0xFF64B5F6) : const Color(0xFF0277BD);
  Color get _cardBg       => _darkTheme ? const Color(0xFF1E2A3A) : Colors.white.withOpacity(0.85);
  Color get _cardBorder   => _darkTheme ? const Color(0xFF2A4A6B) : const Color(0xFF81D4FA);
  Color get _iconColor    => _darkTheme ? const Color(0xFF64B5F6) : const Color(0xFF0288D1);
  Color get _sheetHandle  => _darkTheme ? const Color(0xFF2A4A6B) : const Color(0xFF81D4FA);

  List<Color> get _gradientColors => [_bgStart, _bgMid, _bgEnd];

  @override
  void dispose() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }
    });
    super.dispose();
  }

  Future<void> _fetchUserProfile() async {
    try {
      final token = await ApiService.getToken();
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/user'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _userName = data['name'] ?? 'User';
          _userEmail = data['email'] ?? '';

          // Fix relative avatar URLs
          final raw = data['avatar_url']?.toString() ?? '';
          if (raw.isEmpty) {
            _avatarUrl = null;
          } else if (raw.startsWith('http')) {
            _avatarUrl = raw;
          } else {
            // e.g. "avatars/filename.jpg" → full URL
            _avatarUrl = 'https://geoflow.duckdns.org/storage/$raw';
          }
        });

        final hasNoPhone = data['phone'] == null || data['phone'].toString().isEmpty;
        if (hasNoPhone && mounted && !_snackbarShown) {
          _snackbarShown = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            // ← FIX: capture context into a local variable at the point
            // the callback fires, so the SnackBarAction closure holds
            // the live BuildContext rather than a potentially stale one.
            final ctx = context;
            ScaffoldMessenger.of(ctx).showSnackBar(
              SnackBar(
                content: const Row(
                  children: [
                    Icon(Icons.phone_outlined, color: Colors.white, size: 18),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Please add your phone number for faster report follow-up.',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
                backgroundColor: const Color(0xFF0288D1),
                duration: const Duration(seconds: 6),
                action: SnackBarAction(
                  label: 'Add Now',
                  textColor: Colors.white,
                  onPressed: () {
                    // ← FIX: use Navigator.of(ctx) instead of
                    // Navigator.pushNamed(context, ...) so we're
                    // navigating on the correct live context.
                    Navigator.of(ctx).pushNamed('/profile');
                  },
                ),
              ),
            );
          });
        }
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

  Widget _buildAvatar({double radius = 20}) {
    final hasAvatar = _avatarUrl != null && _avatarUrl!.isNotEmpty;
    if (hasAvatar) {
      return ClipOval(
        child: Image.network(
          _avatarUrl!,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) {
            if (mounted) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) setState(() => _avatarUrl = null);
              });
            }
            return CircleAvatar(
              radius: radius,
              backgroundColor: const Color(0xFF0288D1),
              child: Icon(Icons.person, size: radius * 1.2, color: Colors.white),
            );
          },
        ),
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFF0288D1),
      child: Icon(Icons.person, size: radius * 1.2, color: Colors.white),
    );
  }

  Widget _buildNotifIcon() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(Icons.notifications_outlined, color: _iconColor),
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

  void _showProfileSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: _gradientColors,
              stops: const [0.0, 0.45, 1.0],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: _cardBorder, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0288D1).withOpacity(0.2),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: _sheetHandle,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildAvatar(radius: 36),
                  const SizedBox(height: 12),
                  Text(
                    _userName,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _titleColor,
                    ),
                  ),
                  Text(
                    _userEmail,
                    style: TextStyle(fontSize: 13, color: _subtitleColor),
                  ),
                  const SizedBox(height: 20),
                  _sheetTile(
                    icon: Icon(Icons.person_outline, color: _iconColor),
                    title: 'Edit Profile',
                    onTap: () async {
                      Navigator.pop(ctx);
                      await Navigator.pushNamed(context, '/profile');
                      _fetchUserProfile();
                    },
                  ),
                  const SizedBox(height: 10),
                  _sheetTile(
                    icon: _buildNotifIcon(),
                    title: 'Notifications',
                    onTap: () async {
                      Navigator.pop(ctx);
                      await Navigator.pushNamed(context, '/notifications');
                      _fetchUnreadCount();
                    },
                  ),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: _cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade200, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.07),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ListTile(
                      leading: Icon(Icons.logout, color: Colors.red.shade400),
                      title: Text(
                        'Logout',
                        style: TextStyle(
                          color: Colors.red.shade400,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(ctx);
                        _confirmLogout(context);
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sheetTile({
    required Widget icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _cardBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0288D1).withOpacity(0.07),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: icon,
        title: Text(
          title,
          style: TextStyle(
            color: _titleColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Icon(Icons.chevron_right, color: _iconColor),
        onTap: onTap,
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: _gradientColors,
              stops: const [0.0, 0.45, 1.0],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _cardBorder, width: 1.5),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.red.shade400,
                child: const Icon(Icons.logout, color: Colors.white, size: 22),
              ),
              const SizedBox(height: 16),
              Text(
                'Logout',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _titleColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Are you sure you want to logout?',
                style: TextStyle(fontSize: 13, color: _subtitleColor),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 28, vertical: 12),
                      side: BorderSide(color: _iconColor, width: 1.5),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                          color: _iconColor, fontWeight: FontWeight.w600),
                    ),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.red.shade400,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        ScaffoldMessenger.of(context).clearSnackBars();
                        Navigator.pop(context);
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/login',
                              (route) => false,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 28, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text(
                        'Logout',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: GestureDetector(
            onTap: () => _showProfileSheet(context),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                _buildAvatar(radius: 20),
                if (_unreadCount > 0)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        title: Image.asset('assets/logo.png', height: 40),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.settings_outlined, color: _iconColor),
            onPressed: () async {
              await Navigator.pushNamed(context, '/settings');
              _loadTheme();
            },
          ),
        ],
      ),
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: _gradientColors,
            stops: const [0.0, 0.45, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () => _showProfileSheet(context),
                    child: _buildAvatar(radius: 50),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Welcome $_userName!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: _titleColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ready to Report a Leak?',
                    style: TextStyle(fontSize: 16, color: _subtitleColor),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF29B6F6), Color(0xFF0288D1)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0288D1).withOpacity(0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CameraScreen(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Report Leak',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ),

                  if (widget.onViewAssignments != null) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: widget.onViewAssignments,
                        icon: const Icon(Icons.assignment_outlined),
                        label: const Text('View Assignments'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _iconColor,
                          side: BorderSide(color: _iconColor, width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}