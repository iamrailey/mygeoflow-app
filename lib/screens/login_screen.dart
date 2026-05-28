import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _darkTheme = false;

  @override
  void initState() {
    super.initState();
    _loadTheme();
    // ✅ Clear any snackbars carried over from the previous session
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).clearSnackBars();
    });
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _darkTheme = prefs.getBool('darkTheme') ?? false);
  }

  // ── Dark-mode aware colors ───────────────────────────────────────────────
  Color get _bgStart       => _darkTheme ? const Color(0xFF1A1A2E) : const Color(0xFFEBF5FF);
  Color get _bgMid         => _darkTheme ? const Color(0xFF16213E) : const Color(0xFFDCEEFB);
  Color get _bgEnd         => _darkTheme ? const Color(0xFF0F3460) : const Color(0xFFC9E4FA);
  Color get _titleColor    => _darkTheme ? const Color(0xFF90CAF9) : Colors.black87;
  Color get _subtitleColor => _darkTheme ? const Color(0xFF64B5F6) : Colors.black54;
  Color get _iconColor     => _darkTheme ? const Color(0xFF64B5F6) : Colors.blue.shade300;
  Color get _cardBg        => _darkTheme ? const Color(0xFF1E2A3A) : Colors.white;
  Color get _cardBorder    => _darkTheme ? const Color(0xFF2A4A6B) : Colors.blue.shade100;
  Color get _focusedBorder => _darkTheme ? const Color(0xFF90CAF9) : Colors.blue.shade300;
  Color get _labelColor    => _darkTheme ? const Color(0xFF64B5F6) : Colors.blue.shade300;
  Color get _hintColor     => _darkTheme ? const Color(0xFF4A6A8A) : Colors.grey.shade400;
  Color get _inputTextColor=> _darkTheme ? const Color(0xFFE0E0E0) : Colors.black87;

  List<Color> get _gradientColors => [_bgStart, _bgMid, _bgEnd];

  void _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields!')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await ApiService.login(
        _emailController.text,
        _passwordController.text,
      );

      if (response['token'] != null) {
        await ApiService.saveToken(response['token']);
        setState(() => _isLoading = false);
        Navigator.pushReplacementNamed(context, '/main');
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? 'Login failed!')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
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
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: _gradientColors,
            stops: const [0.0, 0.40, 1.0],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Please Log in to\nGeoFlow',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: _titleColor,
                  ),
                ),
                const SizedBox(height: 32),

                // ── Email field ──────────────────────────────────────────
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(color: _inputTextColor),
                  decoration: InputDecoration(
                    labelText: 'Email',
                    hintText: 'Enter your email',
                    hintStyle: TextStyle(color: _hintColor),
                    filled: true,
                    fillColor: _cardBg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: _cardBorder, width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: _focusedBorder, width: 2),
                    ),
                    labelStyle: TextStyle(color: _labelColor),
                  ),
                ),
                const SizedBox(height: 16),

                // ── Password field ───────────────────────────────────────
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  style: TextStyle(color: _inputTextColor),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: 'Enter your password',
                    hintStyle: TextStyle(color: _hintColor),
                    filled: true,
                    fillColor: _cardBg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: _cardBorder, width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: _focusedBorder, width: 2),
                    ),
                    labelStyle: TextStyle(color: _labelColor),
                  ),
                ),
                const SizedBox(height: 24),

                // ── Sign In button ───────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _darkTheme
                            ? [const Color(0xFF1565C0), const Color(0xFF0D47A1)]
                            : [const Color(0xFF29B6F6), const Color(0xFF0288D1)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0288D1).withOpacity(0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                        'Sign In',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // ── Forgot password ──────────────────────────────────────
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/forgot-password'),
                  child: const Text(
                    'Forgot password?',
                    style: TextStyle(color: _subtitleColor),
                  ),
                ),

                // ── Sign Up row ──────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: TextStyle(color: _subtitleColor),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pushNamed(context, '/register'),
                      child: Text(
                        'Sign Up',
                        style: TextStyle(
                          color: _iconColor,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                          decorationColor: _iconColor,
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
    );
  }
}