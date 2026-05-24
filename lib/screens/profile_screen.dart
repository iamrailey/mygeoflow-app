import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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

  @override
  void initState() {
    super.initState();
    _fetchProfile();
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

  Future<void> _saveChanges() async {
    if (_fullNameController.text.isEmpty || _emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields!'),
          backgroundColor: Color(0xFF0288D1),
        ),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final token = await ApiService.getToken();
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiService.baseUrl}/user/update'),
      );
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';
      request.fields['name'] = _fullNameController.text.trim();
      request.fields['email'] = _emailController.text.trim();
      request.fields['phone'] = _phoneController.text.trim();
      request.fields['_method'] = 'PUT';
      if (_profileImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath('avatar', _profileImage!.path),
        );
      }
      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      setState(() => _isLoading = false);
      if (response.statusCode == 200) {
        _showSuccess();
      } else {
        _showError(response.body);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Network error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showSuccess() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile updated successfully!'),
        backgroundColor: Color(0xFF0288D1),
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
      fillColor: Colors.white.withOpacity(0.85),
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF90CAF9)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF81D4FA), width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF0288D1), width: 2),
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
            colors: [Color(0xFFB3E5FC), Color(0xFFE1F5FE), Color(0xFFFFFFFF)],
            stops: [0.0, 0.45, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Color(0xFF01579B)),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text(
                      'Edit Profile',
                      style: TextStyle(
                        color: Color(0xFF01579B),
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _isFetching
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFF0288D1)))
                    : _fetchError != null
                    ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.wifi_off, color: Color(0xFF81D4FA), size: 48),
                      const SizedBox(height: 12),
                      Text(_fetchError!, style: const TextStyle(color: Color(0xFF0277BD)), textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _fetchProfile,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0288D1),
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
                                        color: const Color(0xFF0288D1).withOpacity(0.3),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: CircleAvatar(
                                    radius: 50,
                                    backgroundColor: const Color(0xFFB3E5FC),
                                    backgroundImage: _profileImage != null
                                        ? FileImage(_profileImage!) as ImageProvider
                                        : (_avatarUrl != null && _avatarUrl!.isNotEmpty)
                                        ? NetworkImage(_avatarUrl!)
                                        : null,
                                    child: (_profileImage == null && (_avatarUrl == null || _avatarUrl!.isEmpty))
                                        ? const Icon(Icons.person, size: 55, color: Color(0xFF0288D1))
                                        : null,
                                  ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: GestureDetector(
                                    onTap: _changePhoto,
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF0288D1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: _changePhoto,
                              child: const Text(
                                'Change Photo',
                                style: TextStyle(
                                  color: Color(0xFF0288D1),
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      const Text('Full Name', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0277BD))),
                      const SizedBox(height: 8),
                      TextField(controller: _fullNameController, decoration: _inputDecoration('Full Name')),
                      const SizedBox(height: 20),

                      const Text('Email Address', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0277BD))),
                      const SizedBox(height: 8),
                      TextField(controller: _emailController, keyboardType: TextInputType.emailAddress, decoration: _inputDecoration('user@email.com')),
                      const SizedBox(height: 20),

                      const Text('Phone Number', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0277BD))),
                      const SizedBox(height: 8),
                      TextField(controller: _phoneController, keyboardType: TextInputType.phone, decoration: _inputDecoration('Enter phone number')),
                      const SizedBox(height: 32),

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
                                color: const Color(0xFF0288D1).withOpacity(0.35),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _saveChanges,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text(
                              'Save Changes',
                              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.5),
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