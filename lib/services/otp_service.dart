import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class OTPService {
  // Use 10.0.2.2 for Android Emulator to access host machine's localhost
  // Use 'localhost' or your machine's IP for iOS Simulator or physical device
  static const String baseUrl = 'http://10.0.2.2:5000/api';

  // Setup 2FA for user
  static Future<Map<String, dynamic>> setup2FA(String userEmail) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/setup-2fa'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userEmail': userEmail}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Save secret to secure storage
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('totp_secret', data['secret']);
        return data;
      } else {
        throw Exception('Failed to setup 2FA: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Connection error: $e');
    }
  }

  // Verify OTP
  static Future<bool> verifyOTP(String otp) async {
    final prefs = await SharedPreferences.getInstance();
    final secret = prefs.getString('totp_secret');

    if (secret == null) {
      throw Exception('No 2FA secret found. Please setup 2FA first.');
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userSecret': secret, 'otp': otp}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body)['valid'];
      }
      return false;
    } catch (e) {
      throw Exception('Connection error: $e');
    }
  }
}
