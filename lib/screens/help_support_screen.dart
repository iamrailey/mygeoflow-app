import 'package:flutter/material.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

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
          'Help & Support',
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
          // Blue banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            color: Colors.blue,
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'How can we help you?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  "We're here to assist you with any questions or issues you may have.",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Support options
          Container(
            color: Colors.white,
            child: Column(
              children: [
                _buildSupportTile(
                  icon: Icons.chat_bubble_outline,
                  iconColor: Colors.blue,
                  title: 'FAQs',
                  subtitle: 'Find answers to common questions',
                  onTap: () {},
                ),
                const Divider(height: 1, indent: 56),
                _buildSupportTile(
                  icon: Icons.email_outlined,
                  iconColor: Colors.green,
                  title: 'Email Support',
                  subtitle: 'support@geoflow.com',
                  onTap: () {},
                ),
                const Divider(height: 1, indent: 56),
                _buildSupportTile(
                  icon: Icons.phone_outlined,
                  iconColor: Colors.orange,
                  title: 'Phone Support',
                  subtitle: '1-800-GEO-FLOW',
                  onTap: () {},
                ),
                const Divider(height: 1, indent: 56),
                _buildSupportTile(
                  icon: Icons.chat_outlined,
                  iconColor: Colors.purple,
                  title: 'Live Chat',
                  subtitle: 'Chat with our support team',
                  onTap: () {},
                ),
                const Divider(height: 1, indent: 56),
                _buildSupportTile(
                  icon: Icons.description_outlined,
                  iconColor: Colors.blueGrey,
                  title: 'User Guide',
                  subtitle: 'Learn how to use GeoFlow',
                  onTap: () {},
                ),
                const Divider(height: 1, indent: 56),
                _buildSupportTile(
                  icon: Icons.open_in_new,
                  iconColor: Colors.blue,
                  title: 'Report a Bug',
                  subtitle: 'Let us know about any issues',
                  onTap: () {},
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // About GeoFlow section
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(20),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'About GeoFlow',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Version: 1.0.0',
                  style: TextStyle(fontSize: 13, color: Colors.black54),
                ),
                SizedBox(height: 4),
                Text(
                  'Last Updated: April 2026',
                  style: TextStyle(fontSize: 13, color: Colors.black54),
                ),
                SizedBox(height: 4),
                Text(
                  '© 2026 GeoFlow. All rights reserved.',
                  style: TextStyle(fontSize: 13, color: Colors.black54),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSupportTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Icon(icon, color: iconColor, size: 24),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: Colors.black45),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.black38),
      onTap: onTap,
    );
  }
}