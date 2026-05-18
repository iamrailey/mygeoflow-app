import 'package:flutter/material.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  void _showFAQs(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'FAQs',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Q: How do I report a leak?',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              SizedBox(height: 4),
              Text(
                'A: Tap the Report Leak tab, take a photo of the leak, fill in your details, and submit.',
                style: TextStyle(fontSize: 13, color: Colors.black54),
              ),
              SizedBox(height: 12),
              Text(
                'Q: How accurate is the location tagging?',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              SizedBox(height: 4),
              Text(
                'A: Location is based on your GPS coordinates. Make sure Location Services is enabled for best accuracy.',
                style: TextStyle(fontSize: 13, color: Colors.black54),
              ),
              SizedBox(height: 12),
              Text(
                'Q: What happens after I submit a report?',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              SizedBox(height: 4),
              Text(
                'A: Your report will be reviewed by the utility team. You will receive a notification once it is verified or resolved.',
                style: TextStyle(fontSize: 13, color: Colors.black54),
              ),
              SizedBox(height: 12),
              Text(
                'Q: Can I edit a submitted report?',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              SizedBox(height: 4),
              Text(
                'A: No, submitted reports cannot be edited. Please contact support to make changes.',
                style: TextStyle(fontSize: 13, color: Colors.black54),
              ),
              SizedBox(height: 12),
              Text(
                'Q: Why is GPS required?',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              SizedBox(height: 4),
              Text(
                'A: GPS is required to accurately pinpoint the leak location on the map for the utility team.',
                style: TextStyle(fontSize: 13, color: Colors.black54),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showEmailSupport(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Email Support',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Send us an email and we\'ll get back to you as soon as possible.',
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.email_outlined, color: Colors.green, size: 20),
                SizedBox(width: 8),
                Text(
                  'supportgeoflow@gmail.com',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showPhoneSupport(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Phone Support',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Call us during business hours (8AM - 5PM, Mon-Fri).',
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.phone_outlined, color: Colors.orange, size: 20),
                SizedBox(width: 8),
                Text(
                  '09452779447',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.phone_outlined, color: Colors.orange, size: 20),
                SizedBox(width: 8),
                Text(
                  '09270633376',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.phone_outlined, color: Colors.orange, size: 20),
                SizedBox(width: 8),
                Text(
                  '09219691163',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showUserGuide(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'User Guide',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'How to use GeoFlow:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              SizedBox(height: 12),
              _GuideStep(number: '1', text: 'Register or login to your account.'),
              _GuideStep(number: '2', text: 'Tap Report Leak to take a photo of the leak.'),
              _GuideStep(number: '3', text: 'Fill in your Full Name and Contact Number.'),
              _GuideStep(number: '4', text: 'Tap Submit Report to send your report.'),
              _GuideStep(number: '5', text: 'Check Manage Leaks to track your report status.'),
              _GuideStep(number: '6', text: 'Check Notifications for updates on your report.'),
              _GuideStep(number: '7', text: 'Go to Settings to update your profile or logout.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
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
                  style: TextStyle(color: Colors.white, fontSize: 13),
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
                  onTap: () => _showFAQs(context),
                ),
                const Divider(height: 1, indent: 56),
                _buildSupportTile(
                  icon: Icons.email_outlined,
                  iconColor: Colors.green,
                  title: 'Email Support',
                  subtitle: 'supportgeoflow@gmail.com',
                  onTap: () => _showEmailSupport(context),
                ),
                const Divider(height: 1, indent: 56),
                _buildSupportTile(
                  icon: Icons.phone_outlined,
                  iconColor: Colors.orange,
                  title: 'Phone Support',
                  subtitle: '09452779447 / 09270633376 / 09219691163',
                  onTap: () => _showPhoneSupport(context),
                ),
                const Divider(height: 1, indent: 56),
                _buildSupportTile(
                  icon: Icons.description_outlined,
                  iconColor: Colors.blueGrey,
                  title: 'User Guide',
                  subtitle: 'Learn how to use GeoFlow',
                  onTap: () => _showUserGuide(context),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // About GeoFlow
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
                Text('Version: 1.0.0',
                    style: TextStyle(fontSize: 13, color: Colors.black54)),
                SizedBox(height: 4),
                Text('Last Updated: April 2026',
                    style: TextStyle(fontSize: 13, color: Colors.black54)),
                SizedBox(height: 4),
                Text('© 2026 GeoFlow. All rights reserved.',
                    style: TextStyle(fontSize: 13, color: Colors.black54)),
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
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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

class _GuideStep extends StatelessWidget {
  final String number;
  final String text;

  const _GuideStep({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: Colors.blue,
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}