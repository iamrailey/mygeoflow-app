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

class _ManageLeaksScreenState extends State<ManageLeaksScreen> {
  final _fullNameController = TextEditingController();
  bool _isLoading = false;
  bool _locationLoading = false;
  Position? _position;
  String _locationText = 'Fetching location...';

  @override
  void initState() {
    super.initState();
    _getLocation();
  }

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
          _locationText = 'Permission permanently denied. Enable in app settings.';
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

      // Reverse geocode with 3 retries
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
            if (place.street != null && place.street!.isNotEmpty) {
              parts.add(place.street!);
            }
            if (place.subLocality != null && place.subLocality!.isNotEmpty) {
              parts.add(place.subLocality!);
            }
            if (place.locality != null && place.locality!.isNotEmpty) {
              parts.add(place.locality!);
            }
            if (place.subAdministrativeArea != null &&
                place.subAdministrativeArea!.isNotEmpty &&
                place.subAdministrativeArea != place.locality) {
              parts.add(place.subAdministrativeArea!);
            }
            if (place.administrativeArea != null &&
                place.administrativeArea!.isNotEmpty) {
              parts.add(place.administrativeArea!);
            }

            if (parts.isNotEmpty) {
              address = parts.join(', ');
              break;
            }
          }
        } catch (_) {
          await Future.delayed(const Duration(seconds: 1));
        }
      }

      // Fallback to coordinates if all retries failed
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
      // Step 1: ML service check
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
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
                SizedBox(width: 8),
                Text('Not a Leak'),
              ],
            ),
            content: Text(
              'The image does not appear to be a water leak.\n'
                  'Confidence: ${mlData['confidence']}%\n\n'
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

  @override
  void dispose() {
    _fullNameController.dispose();
    super.dispose();
  }

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
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
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
                      icon: const Icon(Icons.settings_outlined, color: Color(0xFF0288D1)),
                      onPressed: () => Navigator.pushNamed(context, '/settings'),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Center(
                        child: Text(
                          'Manage Leaks',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF01579B),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Image preview
                      Container(
                        width: double.infinity,
                        height: 200,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE1F5FE),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF81D4FA), width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF29B6F6).withOpacity(0.18),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: widget.image != null
                            ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(widget.image!, fit: BoxFit.cover),
                        )
                            : const Center(
                          child: Icon(Icons.image_outlined, size: 60, color: Color(0xFF81D4FA)),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Full Name
                      const Text(
                        'Full Name',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF0277BD)),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _fullNameController,
                        decoration: InputDecoration(
                          hintText: 'Enter your full name',
                          hintStyle: const TextStyle(color: Color(0xFF90CAF9)),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.85),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFF81D4FA), width: 1.5),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFF0288D1), width: 2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // GPS Location
                      const Text(
                        'Location (GPS)',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF0277BD)),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF81D4FA), width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF29B6F6).withOpacity(0.10),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            _locationLoading
                                ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0288D1)),
                            )
                                : Icon(
                              _position != null ? Icons.location_on : Icons.location_off,
                              color: _position != null ? const Color(0xFF0288D1) : Colors.orange,
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
                              icon: const Icon(Icons.refresh, size: 18, color: Color(0xFF0288D1)),
                              onPressed: _locationLoading ? null : _getLocation,
                              tooltip: 'Refresh location',
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
                                  ? [const Color(0xFF29B6F6), const Color(0xFF0288D1)]
                                  : [Colors.grey.shade400, Colors.grey.shade500],
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
                            onPressed: (_isLoading || _position == null) ? null : _submitReport,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : Text(
                              _position != null ? 'Submit Report' : 'Waiting for GPS...',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
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