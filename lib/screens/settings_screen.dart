import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _locationEnabled = true;
  bool _darkTheme = false;

  void _logout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
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
                  // Cancel
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 28, vertical: 12),
                      side: const BorderSide(
                          color: Color(0xFF0288D1), width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        color: Color(0xFF0288D1),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  // Logout
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
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Logout',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
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
              // ── Custom AppBar ──────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 4.0, vertical: 8.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back,
                          color: Color(0xFF01579B)),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text(
                      'Settings',
                      style: TextStyle(
                        color: Color(0xFF01579B),
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
                        color: Colors.white.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: const Color(0xFF81D4FA), width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0288D1).withOpacity(0.07),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: const CircleAvatar(
                          radius: 24,
                          backgroundColor: Color(0xFFB3E5FC),
                          child: Icon(
                            Icons.person,
                            color: Color(0xFF0288D1),
                            size: 28,
                          ),
                        ),
                        title: const Text(
                          'User Name',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Color(0xFF01579B),
                          ),
                        ),
                        subtitle: const Text(
                          'user@email.com',
                          style: TextStyle(
                            color: Color(0xFF0277BD),
                            fontSize: 13,
                          ),
                        ),
                        trailing: const Icon(
                          Icons.chevron_right,
                          color: Color(0xFF0288D1),
                        ),
                        onTap: () =>
                            Navigator.pushNamed(context, '/profile'),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── PREFERENCES SECTION ──────────────────────────
                    _sectionLabel('PREFERENCES'),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: const Color(0xFF81D4FA), width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0288D1).withOpacity(0.07),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Notifications toggle
                          ListTile(
                            leading: const Icon(
                              Icons.notifications_outlined,
                              color: Color(0xFF0288D1),
                            ),
                            title: const Text(
                              'Notifications',
                              style: TextStyle(
                                fontSize: 15,
                                color: Color(0xFF01579B),
                              ),
                            ),
                            subtitle: const Text(
                              'Receive push notifications',
                              style: TextStyle(
                                  fontSize: 12, color: Color(0xFF0277BD)),
                            ),
                            trailing: Switch(
                              value: _notificationsEnabled,
                              onChanged: (val) =>
                                  setState(() => _notificationsEnabled = val),
                              activeColor: const Color(0xFF0288D1),
                            ),
                          ),
                          const Divider(
                              height: 1,
                              indent: 56,
                              color: Color(0xFFB3E5FC)),

                          // Location Services toggle
                          ListTile(
                            leading: const Icon(
                              Icons.location_on_outlined,
                              color: Color(0xFF0288D1),
                            ),
                            title: const Text(
                              'Location Services',
                              style: TextStyle(
                                fontSize: 15,
                                color: Color(0xFF01579B),
                              ),
                            ),
                            subtitle: const Text(
                              'Enable GPS for accurate reports',
                              style: TextStyle(
                                  fontSize: 12, color: Color(0xFF0277BD)),
                            ),
                            trailing: Switch(
                              value: _locationEnabled,
                              onChanged: (val) =>
                                  setState(() => _locationEnabled = val),
                              activeColor: const Color(0xFF0288D1),
                            ),
                          ),
                          const Divider(
                              height: 1,
                              indent: 56,
                              color: Color(0xFFB3E5FC)),

                          // App Theme toggle
                          ListTile(
                            leading: const Icon(
                              Icons.contrast,
                              color: Color(0xFF0288D1),
                            ),
                            title: const Text(
                              'App Theme',
                              style: TextStyle(
                                fontSize: 15,
                                color: Color(0xFF01579B),
                              ),
                            ),
                            subtitle: Text(
                              _darkTheme ? 'Dark mode' : 'Light mode',
                              style: const TextStyle(
                                  fontSize: 12, color: Color(0xFF0277BD)),
                            ),
                            trailing: Switch(
                              value: _darkTheme,
                              onChanged: (val) =>
                                  setState(() => _darkTheme = val),
                              activeColor: const Color(0xFF0288D1),
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
                        color: Colors.white.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: const Color(0xFF81D4FA), width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0288D1).withOpacity(0.07),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListTile(
                        leading: const Icon(
                          Icons.help_outline,
                          color: Color(0xFF0288D1),
                        ),
                        title: const Text(
                          'Help & Support',
                          style: TextStyle(
                            fontSize: 15,
                            color: Color(0xFF01579B),
                          ),
                        ),
                        trailing: const Icon(
                          Icons.chevron_right,
                          color: Color(0xFF0288D1),
                        ),
                        onTap: () =>
                            Navigator.pushNamed(context, '/help'),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // App version
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 8),
                      child: RichText(
                        text: const TextSpan(
                          children: [
                            TextSpan(
                              text: 'v1.0.0  ',
                              style: TextStyle(
                                color: Color(0xFF81D4FA),
                                fontSize: 13,
                              ),
                            ),
                            TextSpan(
                              text: 'App Version',
                              style: TextStyle(
                                color: Color(0xFF0277BD),
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
                        color: Colors.white.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: Colors.red.shade200, width: 1),
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
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFF0288D1),
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}