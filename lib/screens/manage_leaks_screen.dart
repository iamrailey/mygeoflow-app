import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';

class ManageLeaksScreen extends StatefulWidget {
  final File? image;

  const ManageLeaksScreen({super.key, this.image});

  @override
  State<ManageLeaksScreen> createState() => _ManageLeaksScreenState();
}

class _ManageLeaksScreenState extends State<ManageLeaksScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _fullNameController = TextEditingController();
  bool _isLoading = false;
  bool _locationLoading = false;
  Position? _position;
  String _locationText = 'Fetching location...';

  List<dynamic> _myReports = [];
  bool _reportsLoading = false;

  bool _darkTheme = false;
  String? _avatarUrl;
  bool _isUploadingAvatar = false;

  @override
  void initState() {
    super.initState();
    _loadTheme();
    _fetchUserProfile();
    _checkRoleAccess();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index == 1) _fetchMyReports();
    });
    _getLocation();
  }

  Future<void> _checkRoleAccess() async {
    final role = await ApiService.getRole();
    if (role == 'inspector' && mounted) {
      Navigator.pushReplacementNamed(context, '/main');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fullNameController.dispose();
    super.dispose();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _darkTheme = prefs.getBool('darkTheme') ?? false);
  }

  Future<void> _fetchUserProfile() async {
    try {
      final token = await ApiService.getToken();
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/user'),
        headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String? avatar = data['avatar_url'];
        if (avatar != null && avatar.isNotEmpty && !avatar.startsWith('http')) {
          avatar = 'https://geoflow.duckdns.org/storage/$avatar';
        }
        setState(() => _avatarUrl = avatar);
      }
    } catch (_) {}
  }

  // ── Avatar Upload ──────────────────────────────────────────────────────
  Future<void> _pickAndUploadAvatar() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 500,
      maxHeight: 500,
      imageQuality: 80,
    );

    if (image == null) return;

    setState(() => _isUploadingAvatar = true);

    try {
      final token = await ApiService.getToken();
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiService.baseUrl}/user/avatar'),
      );
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';
      request.files.add(
        await http.MultipartFile.fromPath('avatar', image.path),
      );

      final response = await request.send();
      final body = await response.stream.bytesToString();
      final data = jsonDecode(body);

      if (response.statusCode == 200) {
        String? avatarPath = data['avatar_url'];
        if (avatarPath != null && avatarPath.isNotEmpty) {
          final fullUrl = 'https://geoflow.duckdns.org/storage/$avatarPath';
          setState(() {
            _avatarUrl = fullUrl;
          });
          PaintingBinding.instance.imageCache.clear();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Avatar updated successfully!')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: ${data['message'] ?? 'Unknown error'}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isUploadingAvatar = false);
      }
    }
  }

  Color get _bgStart        => _darkTheme ? const Color(0xFF1A1A2E) : const Color(0xFFB3E5FC);
  Color get _bgMid          => _darkTheme ? const Color(0xFF16213E) : const Color(0xFFE1F5FE);
  Color get _bgEnd          => _darkTheme ? const Color(0xFF0F3460) : const Color(0xFFFFFFFF);
  Color get _titleColor     => _darkTheme ? const Color(0xFF90CAF9) : const Color(0xFF01579B);
  Color get _subtitleColor  => _darkTheme ? const Color(0xFF64B5F6) : const Color(0xFF0277BD);
  Color get _cardBg         => _darkTheme ? const Color(0xFF1E2A3A) : Colors.white;
  Color get _cardBgOpaque   => _darkTheme ? const Color(0xFF1E2A3A) : Colors.white.withOpacity(0.85);
  Color get _cardBorder     => _darkTheme ? const Color(0xFF2A4A6B) : const Color(0xFF81D4FA);
  Color get _iconColor      => _darkTheme ? const Color(0xFF64B5F6) : const Color(0xFF0288D1);
  Color get _tabBarBg       => _darkTheme ? const Color(0xFF1E2A3A).withOpacity(0.6) : Colors.white.withOpacity(0.6);
  Color get _hintColor      => _darkTheme ? const Color(0xFF4A6A8A) : const Color(0xFF90CAF9);
  Color get _inputTextColor => _darkTheme ? const Color(0xFFE0E0E0) : Colors.black87;
  Color get _imagePlaceholderBg => _darkTheme ? const Color(0xFF162032) : const Color(0xFFE1F5FE);

  List<Color> get _gradientColors => [_bgStart, _bgMid, _bgEnd];

  Widget _buildAvatar({bool showCameraBadge = false}) {
    final hasAvatar = _avatarUrl != null && _avatarUrl!.isNotEmpty;
    final double radius = 20;

    Widget avatar = hasAvatar
        ? ClipOval(
      child: Image.network(
        _avatarUrl!,
        width: radius * 2,
        height: radius * 2,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _avatarUrl = null);
          });
          return CircleAvatar(
            radius: radius,
            backgroundColor: _iconColor,
            child: const Icon(Icons.person, color: Colors.white),
          );
        },
      ),
    )
        : CircleAvatar(
      radius: radius,
      backgroundColor: _iconColor,
      child: const Icon(Icons.person, color: Colors.white),
    );

    return GestureDetector(
      onTap: showCameraBadge ? (_isUploadingAvatar ? null : _pickAndUploadAvatar) : null,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          avatar,
          if (_isUploadingAvatar && showCameraBadge)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  ),
                ),
              ),
            ),
          if (showCameraBadge && !_isUploadingAvatar)
            Positioned(
              bottom: -2, right: -2,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(color: Color(0xFF0288D1), shape: BoxShape.circle),
                child: const Icon(Icons.camera_alt, color: Colors.white, size: 14),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _fetchMyReports() async {
    setState(() => _reportsLoading = true);
    try {
      final token = await ApiService.getToken();
      final res = await http.get(
        Uri.parse('${ApiService.baseUrl}/my-reports'),
        headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
      );
      if (res.statusCode == 200) {
        setState(() { _myReports = jsonDecode(res.body); _reportsLoading = false; });
      } else {
        setState(() => _reportsLoading = false);
      }
    } catch (e) {
      setState(() => _reportsLoading = false);
    }
  }

  Future<void> _deleteMyReport(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: _gradientColors, stops: const [0.0, 0.45, 1.0]),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _cardBorder, width: 1.5),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(radius: 24, backgroundColor: Colors.red.shade400, child: const Icon(Icons.delete, color: Colors.white, size: 22)),
              const SizedBox(height: 16),
              Text('Delete Report', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _titleColor)),
              const SizedBox(height: 8),
              Text('Are you sure you want to delete this report?', style: TextStyle(fontSize: 13, color: _subtitleColor), textAlign: TextAlign.center),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12), side: BorderSide(color: _iconColor, width: 1.5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    child: Text('Cancel', style: TextStyle(color: _iconColor, fontWeight: FontWeight.w600)),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade400, padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    child: const Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed != true) return;

    try {
      final token = await ApiService.getToken();
      final res = await http.delete(
        Uri.parse('${ApiService.baseUrl}/my-reports/$id'),
        headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
      );
      final body = jsonDecode(res.body);
      if (res.statusCode == 200) {
        setState(() => _myReports.removeWhere((r) => r['id'] == id));
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report deleted successfully!')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(body['message'] ?? 'Cannot delete report')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _getLocation() async {
    setState(() { _locationLoading = true; _locationText = 'Fetching location...'; _position = null; });
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) { setState(() { _locationText = 'Location services disabled. Please enable GPS.'; _locationLoading = false; }); return; }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) { setState(() { _locationText = 'Location permission denied.'; _locationLoading = false; }); return; }
      }
      if (permission == LocationPermission.deniedForever) { setState(() { _locationText = 'Permission permanently denied. Enable in app settings.'; _locationLoading = false; }); return; }
      Position? position;
      try { position = await Geolocator.getLastKnownPosition(); } catch (_) {}
      if (position == null) { try { position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.medium, timeLimit: const Duration(seconds: 20)); } catch (_) {} }
      if (position == null) { try { position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.lowest, timeLimit: const Duration(seconds: 30)); } catch (_) {} }
      if (position == null) { setState(() { _locationText = 'Could not get location. Tap ↻ to retry.'; _locationLoading = false; }); return; }
      String address = '';
      for (int attempt = 0; attempt < 3; attempt++) {
        try {
          List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
          if (placemarks.isNotEmpty) {
            Placemark place = placemarks[0];
            final List<String> parts = [];
            if (place.street != null && place.street!.isNotEmpty) parts.add(place.street!);
            if (place.subLocality != null && place.subLocality!.isNotEmpty) parts.add(place.subLocality!);
            if (place.locality != null && place.locality!.isNotEmpty) parts.add(place.locality!);
            if (place.subAdministrativeArea != null && place.subAdministrativeArea!.isNotEmpty && place.subAdministrativeArea != place.locality) parts.add(place.subAdministrativeArea!);
            if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) parts.add(place.administrativeArea!);
            if (parts.isNotEmpty) { address = parts.join(', '); break; }
          }
        } catch (_) { await Future.delayed(const Duration(seconds: 1)); }
      }
      if (address.isEmpty) address = '${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}';
      setState(() { _position = position; _locationText = address; _locationLoading = false; });
    } catch (e) {
      setState(() { _locationText = 'Could not get location. Tap ↻ to retry.'; _locationLoading = false; });
    }
  }

  void _showNotLeakDialog(String confidence) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: _gradientColors, stops: const [0.0, 0.45, 1.0]),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _cardBorder, width: 1.5),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircleAvatar(radius: 24, backgroundColor: Colors.orange, child: Icon(Icons.warning_amber_rounded, color: Colors.white, size: 22)),
              const SizedBox(height: 16),
              Text('Not a Leak', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _titleColor)),
              const SizedBox(height: 8),
              Text('The image does not appear to be a water leak.\nConfidence: $confidence%\n\nPlease take a clearer photo of the leak.', style: TextStyle(fontSize: 13, color: _subtitleColor), textAlign: TextAlign.center),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(backgroundColor: _iconColor, padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                child: const Text('OK', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // FEEDBACK METHODS
  // ──────────────────────────────────────────────────────────────────────────

  Future<void> _submitFeedbackWithNotes(
      String imagePath,
      String predicted,
      String actual,
      double confidence,
      String notes,
      ) async {
    try {
      print('📤 ===== SUBMITTING FEEDBACK =====');
      print('📤 Image Path: $imagePath');
      print('📤 Predicted: $predicted');
      print('📤 Actual: $actual');
      print('📤 Confidence: $confidence');
      print('📤 Notes: $notes');

      final token = await ApiService.getToken();
      print('📤 Token: ${token != null ? "✅ Exists" : "❌ NULL"}');

      final url = '${ApiService.baseUrl}/feedback';
      print('📤 URL: $url');

      final body = jsonEncode({
        'image_path': imagePath,
        'predicted': predicted,
        'actual': actual,
        'confidence': confidence,
        'notes': notes.isNotEmpty
            ? 'User feedback: $notes'
            : 'User corrected from Flutter app',
      });
      print('📤 Body: $body');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: body,
      );

      print('📤 Response Status: ${response.statusCode}');
      print('📤 Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        print('✅ Feedback submitted successfully!');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Feedback submitted! Total: ${data['total_feedback']} feedbacks'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        print('❌ Feedback failed with status: ${response.statusCode}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('❌ Failed to submit feedback: ${response.body}')),
          );
        }
      }
    } catch (e) {
      print('❌ Error submitting feedback: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error submitting feedback: $e')),
        );
      }
    }
  }

  Widget _buildFeedbackDialog(
      String imagePath,
      String predicted,
      double confidence,
      Completer<void> completer,
      ) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: _gradientColors,
            stops: const [0.0, 0.45, 1.0],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _cardBorder, width: 1.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, size: 48, color: Colors.green.shade400),
            const SizedBox(height: 12),
            Text(
              'Prediction: $predicted',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _titleColor,
              ),
            ),
            Text(
              'Confidence: ${confidence.toStringAsFixed(1)}%',
              style: TextStyle(fontSize: 14, color: _subtitleColor),
            ),
            const SizedBox(height: 16),
            Divider(color: _cardBorder),
            const SizedBox(height: 12),
            Text(
              'Was this prediction correct?',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _titleColor),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _submitFeedbackWithNotes(
                        imagePath,
                        predicted,
                        predicted,
                        confidence,
                        '', // Empty notes for correct predictions
                      );
                      Navigator.pop(context);
                      if (!completer.isCompleted) completer.complete();
                    },
                    icon: const Icon(Icons.thumb_up, size: 16),
                    label: const Text('Yes'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _showCorrectTypeDialogSimple(imagePath, predicted, confidence, completer);
                    },
                    icon: const Icon(Icons.thumb_down, size: 16),
                    label: const Text('No'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                if (!completer.isCompleted) completer.complete();
              },
              child: Text('Skip', style: TextStyle(color: _subtitleColor)),
            ),
          ],
        ),
      ),
    );
  }

  void _showCorrectTypeDialogSimple(
      String imagePath,
      String predicted,
      double confidence,
      Completer<void> parentCompleter,
      ) {
    final List<String> classes = ["Large", "Medium", "Small", "Normal"];
    String selectedType = predicted;
    final TextEditingController notesController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: _gradientColors,
              stops: const [0.0, 0.45, 1.0],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _cardBorder, width: 1.5),
          ),
          child: StatefulBuilder(
            builder: (context, setStateDialog) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.edit, size: 40, color: _iconColor),
                const SizedBox(height: 12),
                Text(
                  'What is the correct type?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _titleColor,
                  ),
                ),
                const SizedBox(height: 16),
                ...classes.map((cls) => RadioListTile<String>(
                  title: Text(cls, style: TextStyle(color: _titleColor)),
                  value: cls,
                  groupValue: selectedType,
                  activeColor: _iconColor,
                  onChanged: (value) {
                    setStateDialog(() {
                      selectedType = value!;
                    });
                  },
                )),
                const SizedBox(height: 12),
                TextField(
                  controller: notesController,
                  maxLines: 3,
                  style: TextStyle(color: _inputTextColor, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Add optional notes... (e.g., pipe material, location details)',
                    hintStyle: TextStyle(color: _hintColor, fontSize: 12),
                    filled: true,
                    fillColor: _cardBgOpaque,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: _cardBorder, width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: _iconColor, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        if (!parentCompleter.isCompleted) parentCompleter.complete();
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        side: BorderSide(color: _iconColor, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text('Cancel', style: TextStyle(color: _iconColor)),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        _submitFeedbackWithNotes(
                          imagePath,
                          predicted,
                          selectedType,
                          confidence,
                          notesController.text.trim(),
                        );
                        Navigator.pop(context);
                        if (!parentCompleter.isCompleted) parentCompleter.complete();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('✅ Thank you for correcting the prediction!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _iconColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Submit'),
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

  void _showCorrectTypeDialog(Map report) {
    final List<String> classes = ["Large", "Medium", "Small", "Normal"];
    String selectedType = report['type'] ?? 'Small';
    final TextEditingController notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: _gradientColors,
              stops: const [0.0, 0.45, 1.0],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _cardBorder, width: 1.5),
          ),
          child: StatefulBuilder(
            builder: (context, setStateDialog) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.feedback_outlined, size: 40, color: _iconColor),
                const SizedBox(height: 12),
                Text(
                  'What should this be?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _titleColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Predicted: ${report['type']} (${report['confidence']}%)',
                  style: TextStyle(fontSize: 14, color: _subtitleColor),
                ),
                const SizedBox(height: 16),
                ...classes.map((cls) => RadioListTile<String>(
                  title: Text(cls, style: TextStyle(color: _titleColor)),
                  value: cls,
                  groupValue: selectedType,
                  activeColor: _iconColor,
                  onChanged: (value) {
                    setStateDialog(() {
                      selectedType = value!;
                    });
                  },
                )),
                const SizedBox(height: 12),
                TextField(
                  controller: notesController,
                  maxLines: 3,
                  style: TextStyle(color: _inputTextColor, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Add optional notes... (e.g., pipe material, location details)',
                    hintStyle: TextStyle(color: _hintColor, fontSize: 12),
                    filled: true,
                    fillColor: _cardBgOpaque,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: _cardBorder, width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: _iconColor, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        side: BorderSide(color: _iconColor, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text('Cancel', style: TextStyle(color: _iconColor)),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        _submitFeedbackWithNotes(
                          report['image'] ?? '',
                          report['type'] ?? '',
                          selectedType,
                          (report['confidence'] ?? 0).toDouble(),
                          notesController.text.trim(),
                        );
                        Navigator.pop(context);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('✅ Feedback submitted!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _iconColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Submit Feedback'),
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

  // ──────────────────────────────────────────────────────────────────────────
  // SUBMIT REPORT — FIXED
  // ──────────────────────────────────────────────────────────────────────────
  void _submitReport() async {
    if (_fullNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter your full name!')));
      return;
    }
    if (widget.image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please take a photo first!')));
      return;
    }
    if (_position == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location not ready. Tap ↻ and wait.')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final token = await ApiService.getToken();

      // ── ML Prediction ──
      var mlRequest = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiService.baseUrl}/predict'),
      );
      mlRequest.headers['Authorization'] = 'Bearer $token';
      mlRequest.headers['Accept'] = 'application/json';
      mlRequest.files.add(
        await http.MultipartFile.fromPath('image', widget.image!.path),
      );

      final mlResponse = await mlRequest.send();
      final mlBody = await mlResponse.stream.bytesToString();
      final mlData = jsonDecode(mlBody);

      if (mlData['type'] == 'Not a Leak') {
        if (mounted) setState(() => _isLoading = false);
        _showNotLeakDialog('${mlData['confidence']}');
        return;
      }

      // ── Submit Report ──
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiService.baseUrl}/reports'),
      );
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';
      request.fields['full_name'] = _fullNameController.text;
      request.fields['location'] = _locationText;
      request.fields['lat'] = _position!.latitude.toString();
      request.fields['lng'] = _position!.longitude.toString();
      request.files.add(
        await http.MultipartFile.fromPath('image', widget.image!.path),
      );

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 422) {
        final body = jsonDecode(responseBody);
        if (mounted) setState(() => _isLoading = false);
        _showNotLeakDialog('${body['confidence'] ?? '?'}');
        return;
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        // ── CRITICAL: Reset loading state FIRST ──
        if (mounted) setState(() => _isLoading = false);

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Report submitted successfully!')));
        }

        // ── Show feedback dialog and WAIT for user action ──
        final completer = Completer<void>();

        if (mounted) {
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => _buildFeedbackDialog(
              widget.image!.path,
              mlData['type'] as String,
              (mlData['confidence'] as num).toDouble(),
              completer,
            ),
          );

          // Wait for completer to complete (user clicked Yes/No/Skip)
          await completer.future;
        }

        // ── FIX: Navigate to MainScreen WITH bottom nav ──
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(context, '/main', (route) => false);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed: $responseBody')));
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Verified': return Colors.green;
      case 'Under Review': return Colors.orange;
      default: return Colors.grey;
    }
  }

  void _showReportDetailSheet(Map report) {
    final status = report['status'] ?? 'Pending';
    final isPending = status == 'Pending';
    bool isEditing = false;
    bool saving = false;

    final nameController = TextEditingController(text: report['full_name'] ?? '');
    final locationController = TextEditingController(text: report['location'] ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: _gradientColors,
                stops: const [0.0, 0.45, 1.0],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border.all(color: _cardBorder, width: 1.5),
            ),
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(
                        color: _cardBorder,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Text('Report Details', style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold, color: _titleColor,
                        )),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _statusColor(status).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: _statusColor(status)),
                        ),
                        child: Text(status, style: TextStyle(
                          fontSize: 12, color: _statusColor(status), fontWeight: FontWeight.w600,
                        )),
                      ),
                    ],
                  ),
                  Text(report['report_id'] ?? '', style: TextStyle(fontSize: 13, color: _subtitleColor)),
                  const SizedBox(height: 16),

                  if (report['image'] != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        'https://geoflow.duckdns.org/storage/${report['image']}',
                        width: double.infinity, height: 180, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: double.infinity, height: 180,
                          color: _cardBg,
                          child: Icon(Icons.broken_image, color: _cardBorder),
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),

                  Text('Type', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _subtitleColor)),
                  Text(report['type'] ?? 'N/A', style: TextStyle(fontSize: 14, color: _titleColor)),
                  const SizedBox(height: 12),

                  Text('Confidence', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _subtitleColor)),
                  Text('${report['confidence'] ?? 'N/A'}%', style: TextStyle(fontSize: 14, color: _titleColor)),
                  const SizedBox(height: 12),

                  Text('Full Name', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _subtitleColor)),
                  const SizedBox(height: 4),
                  isEditing
                      ? TextField(
                    controller: nameController,
                    style: TextStyle(color: _inputTextColor, fontSize: 14),
                    decoration: InputDecoration(
                      filled: true, fillColor: _cardBgOpaque,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: _cardBorder, width: 1.5)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: _iconColor, width: 2)),
                    ),
                  )
                      : Text(report['full_name'] ?? 'N/A', style: TextStyle(fontSize: 14, color: _titleColor)),
                  const SizedBox(height: 12),

                  Text('Location', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _subtitleColor)),
                  const SizedBox(height: 4),
                  isEditing
                      ? TextField(
                    controller: locationController,
                    maxLines: 2,
                    style: TextStyle(color: _inputTextColor, fontSize: 14),
                    decoration: InputDecoration(
                      filled: true, fillColor: _cardBgOpaque,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: _cardBorder, width: 1.5)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: _iconColor, width: 2)),
                    ),
                  )
                      : Text(report['location'] ?? 'N/A', style: TextStyle(fontSize: 14, color: _titleColor)),
                  const SizedBox(height: 12),

                  if (report['time'] != null) ...[
                    Text('Date', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _subtitleColor)),
                    Text('${report['time']}'.split('T').first, style: TextStyle(fontSize: 14, color: _titleColor)),
                    const SizedBox(height: 12),
                  ],

                  // ── FEEDBACK SECTION ──
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.feedback_outlined, size: 16, color: Colors.blue.shade700),
                            const SizedBox(width: 8),
                            Text(
                              'Help Improve the Model',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Was this prediction correct? Your feedback helps the AI learn and improve!',
                          style: TextStyle(fontSize: 12, color: Colors.blue.shade600),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  _submitFeedbackWithNotes(
                                    report['image'] ?? '',
                                    report['type'] ?? '',
                                    report['type'] ?? '',
                                    (report['confidence'] ?? 0).toDouble(),
                                    '', // Empty notes for correct
                                  );
                                  Navigator.pop(context);
                                },
                                icon: const Icon(Icons.thumb_up, size: 16),
                                label: const Text('Correct'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.pop(context);
                                  _showCorrectTypeDialog(report);
                                },
                                icon: const Icon(Icons.thumb_down, size: 16),
                                label: const Text('Incorrect'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  if (!isPending) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.lock_outline, size: 16, color: Colors.orange.shade700),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'This report is already $status and can no longer be edited.',
                              style: TextStyle(fontSize: 12, color: Colors.orange.shade700),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],

                  const SizedBox(height: 16),

                  if (isPending)
                    SizedBox(
                      width: double.infinity,
                      child: isEditing
                          ? ElevatedButton(
                        onPressed: saving ? null : () async {
                          if (nameController.text.trim().isEmpty || locationController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Name and location cannot be empty.')),
                            );
                            return;
                          }
                          setSheet(() => saving = true);
                          try {
                            final token = await ApiService.getToken();
                            final res = await http.put(
                              Uri.parse('${ApiService.baseUrl}/my-reports/${report['id']}'),
                              headers: {
                                'Authorization': 'Bearer $token',
                                'Accept': 'application/json',
                                'Content-Type': 'application/json',
                              },
                              body: jsonEncode({
                                'full_name': nameController.text.trim(),
                                'location': locationController.text.trim(),
                              }),
                            );
                            final body = jsonDecode(res.body);
                            if (res.statusCode == 200) {
                              Navigator.pop(ctx);
                              _fetchMyReports();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Report updated successfully!')),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(body['message'] ?? 'Update failed')),
                              );
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          }
                          setSheet(() => saving = false);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _iconColor,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: saving
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('Save Changes', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                      )
                          : OutlinedButton.icon(
                        onPressed: () => setSheet(() => isEditing = true),
                        icon: Icon(Icons.edit_outlined, color: _iconColor, size: 18),
                        label: Text('Edit Report', style: TextStyle(color: _iconColor, fontWeight: FontWeight.w600)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: _iconColor, width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: _gradientColors, stops: const [0.0, 0.45, 1.0]),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () async {
                        await Navigator.pushNamed(context, '/profile');
                        _fetchUserProfile();
                      },
                      child: _buildAvatar(showCameraBadge: false),
                    ),
                    Expanded(child: Center(child: Text('GeoFlow', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _titleColor)))),
                    IconButton(
                      icon: Icon(Icons.settings_outlined, color: _iconColor),
                      onPressed: () async {
                        await Navigator.pushNamed(context, '/settings');
                        _loadTheme();
                        _fetchUserProfile();
                      },
                    ),
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(color: _tabBarBg, borderRadius: BorderRadius.circular(12)),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(color: _iconColor, borderRadius: BorderRadius.circular(10)),
                  labelColor: Colors.white,
                  unselectedLabelColor: _iconColor,
                  tabs: const [Tab(text: 'Submit Report'), Tab(text: 'My Reports')],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: double.infinity, height: 200,
                            decoration: BoxDecoration(color: _imagePlaceholderBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: _cardBorder, width: 1.5), boxShadow: [BoxShadow(color: const Color(0xFF29B6F6).withOpacity(0.18), blurRadius: 10, offset: const Offset(0, 4))]),
                            child: widget.image != null
                                ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(widget.image!, fit: BoxFit.cover))
                                : Center(child: Icon(Icons.image_outlined, size: 60, color: _cardBorder)),
                          ),
                          const SizedBox(height: 24),
                          Text('Full Name', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _subtitleColor)),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _fullNameController,
                            style: TextStyle(color: _inputTextColor),
                            decoration: InputDecoration(
                              hintText: 'Enter your full name', hintStyle: TextStyle(color: _hintColor),
                              filled: true, fillColor: _cardBgOpaque,
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: _cardBorder, width: 1.5)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: _iconColor, width: 2)),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text('Location (GPS)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _subtitleColor)),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(color: _cardBgOpaque, borderRadius: BorderRadius.circular(10), border: Border.all(color: _cardBorder, width: 1.5)),
                            child: Row(
                              children: [
                                _locationLoading
                                    ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: _iconColor))
                                    : Icon(_position != null ? Icons.location_on : Icons.location_off, color: _position != null ? _iconColor : Colors.orange, size: 18),
                                const SizedBox(width: 8),
                                Expanded(child: Text(_locationText, style: TextStyle(fontSize: 13, color: _position != null ? _titleColor : Colors.orange.shade700))),
                                IconButton(icon: Icon(Icons.refresh, size: 18, color: _iconColor), onPressed: _locationLoading ? null : _getLocation),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: (_position != null && !_isLoading) ? _darkTheme ? [const Color(0xFF1565C0), const Color(0xFF0D47A1)] : [const Color(0xFF29B6F6), const Color(0xFF0288D1)] : [Colors.grey.shade600, Colors.grey.shade700],
                                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: ElevatedButton(
                                onPressed: (_isLoading || _position == null) ? null : _submitReport,
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                                child: _isLoading
                                    ? const CircularProgressIndicator(color: Colors.white)
                                    : Text(_position != null ? 'Submit Report' : 'Waiting for GPS...', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _reportsLoading
                        ? Center(child: CircularProgressIndicator(color: _iconColor))
                        : _myReports.isEmpty
                        ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.inbox, size: 60, color: _cardBorder),
                      const SizedBox(height: 12),
                      Text('No reports yet', style: TextStyle(color: _subtitleColor)),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(onPressed: _fetchMyReports, icon: const Icon(Icons.refresh), label: const Text('Refresh'), style: ElevatedButton.styleFrom(backgroundColor: _iconColor, foregroundColor: Colors.white)),
                    ]))
                        : RefreshIndicator(
                      onRefresh: _fetchMyReports, color: _iconColor,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _myReports.length,
                        itemBuilder: (context, index) {
                          final r = _myReports[index];
                          final status = r['status'] ?? 'Pending';
                          final isPending = status == 'Pending';
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(color: _cardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: _cardBorder), boxShadow: [BoxShadow(color: const Color(0xFF0288D1).withOpacity(0.07), blurRadius: 6, offset: const Offset(0, 2))]),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(12),
                              onTap: () => _showReportDetailSheet(r),
                              leading: r['image'] != null
                                  ? ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network('https://geoflow.duckdns.org/storage/${r['image']}', width: 56, height: 56, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Icon(Icons.image, color: _cardBorder)))
                                  : Icon(Icons.image, color: _cardBorder),
                              title: Text(r['report_id'] ?? 'Unknown', style: TextStyle(fontWeight: FontWeight.bold, color: _titleColor, fontSize: 14)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(r['type'] ?? '', style: TextStyle(fontSize: 12, color: _subtitleColor)),
                                  Text(r['location'] ?? '', style: TextStyle(fontSize: 11, color: _darkTheme ? const Color(0xFF4A6A8A) : Colors.grey)),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(color: _statusColor(status).withOpacity(0.1), borderRadius: BorderRadius.circular(999), border: Border.all(color: _statusColor(status))),
                                    child: Text(status, style: TextStyle(fontSize: 11, color: _statusColor(status), fontWeight: FontWeight.w600)),
                                  ),
                                ],
                              ),
                              trailing: isPending ? IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteMyReport(r['id'])) : null,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
