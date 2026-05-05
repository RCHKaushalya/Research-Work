import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_user.dart';
import '../services/firebase_service.dart';

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
      FirebaseService.auth.authStateChanges().listen((User? user) async {
        if (user != null) {
          final email = user.email!;
          final nic = email.split('@')[0];
          await _restoreSession(nic);
        } else {
          _currentUser = null;
        }
        if (!_initialized) {
          _initialized = true;
          notifyListeners();
        } else {
          notifyListeners();
        }
      });
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Auth initialization error: $error');
      }
      _initialized = true;
      notifyListeners();
    }
  }

  Future<void> _restoreSession(String nic) async {
    final userData = await FirebaseService.getUserProfile(nic);
    if (userData != null) {
      _currentUser = _mapBackendUserToAppUser(userData);
    } else {
      // User is authenticated in Firebase Auth but missing Firestore doc?
      // Handle edge case if needed, maybe sign out
    }
  }

  Future<AuthResult> login({required String nic, required String pin}) async {
    _busy = true;
    notifyListeners();

    try {
      await FirebaseService.signIn(nic, pin);
      // authStateChanges listener will handle the rest
      return const AuthResult(isSuccess: true, message: 'Login successful.');
    } on FirebaseAuthException catch (e) {
      return AuthResult(isSuccess: false, message: e.message ?? 'Login failed');
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
      // 1. Create Auth user
      await FirebaseService.register(user.nic, user.pin);
      
      // 2. Create Firestore profile
      final userData = {
        'nic': user.nic.toUpperCase(),
        'first_name': user.firstName,
        'last_name': user.lastName,
        'phone': user.phone,
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
      
      await FirebaseService.saveUserProfile(user.nic, userData);
      
      return const AuthResult(isSuccess: true, message: 'Registration successful.');
    } on FirebaseAuthException catch (e) {
      return AuthResult(isSuccess: false, message: e.message ?? 'Registration failed');
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
      final url = await FirebaseService.uploadProfilePhoto(_currentUser!.nic, filePath);
      if (url != null) {
        _currentUser = AppUser(
          nic: _currentUser!.nic,
          firstName: _currentUser!.firstName,
          lastName: _currentUser!.lastName,
          phone: _currentUser!.phone,
          pin: _currentUser!.pin,
          districtName: _currentUser!.districtName,
          dsAreaName: _currentUser!.dsAreaName,
          jobCategoryIds: _currentUser!.jobCategoryIds,
          jobCategoryNames: _currentUser!.jobCategoryNames,
          skillIds: _currentUser!.skillIds,
          skillNames: _currentUser!.skillNames,
          profilePhotoPath: url, // using new URL
          rating: _currentUser!.rating,
          completedJobsCount: _currentUser!.completedJobsCount,
          abandonedJobsCount: _currentUser!.abandonedJobsCount,
        );
        notifyListeners();
        return true;
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
    
    await FirebaseService.saveUserProfile(user.nic, data);
    
    // Refresh local copy
    final userData = await FirebaseService.getUserProfile(user.nic);
    if (userData != null) {
      _currentUser = _mapBackendUserToAppUser(userData);
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await FirebaseService.signOut();
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
    );
  }

  AppUser? getUser(String nic) {
    if (_currentUser?.nic == nic) return _currentUser;
    return null;
  }
}
