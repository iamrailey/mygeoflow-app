import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';

class AssignedReportsScreen extends StatefulWidget {
  const AssignedReportsScreen({super.key});

  @override
  State<AssignedReportsScreen> createState() => _AssignedReportsScreenState();
}

class _AssignedReportsScreenState extends State<AssignedReportsScreen> {
  List<dynamic> _reports = [];
  bool _loading = true;
  bool _darkTheme = false;

  @override
  void initState() {
    super.initState();
    _loadTheme();
    _fetchAssignments();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _darkTheme = prefs.getBool('darkTheme') ?? false);
  }

  Color get _bgStart       => _darkTheme ? const Color(0xFF1A1A2E) : const Color(0xFFB3E5FC);
  Color get _bgMid         => _darkTheme ? const Color(0xFF16213E) : const Color(0xFFE1F5FE);
  Color get _bgEnd         => _darkTheme ? const Color(0xFF0F3460) : const Color(0xFFFFFFFF);
  Color get _titleColor    => _darkTheme ? const Color(0xFF90CAF9) : const Color(0xFF01579B);
  Color get _subtitleColor => _darkTheme ? const Color(0xFF64B5F6) : const Color(0xFF0277BD);
  Color get _cardBg        => _darkTheme ? const Color(0xFF1E2A3A) : Colors.white;
  Color get _cardBorder    => _darkTheme ? const Color(0xFF2A4A6B) : const Color(0xFF81D4FA);
  Color get _iconColor     => _darkTheme ? const Color(0xFF64B5F6) : const Color(0xFF0288D1);

  Future<void> _fetchAssignments() async {
    setState(() => _loading = true);
    try {
      final token = await ApiService.getToken();
      final res = await http.get(
        Uri.parse('${ApiService.baseUrl}/my-assignments'),
        headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
      );
      if (res.statusCode == 200) {
        setState(() => _reports = jsonDecode(res.body));
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Verified':     return Colors.green;
      case 'Under Review': return Colors.orange;
      case 'Resolved':     return Colors.blue;
      default:             return Colors.grey;
    }
  }

  void _showUpdateSheet(Map report) {
    String selectedStatus = report['status'] == 'Verified' || report['status'] == 'Under Review'
        ? report['status'] : 'Under Review';
    final notesController = TextEditingController(text: report['notes'] ?? '');
    File? pickedImage;
    bool submitting = false;

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
                colors: [_bgStart, _bgMid, _bgEnd],
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
                  Text('Update Report', style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold, color: _titleColor,
                  )),
                  Text(report['report_id'] ?? '', style: TextStyle(fontSize: 13, color: _subtitleColor)),
                  const SizedBox(height: 20),

                  // Photo section
                  Text('Site Photo (optional)', style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600, color: _subtitleColor,
                  )),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () async {
                      final picker = ImagePicker();
                      final picked = await picker.pickImage(
                        source: ImageSource.camera,
                        imageQuality: 80,
                      );
                      if (picked != null) {
                        setSheet(() => pickedImage = File(picked.path));
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      height: 140,
                      decoration: BoxDecoration(
                        color: _cardBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: pickedImage != null ? _iconColor : _cardBorder,
                          width: pickedImage != null ? 2 : 1.5,
                        ),
                      ),
                      child: pickedImage != null
                          ? ClipRRect(
                        borderRadius: BorderRadius.circular(9),
                        child: Image.file(pickedImage!, fit: BoxFit.cover),
                      )
                          : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo_outlined, size: 32, color: _cardBorder),
                          const SizedBox(height: 8),
                          Text('Tap to add photo', style: TextStyle(
                            fontSize: 13, color: _cardBorder,
                          )),
                        ],
                      ),
                    ),
                  ),
                  if (pickedImage != null) ...[
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () => setSheet(() => pickedImage = null),
                      child: Text('Remove photo',
                        style: TextStyle(fontSize: 12, color: Colors.red.shade400),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),

                  // Status dropdown
                  Text('Status', style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600, color: _subtitleColor,
                  )),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: _cardBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _cardBorder, width: 1.5),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedStatus,
                        isExpanded: true,
                        dropdownColor: _cardBg,
                        style: TextStyle(color: _titleColor, fontSize: 14),
                        items: ['Under Review', 'Verified'].map((s) => DropdownMenuItem(
                          value: s,
                          child: Text(s),
                        )).toList(),
                        onChanged: (val) => setSheet(() => selectedStatus = val!),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Notes
                  Text('Notes / Reason', style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600, color: _subtitleColor,
                  )),
                  const SizedBox(height: 8),
                  TextField(
                    controller: notesController,
                    maxLines: 3,
                    style: TextStyle(color: _titleColor, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Describe your findings...',
                      hintStyle: TextStyle(color: _cardBorder),
                      filled: true,
                      fillColor: _cardBg,
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
                  const SizedBox(height: 24),

                  // Submit button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: submitting ? null : () async {
                        setSheet(() => submitting = true);
                        try {
                          final token = await ApiService.getToken();

                          if (pickedImage != null) {
                            // Use multipart if there's a photo
                            final request = http.MultipartRequest(
                              'POST',
                              Uri.parse('${ApiService.baseUrl}/my-assignments/${report['id']}'),
                            );
                            request.headers['Authorization'] = 'Bearer $token';
                            request.headers['Accept'] = 'application/json';
                            request.fields['status'] = selectedStatus;
                            request.fields['notes'] = notesController.text;
                            request.fields['_method'] = 'PUT'; // Laravel method spoofing
                            request.files.add(
                              await http.MultipartFile.fromPath('image', pickedImage!.path),
                            );
                            final streamed = await request.send();
                            final res = await http.Response.fromStream(streamed);
                            if (res.statusCode == 200) {
                              Navigator.pop(ctx);
                              _fetchAssignments();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Report updated successfully!')),
                              );
                            } else {
                              final body = jsonDecode(res.body);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(body['message'] ?? 'Update failed')),
                              );
                            }
                          } else {
                            // No photo — plain JSON POST
                            final res = await http.post(
                              Uri.parse('${ApiService.baseUrl}/my-assignments/${report['id']}'),
                              headers: {
                                'Authorization': 'Bearer $token',
                                'Accept': 'application/json',
                                'Content-Type': 'application/json',
                              },
                              body: jsonEncode({
                                'status': selectedStatus,
                                'notes': notesController.text,
                              }),
                            );
                            if (res.statusCode == 200) {
                              Navigator.pop(ctx);
                              _fetchAssignments();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Report updated successfully!')),
                              );
                            } else {
                              final body = jsonDecode(res.body);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(body['message'] ?? 'Update failed')),
                              );
                            }
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e')),
                          );
                        }
                        setSheet(() => submitting = false);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _iconColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: submitting
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Save Update', style: TextStyle(
                        color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600,
                      )),
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

  // Builds a single rounded thumbnail from a storage-relative path.
  Widget _thumb(String? path) {
    if (path == null) {
      return Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _cardBorder),
        ),
        child: Icon(Icons.image, color: _cardBorder, size: 20),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        'https://geoflow.duckdns.org/storage/$path',
        width: 56, height: 56, fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: 56,
          height: 56,
          color: _cardBg,
          child: Icon(Icons.broken_image, color: _cardBorder, size: 20),
        ),
      ),
    );
  }

  // Leading widget for each assignment card.
  // Shows the original reporter photo, and — once the inspector has
  // uploaded one — the inspection photo right next to it with a small
  // camera badge so it's clear which is which.
  Widget _buildLeading(Map r) {
    final hasInspection = r['inspection_image'] != null;

    if (!hasInspection) {
      return _thumb(r['image']);
    }

    return SizedBox(
      width: 116,
      height: 56,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _thumb(r['image']),
          const SizedBox(width: 4),
          Stack(
            clipBehavior: Clip.none,
            children: [
              _thumb(r['inspection_image']),
              Positioned(
                bottom: -2,
                right: -2,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: _iconColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: const Icon(Icons.camera_alt, size: 10, color: Colors.white),
                ),
              ),
            ],
          ),
        ],
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
            colors: [_bgStart, _bgMid, _bgEnd],
            stops: const [0.0, 0.45, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Text('My Assignments', style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold, color: _titleColor,
                    )),
                    const Spacer(),
                    IconButton(
                      icon: Icon(Icons.refresh, color: _iconColor),
                      onPressed: _fetchAssignments,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _loading
                    ? Center(child: CircularProgressIndicator(color: _iconColor))
                    : _reports.isEmpty
                    ? Center(child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.assignment_outlined, size: 64, color: _cardBorder),
                    const SizedBox(height: 12),
                    Text('No assignments yet', style: TextStyle(color: _subtitleColor)),
                  ],
                ))
                    : RefreshIndicator(
                  onRefresh: _fetchAssignments,
                  color: _iconColor,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _reports.length,
                    itemBuilder: (context, index) {
                      final r = _reports[index];
                      final status = r['status'] ?? 'Pending';
                      final isLocked = status == 'Resolved';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: _cardBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _cardBorder),
                          boxShadow: [BoxShadow(
                            color: const Color(0xFF0288D1).withOpacity(0.07),
                            blurRadius: 6, offset: const Offset(0, 2),
                          )],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          leading: _buildLeading(r),
                          title: Text(r['report_id'] ?? 'Unknown', style: TextStyle(
                            fontWeight: FontWeight.bold, color: _titleColor, fontSize: 14,
                          )),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(r['type'] ?? '', style: TextStyle(fontSize: 12, color: _subtitleColor)),
                              Text(r['location'] ?? '', style: TextStyle(fontSize: 11, color: _cardBorder)),
                              if (r['notes'] != null && r['notes'].toString().isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text('Note: ${r['notes']}', style: TextStyle(
                                  fontSize: 11, color: _subtitleColor, fontStyle: FontStyle.italic,
                                )),
                              ],
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _statusColor(status).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(color: _statusColor(status)),
                                ),
                                child: Text(status, style: TextStyle(
                                  fontSize: 11, color: _statusColor(status), fontWeight: FontWeight.w600,
                                )),
                              ),
                            ],
                          ),
                          trailing: isLocked
                              ? Icon(Icons.lock, color: _cardBorder, size: 20)
                              : IconButton(
                            icon: Icon(Icons.edit_outlined, color: _iconColor),
                            onPressed: () => _showUpdateSheet(r),
                          ),
                        ),
                      );
                    },
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
