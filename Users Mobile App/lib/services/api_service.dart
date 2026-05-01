import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hive_flutter/hive_flutter.dart';

class ApiService {
  static const String baseUrl = 'https://informal-worker.onrender.com'; // Live Render Backend
  static const String _sessionBoxName = 'session_box';
  static const String _tokenKey = 'jwt_token';

  static Future<String?> getToken() async {
    final box = await Hive.openBox(_sessionBoxName);
    return box.get(_tokenKey);
  }

  static Future<void> saveToken(String token) async {
    final box = await Hive.openBox(_sessionBoxName);
    await box.put(_tokenKey, token);
  }

  static Future<void> deleteToken() async {
    final box = await Hive.openBox(_sessionBoxName);
    await box.delete(_tokenKey);
  }

  static Future<Map<String, String>> _getHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<http.Response> get(String endpoint) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final headers = await _getHeaders();
    return await http.get(url, headers: headers);
  }

  static Future<http.Response> post(String endpoint, Map<String, dynamic> body) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final headers = await _getHeaders();
    return await http.post(url, headers: headers, body: jsonEncode(body));
  }

  static Future<http.Response> put(String endpoint, Map<String, dynamic> body) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final headers = await _getHeaders();
    return await http.put(url, headers: headers, body: jsonEncode(body));
  }

  static Future<http.Response> uploadFile(String endpoint, String filePath, {String field = 'file'}) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final token = await getToken();
    
    var request = http.MultipartRequest('POST', url);
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    request.files.add(await http.MultipartFile.fromPath(field, filePath));
    
    var streamedResponse = await request.send();
    return await http.Response.fromStream(streamedResponse);
  }
}
