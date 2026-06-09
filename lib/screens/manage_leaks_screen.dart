import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  @override
  void initState() {
    super.initState();
    _loadTheme();
    _fetchUserProfile();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index == 1) _fetchMyReports();
    });
    _getLocation();
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
        setState(() => _avatarUrl = data['avatar_url']);
      }
    } catch (_) {}
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

  Widget _buildAvatar() {
    return CircleAvatar(
      backgroundColor: _iconColor,
      backgroundImage: (_avatarUrl != null && _avatarUrl!.isNotEmpty)
          ? NetworkImage(_avatarUrl!) : null,
      child: (_avatarUrl == null || _avatarUrl!.isEmpty)
          ? const Icon(Icons.person, color: Colors.white) : null,
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

  // ── Submit Report ────────────────────────────────────────────────
  void _submitReport() async {
    if (_fullNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter your full name!')));
      return;
    }
    if (widget.image == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please take a photo first!')));
      return;
    }
    if (_position == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location not ready. Tap ↻ and wait.')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final token = await ApiService.getToken();

      // ── Step 1: ML check via Laravel proxy ───────────────────────
      // CHANGED: was http://3.27.75.51:5000/predict (plain HTTP, blocked by manifest)
      // NOW:     https://geoflow.duckdns.org/api/predict (proxied through Laravel)
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
        setState(() => _isLoading = false);
        _showNotLeakDialog('${mlData['confidence']}');
        return;
      }

      // ── Step 2: Submit report ────────────────────────────────────
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
        setState(() => _isLoading = false);
        _showNotLeakDialog('${body['confidence'] ?? '?'}');
        return;
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report submitted successfully!')));
        Navigator.pushReplacementNamed(context, '/main');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $responseBody')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Verified': return Colors.green;
      case 'Under Review': return Colors.orange;
      default: return Colors.grey;
    }
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
                      onTap: () async { await Navigator.pushNamed(context, '/profile'); _fetchUserProfile(); },
                      child: _buildAvatar(),
                    ),
                    Expanded(child: Center(child: Text('GeoFlow', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _titleColor)))),
                    IconButton(
                      icon: Icon(Icons.settings_outlined, color: _iconColor),
                      onPressed: () async { await Navigator.pushNamed(context, '/settings'); _loadTheme(); _fetchUserProfile(); },
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