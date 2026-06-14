import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../services/supabase_service.dart';

class AuthResult {
  const AuthResult({required this.isSuccess, required this.message});

  final bool isSuccess;
  final String message;
}

class AuthProvider extends ChangeNotifier {
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
      _initialized = true;
      notifyListeners();
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Auth initialization error: $error');
      }
      _initialized = true;
      notifyListeners();
    }
  }

  Future<AuthResult> login({required String nic, required String pin}) async {
    _busy = true;
    notifyListeners();

    try {
      if (!SupabaseService.isConfigured) {
        return const AuthResult(
          isSuccess: false,
          message: 'Supabase is not configured.',
        );
      }

      final userData = await SupabaseService.authenticateNicPin(nic, pin);
      if (userData == null) {
        return const AuthResult(
          isSuccess: false,
          message: 'Invalid NIC or PIN.',
        );
      }

      _currentUser = _mapBackendUserToAppUser(userData);
      notifyListeners();
      return const AuthResult(isSuccess: true, message: 'Login successful.');
    } catch (e) {
      return AuthResult(isSuccess: false, message: 'Connection error: $e');
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<AuthResult> completeRegistration(AppUser user) async {
    _busy = true;
    notifyListeners();

    try {
      if (!SupabaseService.isConfigured) {
        return const AuthResult(
          isSuccess: false,
          message: 'Supabase is not configured.',
        );
      }

      final userData = {
        'nic': user.nic.toUpperCase(),
        'first_name': user.firstName,
        'last_name': user.lastName,
        'phone': user.phone,
        'password_hash': user.pin,
        'language': 'si', // Default
        'district': user.districtName ?? '',
        'ds_area': user.dsAreaName ?? '',
        'job_category_ids': user.jobCategoryIds,
        'skill_ids': user.skillIds,
        'rating': 0.0,
        'completed_jobs_count': 0,
        'abandoned_jobs_count': 0,
        'posted_jobs_count': 0,
        'applied_jobs_count': 0,
        'removed_jobs_count': 0,
        'is_blocked': 0,
        'availability_status': 'available',
        'profile_photo_url': null,
      };

      await SupabaseService.registerNicPinUser(userData);
      _currentUser = user;
      notifyListeners();

      return const AuthResult(
        isSuccess: true,
        message: 'Registration successful.',
      );
    } catch (e) {
      return AuthResult(isSuccess: false, message: 'Registration error: $e');
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<bool> uploadProfilePhoto(String filePath) async {
    if (_currentUser == null) return false;
    try {
      final fileUri = Uri.tryParse(filePath);
      if (fileUri != null && fileUri.hasScheme) {
        await SupabaseService.saveUserProfile(_currentUser!.nic, {
          'profile_photo_url': filePath,
        });
        _currentUser = _currentUser!.copyWith(profilePhotoPath: filePath);
        notifyListeners();
        return true;
      }
      if (kDebugMode) {
        debugPrint('Profile photo upload is not configured for local paths.');
      }
    } catch (e) {
      debugPrint('Photo upload error: $e');
    }
    return false;
  }

  Future<void> saveUser(AppUser user) async {
    final data = {
      'first_name': user.firstName,
      'last_name': user.lastName,
      'district': user.districtName,
      'ds_area': user.dsAreaName,
      'job_category_ids': user.jobCategoryIds,
      'skill_ids': user.skillIds,
    };

    if (!SupabaseService.isConfigured) {
      return;
    }

    await SupabaseService.saveUserProfile(user.nic, data);

    // Refresh local copy
    final userData = await SupabaseService.fetchUserProfile(user.nic);
    if (userData != null) {
      _currentUser = _mapBackendUserToAppUser(userData);
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _currentUser = null;
    notifyListeners();
  }

  AppUser _mapBackendUserToAppUser(Map<String, dynamic> data) {
    return AppUser(
      nic: data['nic'] ?? '',
      firstName: data['first_name'] ?? '',
      lastName: data['last_name'] ?? '',
      phone: data['phone'] ?? '',
      pin: '',
      districtName: data['district'] ?? '',
      dsAreaName: data['ds_area'] ?? '',
      jobCategoryIds: List<String>.from(data['job_category_ids'] ?? []),
      jobCategoryNames: [],
      skillIds: List<String>.from(data['skill_ids'] ?? []),
      skillNames: [],
      profilePhotoPath: data['profile_photo_url'] ?? data['profile_photo_path'],
      rating: (data['rating'] ?? 0.0).toDouble(),
      completedJobsCount: data['completed_jobs_count'] ?? 0,
      abandonedJobsCount: data['abandoned_jobs_count'] ?? 0,
      reviews: (data['reviews'] as List? ?? [])
          .map((r) => Review.fromMap(r))
          .toList(),
    );
  }

  AppUser? getUser(String nic) {
    if (_currentUser?.nic == nic) return _currentUser;
    return null;
  }

  Future<List<AppUser>> getUsers(List<String> nics) async {
    final users = <AppUser>[];
    if (!SupabaseService.isConfigured) {
      return users;
    }

    for (String nic in nics) {
      final data = await SupabaseService.fetchUserProfile(nic);
      if (data != null) {
        users.add(_mapBackendUserToAppUser(data));
      }
    }
    return users;
  }

  Future<void> addReview(String workerId, Review review) async {
    if (!SupabaseService.isConfigured) {
      return;
    }

    await SupabaseService.addReview(workerId, review);
  }
}
