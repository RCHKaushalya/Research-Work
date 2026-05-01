import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/app_user.dart';
import '../services/api_service.dart';

class AuthResult {
  const AuthResult({required this.isSuccess, required this.message});

  final bool isSuccess;
  final String message;
}

class AuthProvider extends ChangeNotifier {
  static const String _sessionBoxName = 'session_box';
  static const String _activeUserNicKey = 'active_user_nic';

  AppUser? _currentUser;
  bool _initialized = false;
  bool _busy = false;

  AppUser? get currentUser => _currentUser;
  bool get isInitialized => _initialized;
  bool get isBusy => _busy;
  bool get isAuthenticated => _currentUser != null;

  AuthProvider() {
    init();
  }

  Future<void> init() async {
    try {
      await Hive.initFlutter();
      await _openBoxes();
      await _restoreSession();
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Auth initialization error: $error');
      }
    } finally {
      _initialized = true;
      notifyListeners();
    }
  }

  Future<void> _openBoxes() async {
    if (!Hive.isBoxOpen(_sessionBoxName)) {
      await Hive.openBox(_sessionBoxName);
    }
  }

  Box<dynamic> get _sessionBox => Hive.box(_sessionBoxName);

  Future<void> _restoreSession() async {
    final token = await ApiService.getToken();
    if (token == null) return;

    final response = await ApiService.get('/users/me');
    if (response.statusCode == 200) {
      final userData = jsonDecode(response.body);
      // Map backend fields to frontend AppUser model
      _currentUser = _mapBackendUserToAppUser(userData);
    } else {
      await ApiService.deleteToken();
    }
  }

  Future<AuthResult> login({required String nic, required String pin}) async {
    _busy = true;
    notifyListeners();

    try {
      final response = await ApiService.post('/auth/login', {
        'nic': nic.trim().toUpperCase(),
        'pin': pin.trim(),
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await ApiService.saveToken(data['access_token']);
        
        // Fetch full profile
        final profileResponse = await ApiService.get('/users/me');
        if (profileResponse.statusCode == 200) {
          _currentUser = _mapBackendUserToAppUser(jsonDecode(profileResponse.body));
          return const AuthResult(isSuccess: true, message: 'Login successful.');
        }
      }
      
      return AuthResult(
        isSuccess: false, 
        message: _getErrorMessage(response.body),
      );
    } catch (e) {
      return AuthResult(isSuccess: false, message: 'Connection error: $e');
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> completeRegistration(AppUser user) async {
    _busy = true;
    notifyListeners();
    
    try {
      final response = await ApiService.post('/auth/register', {
        'nic': user.nic.toUpperCase(),
        'pin': user.pin,
        'first_name': user.firstName,
        'last_name': user.lastName,
        'phone': user.phone,
        'language': 'si', // Default, can be updated later
        'district': user.districtName ?? '',
        'ds_area': user.dsAreaName ?? '',
        'job_category_ids': user.jobCategoryIds,
        'skill_ids': user.skillIds,
      });

      if (response.statusCode == 200) {
        // Auto login after registration
        await login(nic: user.nic, pin: user.pin);
      }
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> saveUser(AppUser user) async {
    // Update profile on backend
    final response = await ApiService.put('/users/me', {
      'first_name': user.firstName,
      'last_name': user.lastName,
      'district': user.districtName,
      'ds_area': user.dsAreaName,
      'job_category_ids': user.jobCategoryIds,
      'skill_ids': user.skillIds,
    });
    
    if (response.statusCode == 200) {
      _currentUser = _mapBackendUserToAppUser(jsonDecode(response.body));
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _currentUser = null;
    await ApiService.deleteToken();
    notifyListeners();
  }

  AppUser _mapBackendUserToAppUser(Map<String, dynamic> data) {
    // Backend uses first_name, last_name, ds_area etc.
    // Frontend AppUser model needs them mapped correctly
    return AppUser(
      nic: data['nic'],
      firstName: data['first_name'],
      lastName: data['last_name'],
      phone: data['phone'],
      pin: '', // Pin not returned by backend
      districtName: data['district'],
      dsAreaName: data['ds_area'],
      jobCategoryIds: List<String>.from(data['job_category_ids'] ?? []),
      jobCategoryNames: [], // Backend could return names or we map from catalog
      skillIds: List<String>.from(data['skill_ids'] ?? []),
      skillNames: [],
      profilePhotoPath: data['profile_photo_path'],
      rating: (data['rating'] ?? 0.0).toDouble(),
      completedJobsCount: data['completed_jobs_count'] ?? 0,
      abandonedJobsCount: data['abandoned_jobs_count'] ?? 0,
    );
  }

  String _getErrorMessage(String body) {
    try {
      final data = jsonDecode(body);
      return data['detail'] ?? 'An error occurred.';
    } catch (_) {
      return 'An error occurred.';
    }
  }

  // To maintain compatibility with some existing UI parts
  AppUser? getUser(String nic) {
    // For now returning current user if matches or null
    if (_currentUser?.nic == nic) return _currentUser;
    return null;
  }
}
