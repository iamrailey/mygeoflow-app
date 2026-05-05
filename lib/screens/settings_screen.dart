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
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                    (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text(
              'Logout',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.grey.shade100,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: false,
      ),
      body: ListView(
        children: [

          // ── PROFILE SECTION ──
          _sectionLabel('PROFILE'),
          Container(
            color: Colors.white,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              leading: CircleAvatar(
                radius: 24,
                backgroundColor: Colors.purple.shade100,
                child: Icon(
                  Icons.person,
                  color: Colors.purple.shade400,
                  size: 28,
                ),
              ),
              title: const Text(
                'User Name',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              subtitle: const Text(
                'user@email.com',
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 13,
                ),
              ),
              trailing: const Icon(
                Icons.chevron_right,
                color: Colors.black38,
              ),
              onTap: () => Navigator.pushNamed(context, '/profile'),
            ),
          ),

          const SizedBox(height: 20),

          // ── PREFERENCES SECTION ──
          _sectionLabel('PREFERENCES'),
          Container(
            color: Colors.white,
            child: Column(
              children: [
                // Notifications toggle
                ListTile(
                  leading: const Icon(
                    Icons.notifications_outlined,
                    color: Colors.black87,
                  ),
                  title: const Text(
                    'Notifications',
                    style: TextStyle(fontSize: 15),
                  ),
                  subtitle: const Text(
                    'Receive push notifications',
                    style: TextStyle(fontSize: 12, color: Colors.black45),
                  ),
                  trailing: Switch(
                    value: _notificationsEnabled,
                    onChanged: (val) =>
                        setState(() => _notificationsEnabled = val),
                    activeColor: Colors.blue,
                  ),
                ),
                const Divider(height: 1, indent: 56),

                // Location Services toggle
                ListTile(
                  leading: const Icon(
                    Icons.location_on_outlined,
                    color: Colors.black87,
                  ),
                  title: const Text(
                    'Location Services',
                    style: TextStyle(fontSize: 15),
                  ),
                  subtitle: const Text(
                    'Enable GPS for accurate reports',
                    style: TextStyle(fontSize: 12, color: Colors.black45),
                  ),
                  trailing: Switch(
                    value: _locationEnabled,
                    onChanged: (val) =>
                        setState(() => _locationEnabled = val),
                    activeColor: Colors.blue,
                  ),
                ),
                const Divider(height: 1, indent: 56),

                // App Theme toggle
                ListTile(
                  leading: const Icon(
                    Icons.contrast,
                    color: Colors.black87,
                  ),
                  title: const Text(
                    'App Theme',
                    style: TextStyle(fontSize: 15),
                  ),
                  subtitle: Text(
                    _darkTheme ? 'Dark mode' : 'Light mode',
                    style: const TextStyle(fontSize: 12, color: Colors.black45),
                  ),
                  trailing: Switch(
                    value: _darkTheme,
                    onChanged: (val) => setState(() => _darkTheme = val),
                    activeColor: Colors.blue,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── SUPPORT SECTION ──
          _sectionLabel('SUPPORT'),
          Container(
            color: Colors.white,
            child: ListTile(
              leading: const Icon(
                Icons.help_outline,
                color: Colors.black87,
              ),
              title: const Text(
                'Help & Support',
                style: TextStyle(fontSize: 15),
              ),
              trailing: const Icon(
                Icons.chevron_right,
                color: Colors.black38,
              ),
              onTap: () => Navigator.pushNamed(context, '/help'),

            ),
          ),

          const SizedBox(height: 8),

          // App version
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: RichText(
              text: const TextSpan(
                children: [
                  TextSpan(
                    text: 'v1.0.0  ',
                    style: TextStyle(
                      color: Colors.black45,
                      fontSize: 13,
                    ),
                  ),
                  TextSpan(
                    text: 'App Version',
                    style: TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          // ── LOGOUT BUTTON ──
          Container(
            color: Colors.white,
            child: ListTile(
              onTap: () => _logout(context),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.logout, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Logout',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w500,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.black45,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}