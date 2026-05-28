import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  // ── Theme ────────────────────────────────────────────────────────
  bool _darkTheme = false;

  // ── Dark-mode aware colors ───────────────────────────────────────
  Color get _bgStart         => _darkTheme ? const Color(0xFF1A1A2E) : const Color(0xFFB8D9F8);
  Color get _bgMid           => _darkTheme ? const Color(0xFF16213E) : const Color(0xFF5AACEE);
  Color get _bgEnd           => _darkTheme ? const Color(0xFF0F3460) : const Color(0xFF1A78C2);
  Color get _cardBg          => _darkTheme ? const Color(0xFF1E2A3A) : Colors.white.withOpacity(0.92);
  Color get _titleColor      => _darkTheme ? const Color(0xFF90CAF9) : const Color(0xFF0D4F8C);
  Color get _inputTextColor  => _darkTheme ? const Color(0xFFE0E0E0) : Colors.black87;
  Color get _labelColor      => _darkTheme ? const Color(0xFF64B5F6) : const Color(0xFF1A78C2);
  Color get _hintColor       => _darkTheme ? const Color(0xFF4A6A8A) : Colors.grey;
  Color get _borderColor     => _darkTheme ? const Color(0xFF2A4A6B) : const Color(0xFF5AACEE);
  Color get _focusedBorder   => _darkTheme ? const Color(0xFF64B5F6) : const Color(0xFF1A78C2);
  Color get _buttonColor     => _darkTheme ? const Color(0xFF1565C0) : const Color(0xFF1A78C2);
  Color get _linkColor       => _darkTheme ? const Color(0xFF64B5F6) : const Color(0xFF1A78C2);
  Color get _plainTextColor  => _darkTheme ? const Color(0xFFB0BEC5) : const Color(0xFF444444);
  Color get _cardShadow      => _darkTheme ? Colors.black.withOpacity(0.4) : Colors.black.withOpacity(0.12);

  List<Color> get _gradientColors => [_bgStart, _bgMid, _bgEnd];

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _darkTheme = prefs.getBool('darkTheme') ?? false);
  }

  InputDecoration _inputDecoration(String label, String hint) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: _labelColor),
      hintText: hint,
      hintStyle: TextStyle(color: _hintColor),
      filled: true,
      fillColor: _darkTheme ? const Color(0xFF162032) : Colors.transparent,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: _borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: _borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: _focusedBorder, width: 2),
      ),
    );
  }

  void _register() async {
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields!')),
      );
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match!')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await ApiService.register(
        _nameController.text,
        _emailController.text,
        _passwordController.text,
      );

      if (response['token'] != null) {
        await ApiService.saveToken(response['token']);
        setState(() => _isLoading = false);
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(response['message'] ?? 'Registration failed!')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Connection error! Is the server running?')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _gradientColors,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding:
              const EdgeInsets.symmetric(horizontal: 28.0, vertical: 24),
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: _cardBg,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: _cardShadow,
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Title
                    Text(
                      "Don't have an account?\nPlease Sign Up to Geoflow",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: _titleColor,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Name field
                    TextField(
                      controller: _nameController,
                      style: TextStyle(color: _inputTextColor),
                      decoration: _inputDecoration('Full Name', 'Enter your name'),
                    ),
                    const SizedBox(height: 14),

                    // Email field
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: TextStyle(color: _inputTextColor),
                      decoration: _inputDecoration('Email', 'Enter your email'),
                    ),
                    const SizedBox(height: 14),

                    // Password field
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      style: TextStyle(color: _inputTextColor),
                      decoration:
                      _inputDecoration('Password', 'Enter your password'),
                    ),
                    const SizedBox(height: 14),

                    // Confirm Password field
                    TextField(
                      controller: _confirmPasswordController,
                      obscureText: true,
                      style: TextStyle(color: _inputTextColor),
                      decoration: _inputDecoration(
                          'Confirm Password', 'Re-enter your password'),
                    ),
                    const SizedBox(height: 24),

                    // Register button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _buttonColor,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 3,
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                            color: Colors.white)
                            : const Text(
                          'Register',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Login link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Already have an account? ",
                          style: TextStyle(color: _plainTextColor),
                        ),
                        GestureDetector(
                          onTap: () =>
                              Navigator.pushNamed(context, '/login'),
                          child: Text(
                            'Sign In',
                            style: TextStyle(
                              color: _linkColor,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                              decorationColor: _linkColor,
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
      ),
    );
  }
}