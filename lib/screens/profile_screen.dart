import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  File? _profileImage;
  String? _avatarUrl;
  bool _isLoading = false;
  bool _isFetching = true;
  String? _fetchError;

  // ── Theme ────────────────────────────────────────────────────────
  bool _darkTheme = false;

  // ── Dark-mode aware colors ───────────────────────────────────────
  Color get _bgStart        => _darkTheme ? const Color(0xFF1A1A2E) : const Color(0xFFB3E5FC);
  Color get _bgMid          => _darkTheme ? const Color(0xFF16213E) : const Color(0xFFE1F5FE);
  Color get _bgEnd          => _darkTheme ? const Color(0xFF0F3460) : const Color(0xFFFFFFFF);
  Color get _titleColor     => _darkTheme ? const Color(0xFF90CAF9) : const Color(0xFF01579B);
  Color get _subtitleColor  => _darkTheme ? const Color(0xFF64B5F6) : const Color(0xFF0277BD);
  Color get _iconColor      => _darkTheme ? const Color(0xFF64B5F6) : const Color(0xFF0288D1);
  Color get _cardBorder     => _darkTheme ? const Color(0xFF2A4A6B) : const Color(0xFF81D4FA);
  Color get _hintColor      => _darkTheme ? const Color(0xFF4A6A8A) : const Color(0xFF90CAF9);
  Color get _inputFill      => _darkTheme ? const Color(0xFF162032) : Colors.white.withOpacity(0.85);
  Color get _inputTextColor => _darkTheme ? const Color(0xFFE0E0E0) : Colors.black87;
  Color get _avatarBg       => _darkTheme ? const Color(0xFF1E2A3A) : const Color(0xFFB3E5FC);
  Color get _buttonGradStart=> _darkTheme ? const Color(0xFF1565C0) : const Color(0xFF29B6F6);
  Color get _buttonGradEnd  => _darkTheme ? const Color(0xFF0D47A1) : const Color(0xFF0288D1);

  List<Color> get _gradientColors => [_bgStart, _bgMid, _bgEnd];

  @override
  void initState() {
    super.initState();
    _loadTheme();
    _fetchProfile();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _darkTheme = prefs.getBool('darkTheme') ?? false);
  }

  Future<void> _fetchProfile() async {
    setState(() {
      _isFetching = true;
      _fetchError = null;
    });
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
        setState(() {
          _fullNameController.text = data['name'] ?? '';
          _emailController.text = data['email'] ?? '';
          _phoneController.text = data['phone'] ?? '';
          _avatarUrl = data['avatar_url'];
          _isFetching = false;
        });
      } else {
        setState(() {
          _fetchError = 'Failed to load profile.';
          _isFetching = false;
        });
      }
    } catch (e) {
      setState(() {
        _fetchError = 'Network error: $e';
        _isFetching = false;
      });
    }
  }

  Future<void> _changePhoto() async {
    final ImagePicker picker = ImagePicker();
    final XFile? photo = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (photo != null) {
      setState(() => _profileImage = File(photo.path));
    }
  }

  // ── FIX: avatar is now always included when a new image is picked ──
  Future<void> _saveChanges() async {
    if (_fullNameController.text.isEmpty || _emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please fill in all required fields!'),
          backgroundColor: _iconColor,
        ),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final token = await ApiService.getToken();

      // Always use multipart so the avatar field is reliably sent
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiService.baseUrl}/user/update'),
      );
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';
      // Laravel needs this to treat the POST as a PUT
      request.fields['_method'] = 'PUT';
      request.fields['name'] = _fullNameController.text.trim();
      request.fields['email'] = _emailController.text.trim();
      request.fields['phone'] = _phoneController.text.trim();

      // Attach avatar only when the user actually picked a new one
      if (_profileImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'avatar',
            _profileImage!.path,
            // Provide explicit filename so Laravel sees it correctly
            filename: _profileImage!.path.split('/').last,
          ),
        );
      }

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      final body = jsonDecode(response.body);

      setState(() => _isLoading = false);

      if (response.statusCode == 200) {
        // Refresh the avatar URL from the server response if present
        if (body['avatar_url'] != null) {
          setState(() => _avatarUrl = body['avatar_url']);
        }
        _showSuccess();
      } else {
        _showError(response.body);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Network error: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showSuccess() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Profile updated successfully!'),
        backgroundColor: _iconColor,
      ),
    );
    Navigator.pop(context);
  }

  void _showError(String body) {
    if (!mounted) return;
    String message = 'Failed to update profile.';
    try {
      final decoded = jsonDecode(body);
      if (decoded['message'] != null) message = decoded['message'];
      if (decoded['errors'] != null) {
        final errors = decoded['errors'] as Map<String, dynamic>;
        message = errors.values.first[0];
      }
    } catch (_) {}
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      filled: true,
      fillColor: _inputFill,
      hintText: hint,
      hintStyle: TextStyle(color: _hintColor),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: _cardBorder, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: _iconColor, width: 2),
      ),
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
            colors: _gradientColors,
            stops: const [0.0, 0.45, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── AppBar ───────────────────────────────────────────
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
                      'Edit Profile',
                      style: TextStyle(
                        color: _titleColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Body ─────────────────────────────────────────────
              Expanded(
                child: _isFetching
                    ? Center(
                    child: CircularProgressIndicator(color: _iconColor))
                    : _fetchError != null
                    ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.wifi_off,
                          color: _cardBorder, size: 48),
                      const SizedBox(height: 12),
                      Text(_fetchError!,
                          style: TextStyle(color: _subtitleColor),
                          textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _fetchProfile,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _iconColor,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                )
                    : SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Profile photo ────────────────────────
                      Center(
                        child: Column(
                          children: [
                            Stack(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: _iconColor
                                            .withOpacity(0.3),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: CircleAvatar(
                                    radius: 50,
                                    backgroundColor: _avatarBg,
                                    backgroundImage:
                                    _profileImage != null
                                        ? FileImage(_profileImage!)
                                    as ImageProvider
                                        : (_avatarUrl != null &&
                                        _avatarUrl!
                                            .isNotEmpty)
                                        ? NetworkImage(
                                        _avatarUrl!)
                                        : null,
                                    child: (_profileImage == null &&
                                        (_avatarUrl == null ||
                                            _avatarUrl!.isEmpty))
                                        ? Icon(Icons.person,
                                        size: 55,
                                        color: _iconColor)
                                        : null,
                                  ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: GestureDetector(
                                    onTap: _changePhoto,
                                    child: Container(
                                      padding:
                                      const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: _iconColor,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                          Icons.camera_alt,
                                          color: Colors.white,
                                          size: 16),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: _changePhoto,
                              child: Text(
                                'Change Photo',
                                style: TextStyle(
                                  color: _iconColor,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // ── Fields ───────────────────────────────
                      Text('Full Name',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _subtitleColor)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _fullNameController,
                        style: TextStyle(color: _inputTextColor),
                        decoration: _inputDecoration('Full Name'),
                      ),
                      const SizedBox(height: 20),

                      Text('Email Address',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _subtitleColor)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: TextStyle(color: _inputTextColor),
                        decoration:
                        _inputDecoration('user@email.com'),
                      ),
                      const SizedBox(height: 20),

                      Text('Phone Number',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _subtitleColor)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        style: TextStyle(color: _inputTextColor),
                        decoration:
                        _inputDecoration('Enter phone number'),
                      ),
                      const SizedBox(height: 32),

                      // ── Save button ──────────────────────────
                      SizedBox(
                        width: double.infinity,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                _buttonGradStart,
                                _buttonGradEnd
                              ],
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
                            onPressed:
                            _isLoading ? null : _saveChanges,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 16),
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                  BorderRadius.circular(10)),
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(
                                color: Colors.white)
                                : const Text(
                              'Save Changes',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}