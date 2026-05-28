import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  bool _darkTheme = false;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _darkTheme = prefs.getBool('darkTheme') ?? false);
  }

  // ── Dark-mode aware colors ───────────────────────────────────────────────
  Color get _scaffoldBg     => _darkTheme ? const Color(0xFF0F3460) : Colors.grey.shade100;
  Color get _appBarBg       => _darkTheme ? const Color(0xFF1A1A2E) : Colors.grey.shade100;
  Color get _appBarTitle    => _darkTheme ? const Color(0xFF90CAF9) : Colors.black;
  Color get _appBarIcon     => _darkTheme ? const Color(0xFF90CAF9) : Colors.black;
  Color get _bannerBg       => _darkTheme ? const Color(0xFF1A1A2E) : Colors.blue;
  Color get _cardBg         => _darkTheme ? const Color(0xFF1E2A3A) : Colors.white;
  Color get _cardBorder     => _darkTheme ? const Color(0xFF2A4A6B) : Colors.transparent;
  Color get _titleText      => _darkTheme ? const Color(0xFF90CAF9) : Colors.black87;
  Color get _subtitleText   => _darkTheme ? const Color(0xFF64B5F6) : Colors.black45;
  Color get _dividerColor   => _darkTheme ? const Color(0xFF2A4A6B) : Colors.grey.shade200;
  Color get _chevronColor   => _darkTheme ? const Color(0xFF64B5F6) : Colors.black38;
  Color get _aboutText      => _darkTheme ? const Color(0xFF90CAF9) : Colors.black87;
  Color get _aboutSubText   => _darkTheme ? const Color(0xFF64B5F6) : Colors.black54;

  // ── Dialog colors ────────────────────────────────────────────────────────
  Color get _dialogBg       => _darkTheme ? const Color(0xFF1E2A3A) : Colors.white;
  Color get _dialogTitle    => _darkTheme ? const Color(0xFF90CAF9) : Colors.black;
  Color get _dialogBody     => _darkTheme ? const Color(0xFF64B5F6) : Colors.black54;
  Color get _dialogBold     => _darkTheme ? const Color(0xFF90CAF9) : Colors.black87;
  Color get _dialogButton   => _darkTheme ? const Color(0xFF64B5F6) : Colors.blue;

  void _showFAQs(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _dialogBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: _cardBorder, width: 1),
        ),
        title: Text(
          'FAQs',
          style: TextStyle(fontWeight: FontWeight.bold, color: _dialogTitle),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Q: How do I report a leak?',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _dialogBold)),
              const SizedBox(height: 4),
              Text(
                'A: Tap the Report Leak tab, take a photo of the leak, fill in your details, and submit.',
                style: TextStyle(fontSize: 13, color: _dialogBody),
              ),
              const SizedBox(height: 12),
              Text('Q: How accurate is the location tagging?',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _dialogBold)),
              const SizedBox(height: 4),
              Text(
                'A: Location is based on your GPS coordinates. Make sure Location Services is enabled for best accuracy.',
                style: TextStyle(fontSize: 13, color: _dialogBody),
              ),
              const SizedBox(height: 12),
              Text('Q: What happens after I submit a report?',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _dialogBold)),
              const SizedBox(height: 4),
              Text(
                'A: Your report will be reviewed by the utility team. You will receive a notification once it is verified or resolved.',
                style: TextStyle(fontSize: 13, color: _dialogBody),
              ),
              const SizedBox(height: 12),
              Text('Q: Can I edit a submitted report?',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _dialogBold)),
              const SizedBox(height: 4),
              Text(
                'A: No, submitted reports cannot be edited. Please contact support to make changes.',
                style: TextStyle(fontSize: 13, color: _dialogBody),
              ),
              const SizedBox(height: 12),
              Text('Q: Why is GPS required?',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _dialogBold)),
              const SizedBox(height: 4),
              Text(
                'A: GPS is required to accurately pinpoint the leak location on the map for the utility team.',
                style: TextStyle(fontSize: 13, color: _dialogBody),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: _dialogButton)),
          ),
        ],
      ),
    );
  }

  void _showEmailSupport(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _dialogBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: _cardBorder, width: 1),
        ),
        title: Text(
          'Email Support',
          style: TextStyle(fontWeight: FontWeight.bold, color: _dialogTitle),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Send us an email and we'll get back to you as soon as possible.",
              style: TextStyle(fontSize: 13, color: _dialogBody),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.email_outlined, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Text(
                  'supportgeoflow@gmail.com',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _dialogBold,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: _dialogButton)),
          ),
        ],
      ),
    );
  }

  void _showPhoneSupport(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _dialogBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: _cardBorder, width: 1),
        ),
        title: Text(
          'Phone Support',
          style: TextStyle(fontWeight: FontWeight.bold, color: _dialogTitle),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Call us during business hours (8AM - 5PM, Mon-Fri).',
              style: TextStyle(fontSize: 13, color: _dialogBody),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.phone_outlined, color: Colors.orange, size: 20),
                const SizedBox(width: 8),
                Text('09452779447',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _dialogBold)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.phone_outlined, color: Colors.orange, size: 20),
                const SizedBox(width: 8),
                Text('09270633376',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _dialogBold)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.phone_outlined, color: Colors.orange, size: 20),
                const SizedBox(width: 8),
                Text('09219691163',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _dialogBold)),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: _dialogButton)),
          ),
        ],
      ),
    );
  }

  void _showUserGuide(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _dialogBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: _cardBorder, width: 1),
        ),
        title: Text(
          'User Guide',
          style: TextStyle(fontWeight: FontWeight.bold, color: _dialogTitle),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'How to use GeoFlow:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: _dialogBold),
              ),
              const SizedBox(height: 12),
              _GuideStep(number: '1', text: 'Register or login to your account.', darkTheme: _darkTheme),
              _GuideStep(number: '2', text: 'Tap Report Leak to take a photo of the leak.', darkTheme: _darkTheme),
              _GuideStep(number: '3', text: 'Fill in your Full Name and Contact Number.', darkTheme: _darkTheme),
              _GuideStep(number: '4', text: 'Tap Submit Report to send your report.', darkTheme: _darkTheme),
              _GuideStep(number: '5', text: 'Check Manage Leaks to track your report status.', darkTheme: _darkTheme),
              _GuideStep(number: '6', text: 'Check Notifications for updates on your report.', darkTheme: _darkTheme),
              _GuideStep(number: '7', text: 'Go to Settings to update your profile or logout.', darkTheme: _darkTheme),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: _dialogButton)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _scaffoldBg,
      appBar: AppBar(
        backgroundColor: _appBarBg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: _appBarIcon),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Help & Support',
          style: TextStyle(
            color: _appBarTitle,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: false,
      ),
      body: ListView(
        children: [
          // ── Blue / dark banner ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            color: _bannerBg,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'How can we help you?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "We're here to assist you with any questions or issues you may have.",
                  style: TextStyle(
                    color: _darkTheme ? const Color(0xFF90CAF9) : Colors.white,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Support options ──
          Container(
            decoration: BoxDecoration(
              color: _cardBg,
              border: Border.all(color: _cardBorder, width: 1),
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.symmetric(horizontal: 0),
            child: Column(
              children: [
                _buildSupportTile(
                  icon: Icons.chat_bubble_outline,
                  iconColor: Colors.blue,
                  title: 'FAQs',
                  subtitle: 'Find answers to common questions',
                  onTap: () => _showFAQs(context),
                ),
                Divider(height: 1, indent: 56, color: _dividerColor),
                _buildSupportTile(
                  icon: Icons.email_outlined,
                  iconColor: Colors.green,
                  title: 'Email Support',
                  subtitle: 'supportgeoflow@gmail.com',
                  onTap: () => _showEmailSupport(context),
                ),
                Divider(height: 1, indent: 56, color: _dividerColor),
                _buildSupportTile(
                  icon: Icons.phone_outlined,
                  iconColor: Colors.orange,
                  title: 'Phone Support',
                  subtitle: '09452779447 / 09270633376 / 09219691163',
                  onTap: () => _showPhoneSupport(context),
                ),
                Divider(height: 1, indent: 56, color: _dividerColor),
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

          // ── About GeoFlow ──
          Container(
            decoration: BoxDecoration(
              color: _cardBg,
              border: Border.all(color: _cardBorder, width: 1),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'About GeoFlow',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: _aboutText,
                  ),
                ),
                const SizedBox(height: 10),
                Text('Version: 1.0.0',
                    style: TextStyle(fontSize: 13, color: _aboutSubText)),
                const SizedBox(height: 4),
                Text('Last Updated: April 2026',
                    style: TextStyle(fontSize: 13, color: _aboutSubText)),
                const SizedBox(height: 4),
                Text('© 2026 GeoFlow. All rights reserved.',
                    style: TextStyle(fontSize: 13, color: _aboutSubText)),
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
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: _titleText,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12, color: _subtitleText),
      ),
      trailing: Icon(Icons.chevron_right, color: _chevronColor),
      onTap: onTap,
    );
  }
}

class _GuideStep extends StatelessWidget {
  final String number;
  final String text;
  final bool darkTheme;

  const _GuideStep({
    required this.number,
    required this.text,
    required this.darkTheme,
  });

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
              style: TextStyle(
                fontSize: 13,
                color: darkTheme ? const Color(0xFF90CAF9) : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}