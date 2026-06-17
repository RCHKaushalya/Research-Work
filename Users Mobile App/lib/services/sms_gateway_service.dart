import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/supabase_config.dart';

class SmsGatewayService {
  static String normalizePhone(String phone) {
    final cleaned = phone.trim().replaceAll(RegExp(r'[\s().-]+'), '');
    if (cleaned.isEmpty) return cleaned;
    if (cleaned.startsWith('+')) return cleaned;
    if (cleaned.startsWith('0')) return '+94${cleaned.substring(1)}';
    if (cleaned.startsWith('94')) return '+$cleaned';
    return '+$cleaned';
  }

  static Future<bool> sendSms({
    required String phoneNumber,
    required String message,
  }) async {
    if (SupabaseConfig.smsGatewayApiKey.isEmpty) return false;

    final uri = Uri.parse(SupabaseConfig.smsGatewayUrl).replace(
      queryParameters: {
        'key': SupabaseConfig.smsGatewayApiKey,
        'number': normalizePhone(phoneNumber),
        'message': message,
        'devices': SupabaseConfig.smsGatewayDevices,
        'type': 'sms',
        'prioritize': '0',
      },
    );

    final response = await http.get(uri).timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) return false;

    try {
      final payload = jsonDecode(response.body);
      return payload is Map && payload['success'] == true;
    } catch (_) {
      return false;
    }
  }
}
