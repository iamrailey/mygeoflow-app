import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class PendingApprovalScreen extends StatefulWidget {
  const PendingApprovalScreen({super.key});

  @override
  State<PendingApprovalScreen> createState() => _PendingApprovalScreenState();
}

class _PendingApprovalScreenState extends State<PendingApprovalScreen> {
  bool _darkTheme = false;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _darkTheme = prefs.getBool('darkTheme') ?? false);
  }

  Color get _bgStart     => _darkTheme ? const Color(0xFF1A1A2E) : const Color(0xFFB3E5FC);
  Color get _bgMid       => _darkTheme ? const Color(0xFF16213E) : const Color(0xFFE1F5FE);
  Color get _bgEnd       => _darkTheme ? const Color(0xFF0F3460) : const Color(0xFFFFFFFF);
  Color get _titleColor  => _darkTheme ? const Color(0xFF90CAF9) : const Color(0xFF01579B);
  Color get _subtitleColor => _darkTheme ? const Color(0xFF64B5F6) : const Color(0xFF0277BD);
  Color get _cardBg      => _darkTheme ? const Color(0xFF1E2A3A) : Colors.white;
  Color get _cardBorder  => _darkTheme ? const Color(0xFF2A4A6B) : const Color(0xFF81D4FA);
  Color get _iconColor   => _darkTheme ? const Color(0xFF64B5F6) : const Color(0xFF0288D1);

  // Re-check approval status — if now approved, go to main screen.
  Future<void> _checkStatus(BuildContext context) async {
    setState(() => _checking = true);
    try {
      final status = await ApiService.getInspectorStatus();
      if (status == 'approved' && mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/main', (route) => false);
        return;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              status == 'rejected'
                  ? 'Your application has been rejected. Contact your administrator.'
                  : 'Still pending approval. Please check back later.',
            ),
            backgroundColor: status == 'rejected' ? Colors.red : _iconColor,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not check status. Please try again.')),
        );
      }
    }
    if (mounted) setState(() => _checking = false);
  }

  Future<void> _logout(BuildContext context) async {
    await ApiService.logout();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
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
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: _iconColor.withOpacity(0.12),
                      shape: BoxShape.circle,
                      border: Border.all(color: _iconColor, width: 2),
                    ),
                    child: Icon(
                      Icons.hourglass_top_rounded,
                      size: 52,
                      color: _iconColor,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Title
                  Text(
                    'Awaiting Approval',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: _titleColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),

                  // Subtitle
                  Text(
                    'Your inspector account is pending review by an administrator. '
                    'You will be notified once your account is approved.',
                    style: TextStyle(
                      fontSize: 14,
                      color: _subtitleColor,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),

                  // Info card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _cardBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _cardBorder, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0288D1).withOpacity(0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _infoRow(Icons.check_circle_outline, 'Account registered successfully'),
                        const SizedBox(height: 12),
                        _infoRow(Icons.pending_outlined, 'Waiting for admin review'),
                        const SizedBox(height: 12),
                        _infoRow(Icons.notifications_outlined, 'You will be notified on approval'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Check status button
                  SizedBox(
                    width: double.infinity,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [const Color(0xFF29B6F6), _iconColor],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: _iconColor.withOpacity(0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _checking ? null : () => _checkStatus(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: _checking
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Check Approval Status',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Logout button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => _logout(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: _cardBorder, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'Logout',
                        style: TextStyle(
                          color: _subtitleColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: _iconColor),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: _subtitleColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
