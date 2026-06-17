import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/app_user.dart';
import '../models/job.dart';
import '../config/supabase_config.dart';

const String _supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const String _supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

class SupabaseService {
  static bool get isConfigured =>
      _effectiveUrl.isNotEmpty && _effectiveAnonKey.isNotEmpty;

  static String get _effectiveUrl =>
      _supabaseUrl.isNotEmpty ? _supabaseUrl : SupabaseConfig.url;

  static String get _effectiveAnonKey =>
      _supabaseAnonKey.isNotEmpty ? _supabaseAnonKey : SupabaseConfig.anonKey;

  static Future<void> initialize() async {
    if (!isConfigured) return;

    await Supabase.initialize(url: _effectiveUrl, anonKey: _effectiveAnonKey);
  }

  static SupabaseClient get client => Supabase.instance.client;

  static Future<String> uploadProfilePhoto({
    required String nic,
    required Uint8List bytes,
    required String fileName,
  }) async {
    return _uploadUserPhoto(
      nic: nic,
      bytes: bytes,
      fileName: fileName,
      prefix: 'profile',
    );
  }

  static Future<String> uploadPortfolioPhoto({
    required String nic,
    required Uint8List bytes,
    required String fileName,
  }) async {
    return _uploadUserPhoto(
      nic: nic,
      bytes: bytes,
      fileName: fileName,
      prefix: 'portfolio',
    );
  }

  static Future<String> _uploadUserPhoto({
    required String nic,
    required Uint8List bytes,
    required String fileName,
    required String prefix,
  }) async {
    if (!isConfigured) {
      throw StateError('Supabase is not configured.');
    }

    final extension = _extensionFor(fileName);
    final contentType = _contentTypeFor(extension);
    final storagePath =
        '${nic.toUpperCase()}/${prefix}_${DateTime.now().millisecondsSinceEpoch}.$extension';

    await client.storage
        .from('profile-photos')
        .uploadBinary(
          storagePath,
          bytes,
          fileOptions: FileOptions(contentType: contentType, upsert: true),
        );

    return client.storage.from('profile-photos').getPublicUrl(storagePath);
  }

  static Future<List<Job>> fetchJobs() async {
    if (!isConfigured) {
      return [];
    }

    final response = await client.from('jobs').select();
    final rows = response as List<dynamic>;

    return rows
        .map((row) => _mapJob(Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  /// Creates a job and returns the full row as created by the database
  /// (including the server-generated UUID). Throws on failure.
  static Future<Map<String, dynamic>> createJob(Job job) async {
    if (!isConfigured) {
      throw StateError('Supabase is not configured.');
    }

    final payload = <String, dynamic>{
      'title': job.title,
      'description': job.description,
      'employer_nic': job.employerId,
      'category': job.categoryName.isNotEmpty
          ? job.categoryName
          : job.categoryId,
      'location': job.location,
      'status': job.status,
      'required_skills': job.requiredSkillIds,
      'applied_worker_ids': job.appliedWorkerIds,
      'accepted_worker_ids': job.acceptedWorkerIds,
    };
    if (job.id.isNotEmpty) payload['id'] = job.id;

    // .select().single() causes Supabase to return the newly inserted row
    final row = await client.from('jobs').insert(payload).select().single();
    return Map<String, dynamic>.from(row as Map);
  }

  /// Returns workers whose district/ds_area and skills match the job.
  /// Used after posting a job to build the SMS notification list.
  static Future<List<Map<String, dynamic>>> fetchMatchingWorkers({
    required String district,
    required String dsArea,
    required List<String> skillIds,
  }) async {
    if (!isConfigured) return [];

    // Fetch all workers in the same district (broad location filter).
    // Fine-grained ds_area and skill filtering is done in Dart below
    // because Supabase REST doesn't support array-overlap in a single
    // simple query without RPC.
    final response = await client
        .from('users')
        .select('nic, phone, district, ds_area, skill_ids')
        .eq('district', district);

    final rows = response as List<dynamic>;
    final matches = <Map<String, dynamic>>[];

    for (final raw in rows) {
      final row = Map<String, dynamic>.from(raw as Map);
      final phone = (row['phone'] ?? '').toString();
      if (phone.isEmpty) continue; // must have a phone number

      // DS area filter: if a DS area was given, the worker must be in
      // either the same DS area or the broader district.
      if (dsArea.isNotEmpty) {
        final workerDs = (row['ds_area'] ?? '').toString().toLowerCase();
        final workerDistrict = (row['district'] ?? '').toString().toLowerCase();
        if (workerDs != dsArea.toLowerCase() &&
            workerDistrict != district.toLowerCase()) {
          continue;
        }
      }

      // Skill filter: at least one skill must overlap.
      if (skillIds.isNotEmpty) {
        final workerSkills = _stringList(row['skill_ids']);
        final hasOverlap = skillIds.any((s) => workerSkills.contains(s));
        if (!hasOverlap) continue;
      }

      matches.add(row);
    }

    return matches;
  }

  static Future<Map<String, dynamic>?> authenticateNicPin(
    String nic,
    String pin,
  ) async {
    if (!isConfigured) {
      return null;
    }

    final response = await client
        .from('users')
        .select()
        .eq('nic', nic.toUpperCase())
        .eq('password_hash', pin)
        .limit(1);

    final rows = response as List<dynamic>;
    if (rows.isEmpty) {
      return null;
    }

    return Map<String, dynamic>.from(rows.first as Map);
  }

  static Future<void> registerNicPinUser(Map<String, dynamic> data) async {
    if (!isConfigured) {
      throw StateError('Supabase is not configured.');
    }

    await client.from('users').upsert({
      ...data,
      'nic': (data['nic'] ?? '').toString().toUpperCase(),
    }, onConflict: 'nic');
  }

  static Future<void> updatePin(String nic, String pin) async {
    if (!isConfigured) {
      throw StateError('Supabase is not configured.');
    }

    await client
        .from('users')
        .update({'password_hash': pin})
        .eq('nic', nic.toUpperCase());
  }

  static Future<void> applyForJob(String jobId, String nic) async {
    final jobResponse = await client
        .from('jobs')
        .select()
        .eq('id', jobId)
        .limit(1);
    final jobRows = jobResponse as List<dynamic>;
    if (jobRows.isEmpty) {
      throw StateError('Job not found.');
    }

    final jobData = Map<String, dynamic>.from(jobRows.first as Map);
    final appliedWorkerIds = _stringList(jobData['applied_worker_ids']);
    final normalizedNic = nic.toUpperCase();

    if (appliedWorkerIds.contains(normalizedNic)) {
      return;
    }

    appliedWorkerIds.add(normalizedNic);

    await client.from('applications').upsert({
      'job_id': jobId,
      'worker_nic': normalizedNic,
      'status': 'applied',
      'applied_at': DateTime.now().toIso8601String(),
    }, onConflict: 'job_id,worker_nic');

    await client
        .from('jobs')
        .update({'applied_worker_ids': appliedWorkerIds})
        .eq('id', jobId);

    final userResponse = await client
        .from('users')
        .select()
        .eq('nic', normalizedNic)
        .limit(1);
    final userRows = userResponse as List<dynamic>;
    if (userRows.isNotEmpty) {
      final userData = Map<String, dynamic>.from(userRows.first as Map);
      final appliedJobsCount = (userData['applied_jobs_count'] ?? 0) as int;
      await client
          .from('users')
          .update({'applied_jobs_count': appliedJobsCount + 1})
          .eq('nic', normalizedNic);
    }
  }

  static Future<Map<String, dynamic>?> getJobDetails(String jobId) async {
    if (!isConfigured) {
      return null;
    }

    final response = await client
        .from('jobs')
        .select()
        .eq('id', jobId)
        .limit(1);
    final rows = response as List<dynamic>;
    if (rows.isEmpty) {
      return null;
    }
    return Map<String, dynamic>.from(rows.first as Map);
  }

  static Future<Map<String, dynamic>?> fetchUserProfile(String nic) async {
    if (!isConfigured) {
      return null;
    }

    final response = await client
        .from('users')
        .select()
        .eq('nic', nic.toUpperCase())
        .limit(1);

    final rows = response as List<dynamic>;
    if (rows.isEmpty) {
      return null;
    }

    return Map<String, dynamic>.from(rows.first as Map);
  }

  static Future<List<Map<String, dynamic>>> fetchUsers({
    int limit = 100,
  }) async {
    if (!isConfigured) {
      return [];
    }

    final response = await client
        .from('users')
        .select()
        .order('rating', ascending: false)
        .limit(limit);

    final rows = response as List<dynamic>;
    return rows.map((row) => Map<String, dynamic>.from(row as Map)).toList();
  }

  static Future<void> saveUserProfile(
    String nic,
    Map<String, dynamic> data,
  ) async {
    if (!isConfigured) {
      throw StateError('Supabase is not configured.');
    }

    final payload = <String, dynamic>{...data, 'nic': nic.toUpperCase()};

    await client.from('users').upsert(payload, onConflict: 'nic');
  }

  static Future<void> addReview(String workerNic, Review review) async {
    if (!isConfigured) {
      throw StateError('Supabase is not configured.');
    }

    await client.from('reviews').insert({
      'reviewer_nic': '',
      'worker_nic': workerNic.toUpperCase(),
      'rating': review.rating,
      'comment': review.comment,
      'created_at': review.date.toIso8601String(),
    });

    final response = await client
        .from('reviews')
        .select('rating')
        .eq('worker_nic', workerNic.toUpperCase());
    final rows = response as List<dynamic>;
    if (rows.isEmpty) {
      return;
    }

    final ratings = rows
        .map(
          (row) =>
              (Map<String, dynamic>.from(row as Map)['rating'] ?? 0).toString(),
        )
        .map(double.tryParse)
        .whereType<double>()
        .toList();
    if (ratings.isEmpty) {
      return;
    }

    final averageRating =
        ratings.reduce((sum, value) => sum + value) / ratings.length;
    await client
        .from('users')
        .update({'rating': averageRating})
        .eq('nic', workerNic.toUpperCase());
  }

  static Job _mapJob(Map<String, dynamic> data) {
    return Job(
      id: (data['id'] ?? '').toString(),
      title: (data['title'] ?? '').toString(),
      description: (data['description'] ?? '').toString(),
      employerId: (data['employer_nic'] ?? data['employer_id'] ?? '')
          .toString(),
      employerName: (data['employer_name'] ?? '').toString(),
      categoryId: (data['category_id'] ?? '').toString(),
      categoryName: (data['category'] ?? '').toString(),
      location: (data['location'] ?? '').toString(),
      status: (data['status'] ?? 'open').toString(),
      appliedWorkerIds: _stringList(data['applied_worker_ids']),
      acceptedWorkerIds: _stringList(data['accepted_worker_ids']),
      requiredSkillIds: _stringList(data['required_skills']),
      payments: _paymentList(data['payments']),
      createdAt: data['created_at'] != null
          ? DateTime.tryParse(data['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  static List<String> _stringList(dynamic value) {
    if (value is List) {
      return value.map((item) => item.toString()).toList();
    }
    return const [];
  }

  static List<JobPayment> _paymentList(dynamic value) {
    if (value is List) {
      return value.map((item) {
        if (item is Map) {
          return JobPayment.fromMap(item);
        }
        return JobPayment(workerId: '', amount: 0, date: DateTime.now());
      }).toList();
    }
    return const [];
  }

  static String _extensionFor(String fileName) {
    final sanitized = fileName.toLowerCase().split('?').first;
    final extension = sanitized.contains('.')
        ? sanitized.split('.').last
        : 'jpg';

    if (extension == 'jpeg' ||
        extension == 'jpg' ||
        extension == 'png' ||
        extension == 'webp') {
      return extension == 'jpeg' ? 'jpg' : extension;
    }

    return 'jpg';
  }

  static String _contentTypeFor(String extension) {
    switch (extension) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }
}
