import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../services/location_service.dart';
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
        'district': user.districtId ?? user.districtName ?? '',
        'ds_area': user.dsAreaId ?? user.dsAreaName ?? '',
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
        'portfolio_photo_urls': user.portfolioPhotos,
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

  Future<bool> uploadProfilePhoto({
    required Uint8List bytes,
    required String fileName,
  }) async {
    if (_currentUser == null) return false;
    try {
      final publicUrl = await SupabaseService.uploadProfilePhoto(
        nic: _currentUser!.nic,
        bytes: bytes,
        fileName: fileName,
      );

      await SupabaseService.saveUserProfile(_currentUser!.nic, {
        'profile_photo_url': publicUrl,
      });
      _currentUser = _currentUser!.copyWith(profilePhotoPath: publicUrl);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Photo upload error: $e');
    }
    return false;
  }

  Future<bool> uploadPortfolioPhoto({
    required Uint8List bytes,
    required String fileName,
  }) async {
    if (_currentUser == null) return false;
    try {
      final publicUrl = await SupabaseService.uploadPortfolioPhoto(
        nic: _currentUser!.nic,
        bytes: bytes,
        fileName: fileName,
      );
      final portfolioPhotos = [..._currentUser!.portfolioPhotos, publicUrl];

      await SupabaseService.saveUserProfile(_currentUser!.nic, {
        'portfolio_photo_urls': portfolioPhotos,
      });

      _currentUser = _currentUser!.copyWith(portfolioPhotos: portfolioPhotos);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Portfolio upload error: $e');
    }
    return false;
  }

  Future<void> saveUser(AppUser user) async {
    final data = {
      'first_name': user.firstName,
      'last_name': user.lastName,
      'phone': user.phone,
      'district': user.districtId ?? user.districtName,
      'ds_area': user.dsAreaId ?? user.dsAreaName,
      'job_category_ids': user.jobCategoryIds,
      'skill_ids': user.skillIds,
      'profile_photo_url': user.profilePhotoPath,
      'portfolio_photo_urls': user.portfolioPhotos,
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

  void saveLocalUser(AppUser user) {
    _currentUser = user;
    notifyListeners();
  }

  Future<void> logout() async {
    _currentUser = null;
    notifyListeners();
  }

  AppUser _mapBackendUserToAppUser(Map<String, dynamic> data) {
    final locationService = LocationService();
    final districtId = (data['district'] ?? '').toString();
    final dsAreaId = (data['ds_area'] ?? '').toString();

    return AppUser(
      nic: data['nic'] ?? '',
      firstName: data['first_name'] ?? '',
      lastName: data['last_name'] ?? '',
      phone: data['phone'] ?? '',
      pin: '',
      districtId: districtId,
      districtName: locationService.getDistrictName(districtId),
      dsAreaId: dsAreaId,
      dsAreaName: locationService.getDSAreaName(dsAreaId, districtId),
      jobCategoryIds: List<String>.from(data['job_category_ids'] ?? []),
      jobCategoryNames: [],
      skillIds: List<String>.from(data['skill_ids'] ?? []),
      skillNames: [],
      profilePhotoPath: data['profile_photo_url'] ?? data['profile_photo_path'],
      portfolioPhotos: List<String>.from(
        data['portfolio_photo_urls'] ?? data['portfolioPhotos'] ?? [],
      ),
      rating: _toDouble(data['rating']),
      completedJobsCount: _toInt(data['completed_jobs_count']),
      abandonedJobsCount: _toInt(data['abandoned_jobs_count']),
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

  Future<List<AppUser>> searchUsers(String query) async {
    final trimmed = query.trim().toLowerCase();
    if (trimmed.isEmpty || !SupabaseService.isConfigured) {
      return [];
    }

    final rows = await SupabaseService.fetchUsers(limit: 150);
    return rows.map(_mapBackendUserToAppUser).where((user) {
      final haystack = [
        user.nic,
        user.firstName,
        user.lastName,
        user.fullName,
        user.phone,
        user.districtName ?? '',
        user.dsAreaName ?? '',
        ...user.jobCategoryIds,
        ...user.skillIds,
      ].join(' ').toLowerCase();
      return haystack.contains(trimmed);
    }).toList();
  }

  Future<void> addReview(String workerId, Review review) async {
    if (!SupabaseService.isConfigured) {
      return;
    }

    await SupabaseService.addReview(workerId, review);
  }

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  int _toInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
