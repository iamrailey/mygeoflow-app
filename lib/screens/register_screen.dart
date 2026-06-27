import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController     = TextEditingController();
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController  = TextEditingController();

  String _selectedRole   = 'reporter';
  bool   _isLoading      = false;
  bool   _obscurePass    = true;
  bool   _obscureConfirm = true;

  // ── Theme colours (light only for auth screens) ────────────────────────
  static const Color _bgStart    = Color(0xFFB3E5FC);
  static const Color _bgMid      = Color(0xFFE1F5FE);
  static const Color _bgEnd      = Color(0xFFFFFFFF);
  static const Color _titleColor = Color(0xFF01579B);
  static const Color _subColor   = Color(0xFF0277BD);
  static const Color _iconColor  = Color(0xFF0288D1);
  static const Color _cardBorder = Color(0xFF81D4FA);

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final name     = _nameController.text.trim();
    final email    = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm  = _confirmController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty || confirm.isEmpty) {
      _snack('Please fill in all fields.');
      return;
    }
    if (password != confirm) {
      _snack('Passwords do not match.');
      return;
    }
    if (password.length < 8) {
      _snack('Password must be at least 8 characters.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final res = await http.post(
        Uri.parse('${ApiService.baseUrl}/register'),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({
          'name':                  name,
          'email':                 email,
          'password':              password,
          'password_confirmation': confirm,
          'role':                  _selectedRole,
        }),
      );

      final body = jsonDecode(res.body);

      if (res.statusCode == 200 || res.statusCode == 201) {
        // Save token and role
        final token            = body['token'];
        final role             = body['user']?['role'] ?? _selectedRole;
        final inspectorStatus  = body['user']?['inspector_status'];

        await ApiService.saveToken(token);
        await ApiService.saveRole(role);
        if (inspectorStatus != null) {
          await ApiService.saveInspectorStatus(inspectorStatus);
        }

        if (!mounted) return;

        if (role == 'inspector') {
          // Inspectors need admin approval before they can use the app
          Navigator.pushNamedAndRemoveUntil(
            context, '/pending-approval', (route) => false,
          );
        } else {
          Navigator.pushNamedAndRemoveUntil(
            context, '/main', (route) => false,
          );
        }
      } else {
        final message = body['message'] ??
            (body['errors'] != null
                ? (body['errors'] as Map).values.first[0]
                : 'Registration failed.');
        _snack(message);
      }
    } catch (e) {
      _snack('Error: $e');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_bgStart, _bgMid, _bgEnd],
            stops: [0.0, 0.45, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  Image.asset('assets/logo.png', height: 72),
                  const SizedBox(height: 20),

                  Text(
                    'Create Account',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: _titleColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Sign up to get started',
                    style: TextStyle(fontSize: 14, color: _subColor),
                  ),
                  const SizedBox(height: 32),

                  // ── Role selector ─────────────────────────────────────────
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _cardBorder, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: _iconColor.withOpacity(0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        _roleTab('reporter', Icons.person_outlined, 'Reporter'),
                        _roleTab('inspector', Icons.search_outlined, 'Inspector'),
                      ],
                    ),
                  ),

                  // Role description hint
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 16),
                    child: Text(
                      _selectedRole == 'reporter'
                          ? 'Reporters can submit and track leak reports.'
                          : 'Inspectors review and verify assigned reports.\nRequires admin approval.',
                      style: const TextStyle(fontSize: 12, color: _subColor),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  // ── Form fields ───────────────────────────────────────────
                  _field(
                    controller: _nameController,
                    hint: 'Full Name',
                    icon: Icons.person_outlined,
                  ),
                  const SizedBox(height: 14),

                  _field(
                    controller: _emailController,
                    hint: 'Email Address',
                    icon: Icons.email_outlined,
                    keyboard: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 14),

                  _field(
                    controller: _passwordController,
                    hint: 'Password',
                    icon: Icons.lock_outlined,
                    obscure: _obscurePass,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePass ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: _iconColor,
                        size: 20,
                      ),
                      onPressed: () => setState(() => _obscurePass = !_obscurePass),
                    ),
                  ),
                  const SizedBox(height: 14),

                  _field(
                    controller: _confirmController,
                    hint: 'Confirm Password',
                    icon: Icons.lock_outlined,
                    obscure: _obscureConfirm,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: _iconColor,
                        size: 20,
                      ),
                      onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── Register button ───────────────────────────────────────
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
                            color: _iconColor.withOpacity(0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Text(
                                'Create Account',
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
                  const SizedBox(height: 20),

                  // ── Login link ────────────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Already have an account? ',
                        style: TextStyle(fontSize: 14, color: _subColor),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pushReplacementNamed(context, '/login'),
                        child: const Text(
                          'Sign In',
                          style: TextStyle(
                            fontSize: 14,
                            color: _iconColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Role tab button inside the selector row
  Widget _roleTab(String role, IconData icon, String label) {
    final selected = _selectedRole == role;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedRole = role),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? _iconColor : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: selected ? Colors.white : _iconColor),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : _iconColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Reusable text field
  Widget _field({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffixIcon,
    TextInputType keyboard = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboard,
      style: const TextStyle(color: Colors.black87, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF90CAF9)),
        prefixIcon: Icon(icon, color: _iconColor, size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white.withOpacity(0.85),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _cardBorder, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _iconColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
