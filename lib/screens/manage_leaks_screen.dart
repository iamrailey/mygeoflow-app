import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
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

  // ── Submit Report state ──────────────────────────────────────────
  final _fullNameController = TextEditingController();
  bool _isLoading = false;
  bool _locationLoading = false;
  Position? _position;
  String _locationText = 'Fetching location...';

  // ── My Reports state ─────────────────────────────────────────────
  List<dynamic> _myReports = [];
  bool _reportsLoading = false;

  @override
  void initState() {
    super.initState();
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

  // ── Fetch My Reports ─────────────────────────────────────────────
  Future<void> _fetchMyReports() async {
    setState(() => _reportsLoading = true);
    try {
      final token = await ApiService.getToken();
      final res = await http.get(
        Uri.parse('${ApiService.baseUrl}/my-reports'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      if (res.statusCode == 200) {
        setState(() {
          _myReports = jsonDecode(res.body);
          _reportsLoading = false;
        });
      } else {
        setState(() => _reportsLoading = false);
      }
    } catch (e) {
      setState(() => _reportsLoading = false);
    }
  }

  // ── Delete My Report ─────────────────────────────────────────────
  Future<void> _deleteMyReport(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Report'),
        content: const Text('Are you sure you want to delete this report?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child:
              const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final token = await ApiService.getToken();
      final res = await http.delete(
        Uri.parse('${ApiService.baseUrl}/my-reports/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      final body = jsonDecode(res.body);
      if (res.statusCode == 200) {
        setState(() => _myReports.removeWhere((r) => r['id'] == id));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report deleted successfully!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(body['message'] ?? 'Cannot delete report')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  // ── Location ─────────────────────────────────────────────────────
  Future<void> _getLocation() async {
    setState(() {
      _locationLoading = true;
      _locationText = 'Fetching location...';
      _position = null;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _locationText = 'Location services disabled. Please enable GPS.';
          _locationLoading = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _locationText = 'Location permission denied.';
            _locationLoading = false;
          });
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _locationText =
          'Permission permanently denied. Enable in app settings.';
          _locationLoading = false;
        });
        return;
      }

      Position? position;
      try {
        position = await Geolocator.getLastKnownPosition();
      } catch (_) {}

      if (position == null) {
        try {
          position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.medium,
            timeLimit: const Duration(seconds: 20),
          );
        } catch (_) {}
      }

      if (position == null) {
        try {
          position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.lowest,
            timeLimit: const Duration(seconds: 30),
          );
        } catch (_) {}
      }

      if (position == null) {
        setState(() {
          _locationText = 'Could not get location. Tap ↻ to retry.';
          _locationLoading = false;
        });
        return;
      }

      String address = '';
      for (int attempt = 0; attempt < 3; attempt++) {
        try {
          List<Placemark> placemarks = await placemarkFromCoordinates(
            position.latitude,
            position.longitude,
          );
          if (placemarks.isNotEmpty) {
            Placemark place = placemarks[0];
            final List<String> parts = [];
            if (place.street != null && place.street!.isNotEmpty)
              parts.add(place.street!);
            if (place.subLocality != null && place.subLocality!.isNotEmpty)
              parts.add(place.subLocality!);
            if (place.locality != null && place.locality!.isNotEmpty)
              parts.add(place.locality!);
            if (place.subAdministrativeArea != null &&
                place.subAdministrativeArea!.isNotEmpty &&
                place.subAdministrativeArea != place.locality)
              parts.add(place.subAdministrativeArea!);
            if (place.administrativeArea != null &&
                place.administrativeArea!.isNotEmpty)
              parts.add(place.administrativeArea!);
            if (parts.isNotEmpty) {
              address = parts.join(', ');
              break;
            }
          }
        } catch (_) {
          await Future.delayed(const Duration(seconds: 1));
        }
      }

      if (address.isEmpty) {
        address =
        '${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}';
      }

      setState(() {
        _position = position;
        _locationText = address;
        _locationLoading = false;
      });
    } catch (e) {
      setState(() {
        _locationText = 'Could not get location. Tap ↻ to retry.';
        _locationLoading = false;
      });
    }
  }

  // ── Not a Leak Dialog ────────────────────────────────────────────
  void _showNotLeakDialog(String confidence) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            SizedBox(width: 8),
            Text('Not a Leak'),
          ],
        ),
        content: Text(
          'The image does not appear to be a water leak.\n'
              'Confidence: $confidence%\n\n'
              'Please take a clearer photo of the leak.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // ── Submit Report ────────────────────────────────────────────────
  void _submitReport() async {
    if (_fullNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your full name!')),
      );
      return;
    }
    if (widget.image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please take a photo first!')),
      );
      return;
    }
    if (_position == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location not ready. Tap ↻ and wait.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Step 1: ML check
      var mlRequest = http.MultipartRequest(
        'POST',
        Uri.parse('http://3.27.75.51:5000/predict'),
      );
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

      // Step 2: Submit to Laravel
      final token = await ApiService.getToken();
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report submitted successfully!')),
        );
        Navigator.pushReplacementNamed(context, '/main');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $responseBody')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ── Status color ─────────────────────────────────────────────────
  Color _statusColor(String status) {
    switch (status) {
      case 'Verified':
        return Colors.green;
      case 'Under Review':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  // ── Build ────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFB3E5FC),
              Color(0xFFE1F5FE),
              Color(0xFFFFFFFF),
            ],
            stops: [0.0, 0.45, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // AppBar
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12.0, vertical: 8.0),
                child: Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: Color(0xFF0288D1),
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                    const Expanded(
                      child: Center(
                        child: Text(
                          'GeoFlow',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF01579B),
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.settings_outlined,
                          color: Color(0xFF0288D1)),
                      onPressed: () =>
                          Navigator.pushNamed(context, '/settings'),
                    ),
                  ],
                ),
              ),

              // Tab Bar
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: const Color(0xFF0288D1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: const Color(0xFF0288D1),
                  tabs: const [
                    Tab(text: 'Submit Report'),
                    Tab(text: 'My Reports'),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Tab Views
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // ── TAB 1: Submit Report ──────────────────────
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Image preview
                          Container(
                            width: double.infinity,
                            height: 200,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE1F5FE),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: const Color(0xFF81D4FA), width: 1.5),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF29B6F6)
                                      .withOpacity(0.18),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: widget.image != null
                                ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(widget.image!,
                                  fit: BoxFit.cover),
                            )
                                : const Center(
                              child: Icon(Icons.image_outlined,
                                  size: 60, color: Color(0xFF81D4FA)),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Full Name
                          const Text('Full Name',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF0277BD))),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _fullNameController,
                            decoration: InputDecoration(
                              hintText: 'Enter your full name',
                              hintStyle:
                              const TextStyle(color: Color(0xFF90CAF9)),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.85),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                    color: Color(0xFF81D4FA), width: 1.5),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                    color: Color(0xFF0288D1), width: 2),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // GPS Location
                          const Text('Location (GPS)',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF0277BD))),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.85),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: const Color(0xFF81D4FA), width: 1.5),
                            ),
                            child: Row(
                              children: [
                                _locationLoading
                                    ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Color(0xFF0288D1)),
                                )
                                    : Icon(
                                  _position != null
                                      ? Icons.location_on
                                      : Icons.location_off,
                                  color: _position != null
                                      ? const Color(0xFF0288D1)
                                      : Colors.orange,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _locationText,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: _position != null
                                          ? const Color(0xFF01579B)
                                          : Colors.orange.shade800,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.refresh,
                                      size: 18, color: Color(0xFF0288D1)),
                                  onPressed:
                                  _locationLoading ? null : _getLocation,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Submit button
                          SizedBox(
                            width: double.infinity,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: (_position != null && !_isLoading)
                                      ? [
                                    const Color(0xFF29B6F6),
                                    const Color(0xFF0288D1)
                                  ]
                                      : [
                                    Colors.grey.shade400,
                                    Colors.grey.shade500
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: ElevatedButton(
                                onPressed: (_isLoading || _position == null)
                                    ? null
                                    : _submitReport,
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
                                    : Text(
                                  _position != null
                                      ? 'Submit Report'
                                      : 'Waiting for GPS...',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── TAB 2: My Reports ─────────────────────────
                    _reportsLoading
                        ? const Center(
                        child: CircularProgressIndicator(
                            color: Color(0xFF0288D1)))
                        : _myReports.isEmpty
                        ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.inbox,
                              size: 60, color: Color(0xFF81D4FA)),
                          const SizedBox(height: 12),
                          const Text('No reports yet',
                              style: TextStyle(
                                  color: Color(0xFF0277BD))),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _fetchMyReports,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Refresh'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                              const Color(0xFF0288D1),
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    )
                        : RefreshIndicator(
                      onRefresh: _fetchMyReports,
                      color: const Color(0xFF0288D1),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _myReports.length,
                        itemBuilder: (context, index) {
                          final r = _myReports[index];
                          final status =
                              r['status'] ?? 'Pending';
                          final isPending =
                              status == 'Pending';

                          return Container(
                            margin: const EdgeInsets.only(
                                bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius:
                              BorderRadius.circular(12),
                              border: Border.all(
                                  color:
                                  const Color(0xFFB3E5FC)),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF0288D1)
                                      .withOpacity(0.07),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ListTile(
                              contentPadding:
                              const EdgeInsets.all(12),
                              leading: r['image'] != null
                                  ? ClipRRect(
                                borderRadius:
                                BorderRadius.circular(
                                    8),
                                child: Image.network(
                                  'https://geoflow.duckdns.org/storage/${r['image']}',
                                  width: 56,
                                  height: 56,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                  const Icon(
                                      Icons.image,
                                      color: Color(
                                          0xFF81D4FA)),
                                ),
                              )
                                  : const Icon(Icons.image,
                                  color: Color(0xFF81D4FA)),
                              title: Text(
                                r['report_id'] ?? 'Unknown',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF01579B),
                                  fontSize: 14,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(r['type'] ?? '',
                                      style: const TextStyle(
                                          fontSize: 12)),
                                  Text(r['location'] ?? '',
                                      style: const TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey)),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding:
                                    const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2),
                                    decoration: BoxDecoration(
                                      color: _statusColor(status)
                                          .withOpacity(0.1),
                                      borderRadius:
                                      BorderRadius.circular(
                                          999),
                                      border: Border.all(
                                          color:
                                          _statusColor(status)),
                                    ),
                                    child: Text(
                                      status,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color:
                                        _statusColor(status),
                                        fontWeight:
                                        FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              trailing: isPending
                                  ? IconButton(
                                icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red),
                                onPressed: () =>
                                    _deleteMyReport(
                                        r['id']),
                              )
                                  : null,
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