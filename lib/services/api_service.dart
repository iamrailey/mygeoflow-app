import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  static const String baseUrl = 'https://geoflow.duckdns.org/api';

  // ── Use flutter_secure_storage instead of SharedPreferences ──────
  // Tokens are sensitive — SharedPreferences stores them unencrypted
  // on disk; FlutterSecureStorage uses Android Keystore / iOS Keychain.
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true, // AES encryption via Jetpack Security
    ),
  );

  // ── Register ─────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> register(
      String name, String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': password,
      }),
    );
    return jsonDecode(response.body);
  }

  // ── Login ────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> login(
      String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );
    return jsonDecode(response.body);
  }

  // ── Token ────────────────────────────────────────────────────────
  static Future<void> saveToken(String token) async {
    await _storage.write(key: 'auth_token', value: token);
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: 'auth_token');
  }

  static Future<void> deleteToken() async {
    await _storage.delete(key: 'auth_token');
  }

  // ── Role ─────────────────────────────────────────────────────────
  static Future<void> saveRole(String role) async {
    await _storage.write(key: 'user_role', value: role);
  }

  static Future<String?> getRole() async {
    return await _storage.read(key: 'user_role');
  }

  static Future<void> deleteRole() async {
    await _storage.delete(key: 'user_role');
  }

  // ── Inspector status ─────────────────────────────────────────────
  // Possible values: 'pending', 'approved', 'rejected'
  static Future<void> saveInspectorStatus(String status) async {
    await _storage.write(key: 'inspector_status', value: status);
  }

  static Future<String?> getInspectorStatus() async {
    // Always fetch fresh from the API so the pending screen
    // reflects the latest admin decision.
    try {
      final token = await getToken();
      if (token == null) return null;
      final res = await http.get(
        Uri.parse('$baseUrl/user'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final status = data['inspector_status'] as String?;
        if (status != null) {
          await _storage.write(key: 'inspector_status', value: status);
        }
        return status;
      }
    } catch (_) {}
    // Fall back to cached value if network fails
    return await _storage.read(key: 'inspector_status');
  }

  static Future<void> deleteInspectorStatus() async {
    await _storage.delete(key: 'inspector_status');
  }

  // ── Logout ───────────────────────────────────────────────────────
  // Revokes the token server-side then wipes all local storage.
  static Future<void> logout() async {
    try {
      final token = await getToken();
      if (token != null) {
        await http.post(
          Uri.parse('$baseUrl/logout'),
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        );
      }
    } catch (_) {}
    await _storage.deleteAll();
  }
}
