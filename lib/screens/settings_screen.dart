import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _locationEnabled = true;
  bool _darkTheme = false;
  String _userName = 'User Name';
  String _userEmail = 'user@email.com';
  String? _avatarUrl; // ← ADDED

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications') ?? true;
      _locationEnabled = prefs.getBool('location') ?? true;
      _darkTheme = prefs.getBool('darkTheme') ?? false;
    });
  }

  Future<void> _savePreference(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
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

        String? avatar = data['avatar_url'];

        // FIX avatar URL
        if (avatar != null &&
            avatar.isNotEmpty &&
            !avatar.startsWith('http')) {
          avatar = 'https://geoflow.duckdns.org/storage/$avatar';
        }

        if (mounted) {
          setState(() {
            _userName = data['name'] ?? 'User Name';
            _userEmail = data['email'] ?? 'user@email.com';
            _avatarUrl = avatar;
          });
        }

        print('Avatar URL: $_avatarUrl');
      }
    } catch (e) {
      print('Profile Error: $e');
    }
  }

  void _logout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFB3E5FC),
                Color(0xFFE1F5FE),
                Color(0xFFFFFFFF),
              ],
              stops: [0.0, 0.45, 1.0],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF81D4FA), width: 1.5),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircleAvatar(
                radius: 24,
                backgroundColor: Color(0xFF0288D1),
                child: Icon(Icons.logout, color: Colors.white, size: 22),
              ),
              const SizedBox(height: 16),
              const Text(
                'Logout',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF01579B),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Are you sure you want to logout?',
                style: TextStyle(fontSize: 13, color: Color(0xFF0277BD)),
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
                      side: const BorderSide(
                          color: Color(0xFF0288D1), width: 1.5),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        color: Color(0xFF0288D1),
                        fontWeight: FontWeight.w600,
                      ),
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

  // ── Dark-mode aware colors ───────────────────────────────────────────────
  Color get _bgStart => _darkTheme ? const Color(0xFF1A1A2E) : const Color(0xFFB3E5FC);
  Color get _bgMid => _darkTheme ? const Color(0xFF16213E) : const Color(0xFFE1F5FE);
  Color get _bgEnd => _darkTheme ? const Color(0xFF0F3460) : const Color(0xFFFFFFFF);
  Color get _cardBg => _darkTheme ? const Color(0xFF1E2A3A) : Colors.white.withOpacity(0.85);
  Color get _cardBorder => _darkTheme ? const Color(0xFF2A4A6B) : const Color(0xFF81D4FA);
  Color get _titleColor => _darkTheme ? const Color(0xFF90CAF9) : const Color(0xFF01579B);
  Color get _subtitleColor => _darkTheme ? const Color(0xFF64B5F6) : const Color(0xFF0277BD);
  Color get _sectionColor => _darkTheme ? const Color(0xFF64B5F6) : const Color(0xFF0288D1);
  Color get _iconColor => _darkTheme ? const Color(0xFF64B5F6) : const Color(0xFF0288D1);
  Color get _dividerColor => _darkTheme ? const Color(0xFF2A4A6B) : const Color(0xFFB3E5FC);
  Color get _switchActive => _darkTheme ? const Color(0xFF64B5F6) : const Color(0xFF0288D1);

  // ── ADDED: builds the profile avatar (network image or fallback icon) ────
  Widget _buildAvatar() {
    return CircleAvatar(
      radius: 20,
      backgroundColor: _iconColor,
      backgroundImage:
      (_avatarUrl != null && _avatarUrl!.isNotEmpty)
          ? NetworkImage(_avatarUrl!)
          : null,
      child: (_avatarUrl == null || _avatarUrl!.isEmpty)
          ? const Icon(Icons.person, color: Colors.white)
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_bgStart, _bgMid, _bgEnd],
            stops: const [0.0, 0.45, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── Custom AppBar ──────────────────────────────────────
              Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: _titleColor),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Text(
                      'Settings',
                      style: TextStyle(
                        color: _titleColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Scrollable body ────────────────────────────────────
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 32),
                  children: [
                    // ── PROFILE SECTION ──────────────────────────────
                    _sectionLabel('PROFILE'),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: _cardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _cardBorder, width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: _iconColor.withOpacity(0.07),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        leading: _buildAvatar(), // ← CHANGED: was hardcoded Icons.person
                        title: Text(
                          _userName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: _titleColor,
                          ),
                        ),
                        subtitle: Text(
                          _userEmail,
                          style:
                          TextStyle(color: _subtitleColor, fontSize: 13),
                        ),
                        trailing: Icon(Icons.chevron_right, color: _iconColor),
                        onTap: () async {
                          await Navigator.pushNamed(context, '/profile');
                          _fetchUserProfile(); // ← refreshes avatar after editing
                        },
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── PREFERENCES SECTION ──────────────────────────
                    _sectionLabel('PREFERENCES'),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: _cardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _cardBorder, width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: _iconColor.withOpacity(0.07),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          ListTile(
                            leading: Icon(Icons.notifications_outlined,
                                color: _iconColor),
                            title: Text('Notifications',
                                style: TextStyle(
                                    fontSize: 15, color: _titleColor)),
                            subtitle: Text('Receive push notifications',
                                style: TextStyle(
                                    fontSize: 12, color: _subtitleColor)),
                            trailing: Switch(
                              value: _notificationsEnabled,
                              onChanged: (val) {
                                setState(() => _notificationsEnabled = val);
                                _savePreference('notifications', val);
                              },
                              activeColor: _switchActive,
                            ),
                          ),
                          Divider(
                              height: 1, indent: 56, color: _dividerColor),
                          ListTile(
                            leading: Icon(Icons.location_on_outlined,
                                color: _iconColor),
                            title: Text('Location Services',
                                style: TextStyle(
                                    fontSize: 15, color: _titleColor)),
                            subtitle: Text('Enable GPS for accurate reports',
                                style: TextStyle(
                                    fontSize: 12, color: _subtitleColor)),
                            trailing: Switch(
                              value: _locationEnabled,
                              onChanged: (val) {
                                setState(() => _locationEnabled = val);
                                _savePreference('location', val);
                              },
                              activeColor: _switchActive,
                            ),
                          ),
                          Divider(
                              height: 1, indent: 56, color: _dividerColor),
                          ListTile(
                            leading: Icon(Icons.contrast, color: _iconColor),
                            title: Text('App Theme',
                                style: TextStyle(
                                    fontSize: 15, color: _titleColor)),
                            subtitle: Text(
                              _darkTheme ? 'Dark mode' : 'Light mode',
                              style: TextStyle(
                                  fontSize: 12, color: _subtitleColor),
                            ),
                            trailing: Switch(
                              value: _darkTheme,
                              onChanged: (val) {
                                setState(() => _darkTheme = val);
                                _savePreference('darkTheme', val);
                              },
                              activeColor: _switchActive,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── SUPPORT SECTION ──────────────────────────────
                    _sectionLabel('SUPPORT'),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: _cardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _cardBorder, width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: _iconColor.withOpacity(0.07),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListTile(
                        leading: Icon(Icons.help_outline, color: _iconColor),
                        title: Text('Help & Support',
                            style:
                            TextStyle(fontSize: 15, color: _titleColor)),
                        trailing: Icon(Icons.chevron_right, color: _iconColor),
                        onTap: () => Navigator.pushNamed(context, '/help'),
                      ),
                    ),

                    const SizedBox(height: 8),

                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 8),
                      child: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'v1.0.0  ',
                              style: TextStyle(
                                  color: _sectionColor, fontSize: 13),
                            ),
                            TextSpan(
                              text: 'App Version',
                              style: TextStyle(
                                color: _subtitleColor,
                                fontWeight: FontWeight.w500,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // ── LOGOUT BUTTON ────────────────────────────────
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: _cardBg,
                        borderRadius: BorderRadius.circular(12),
                        border:
                        Border.all(color: Colors.red.shade200, width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.07),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListTile(
                        onTap: () => _logout(context),
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.logout,
                                color: Colors.red.shade400, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Logout',
                              style: TextStyle(
                                color: Colors.red.shade400,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
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
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 16, 6),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: _sectionColor,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}