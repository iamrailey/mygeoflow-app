import 'package:flutter/material.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';

class ManageLeaksScreen extends StatefulWidget {
  final File? image;

  const ManageLeaksScreen({super.key, this.image});

  @override
  State<ManageLeaksScreen> createState() => _ManageLeaksScreenState();
}

class _ManageLeaksScreenState extends State<ManageLeaksScreen> {
  final _fullNameController = TextEditingController();
  final _locationController = TextEditingController();
  bool _isLoading = false;

  void _submitReport() async {
    if (_fullNameController.text.isEmpty || _locationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields!')),
      );
      return;
    }

    if (widget.image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please take a photo first!')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final token = await ApiService.getToken();

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiService.baseUrl}/reports'),
      );

      // Auth header
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      // Fields
      request.fields['full_name'] = _fullNameController.text;
      request.fields['location'] = _locationController.text;

      // Image
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
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const Padding(
          padding: EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: Colors.grey,
            child: Icon(Icons.person, color: Colors.white),
          ),
        ),
        title: const Text(
          'GeoFlow',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.black),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
      body: SingleChildScrollView(
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
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Image preview
            Center(
              child: Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade400),
                ),
                child: widget.image != null
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    widget.image!,
                    fit: BoxFit.cover,
                  ),
                )
                    : const Center(
                  child: Icon(
                    Icons.image_outlined,
                    size: 60,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Full Name
            const Text(
              'Full Name',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _fullNameController,
              decoration: InputDecoration(
                hintText: 'Enter your full name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Location
            const Text(
              'Location',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _locationController,
              decoration: InputDecoration(
                hintText: 'e.g. Diliman, Quezon City',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitReport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade300,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.black)
                    : const Text(
                  'Submit Report',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}