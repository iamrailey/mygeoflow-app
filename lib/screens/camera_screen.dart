import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:io';
import 'manage_leaks_screen.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isFlashOff = true;
  File? _capturedImage;
  bool _showConfirmDialog = false;
  int _selectedCameraIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  Future<void> _initCamera() async {
    _cameras = await availableCameras();
    if (_cameras == null || _cameras!.isEmpty) return;

    await _startCamera(_selectedCameraIndex);
  }

  Future<void> _startCamera(int index) async {
    final controller = CameraController(
      _cameras![index],
      ResolutionPreset.high,
      enableAudio: false,
    );

    try {
      await controller.initialize();
      if (!mounted) return;

      setState(() {
        _controller = controller;
        _isInitialized = true;
      });
    } catch (e) {
      debugPrint('Camera init error: $e');
    }
  }

  Future<void> _takePhoto() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    try {
      final XFile photo = await _controller!.takePicture();
      setState(() {
        _capturedImage = File(photo.path);
        _showConfirmDialog = true;
      });
    } catch (e) {
      debugPrint('Take photo error: $e');
    }
  }

  Future<void> _flipCamera() async {
    if (_cameras == null || _cameras!.length < 2) return;

    _selectedCameraIndex = _selectedCameraIndex == 0 ? 1 : 0;

    await _controller?.dispose();
    setState(() => _isInitialized = false);
    await _startCamera(_selectedCameraIndex);
  }

  Future<void> _toggleFlash() async {
    if (_controller == null) return;
    setState(() => _isFlashOff = !_isFlashOff);
    await _controller!.setFlashMode(
      _isFlashOff ? FlashMode.off : FlashMode.torch,
    );
  }

  void _submitPhoto() {
    setState(() => _showConfirmDialog = false);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ManageLeaksScreen(image: _capturedImage),
      ),
    );
  }

  void _retakePhoto() {
    setState(() {
      _capturedImage = null;
      _showConfirmDialog = false;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      _controller?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _startCamera(_selectedCameraIndex);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(
              _isFlashOff ? Icons.flash_off : Icons.flash_on,
              color: Colors.white,
            ),
            onPressed: _toggleFlash,
          ),
          IconButton(
            icon: const Icon(Icons.hdr_on, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.timer_outlined, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: Stack(
        children: [
          // ── Live camera preview or captured image ──
          Positioned.fill(
            child: _showConfirmDialog && _capturedImage != null
                ? Image.file(_capturedImage!, fit: BoxFit.cover)
                : _isInitialized && _controller != null
                ? CameraPreview(_controller!)
                : const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          ),

          // ── Confirm dialog overlay ──
          if (_showConfirmDialog)
            Center(
              child: Container(
                margin: const EdgeInsets.all(32),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFFB3E5FC),
                      Color(0xFFE1F5FE),
                      Color(0xFFFFFFFF),
                    ],
                    stops: [0.0, 0.45, 1.0],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF81D4FA), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0288D1).withOpacity(0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircleAvatar(
                      radius: 28,
                      backgroundColor: Color(0xFF0288D1),
                      child: Icon(Icons.camera_alt, color: Colors.white, size: 28),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Done Taking a Photo?',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF01579B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'You can submit or retake the photo.',
                      style: TextStyle(fontSize: 13, color: Color(0xFF0277BD)),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Submit button
                        DecoratedBox(
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
                            onPressed: _submitPhoto,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 28, vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text(
                              'Submit',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                        // Retake button
                        OutlinedButton(
                          onPressed: _retakePhoto,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 28, vertical: 12),
                            side: const BorderSide(
                                color: Color(0xFF0288D1), width: 1.5),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text(
                            'Retake',
                            style: TextStyle(
                              color: Color(0xFF0288D1),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

          // ── Bottom camera controls ──
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 24),
              color: Colors.black.withOpacity(0.5),
              child: Column(
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('VIDEO',
                          style: TextStyle(color: Colors.white54, fontSize: 12)),
                      SizedBox(width: 16),
                      Text('PHOTO',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold)),
                      SizedBox(width: 16),
                      Text('SQUARE',
                          style: TextStyle(color: Colors.white54, fontSize: 12)),
                      SizedBox(width: 16),
                      Text('PANO',
                          style: TextStyle(color: Colors.white54, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Gallery placeholder
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.photo, color: Colors.white),
                      ),

                      // Shutter button
                      GestureDetector(
                        onTap: _takePhoto,
                        child: Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white54, width: 3),
                          ),
                        ),
                      ),

                      // Flip camera button
                      IconButton(
                        icon: const Icon(Icons.flip_camera_ios,
                            color: Colors.white, size: 30),
                        onPressed: _flipCamera,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}