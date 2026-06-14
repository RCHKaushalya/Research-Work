import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../models/job.dart';
import '../services/supabase_service.dart';

class JobProvider extends ChangeNotifier {
  List<Job> _jobs = [];
  bool _isLoading = false;

  List<Job> get jobs => _jobs;
  bool get isLoading => _isLoading;

  JobProvider() {
    fetchJobs();
  }

  Future<void> fetchJobs() async {
    _isLoading = true;
    notifyListeners();

    if (!SupabaseService.isConfigured) {
      _jobs = [];
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      _jobs = await SupabaseService.fetchJobs();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Supabase job fetch error: $e');
      }
      _jobs = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  List<Job> getSuitableJobsForCategories(AppUser? user) {
    if (user == null) return _jobs;
    final userCategoryIds = user.jobCategoryIds;

    List<Job> filtered;
    if (userCategoryIds.isEmpty) {
      filtered = _jobs.where((j) => j.status == 'open').toList();
    } else {
      filtered = _jobs.where((job) => job.status == 'open').toList();
    }

    filtered.sort((a, b) {
      final scoreA = getMatchScore(a, user);
      final scoreB = getMatchScore(b, user);
      return scoreB.compareTo(scoreA);
    });

    return filtered;
  }

  double getMatchScore(Job job, AppUser user) {
    if (job.requiredSkillIds.isEmpty) return 100.0;
    int matchCount = 0;
    for (final skillId in job.requiredSkillIds) {
      if (user.skillIds.contains(skillId)) matchCount++;
    }
    return (matchCount / job.requiredSkillIds.length) * 100;
  }

  Future<void> applyToJob(String jobId, String userId) async {
    if (!SupabaseService.isConfigured) {
      return;
    }

    await SupabaseService.applyForJob(jobId, userId);
    await fetchJobs();
  }

  Future<void> startJob(String jobId) async {
    await _updateJob(jobId, {'status': 'in_progress'});
  }

  Future<void> cancelJob(String jobId) async {
    await _updateJob(jobId, {'status': 'cancelled'});
  }

  Future<void> completeJob(String jobId) async {
    await _updateJob(jobId, {'status': 'completed'});
  }

  Future<void> acceptWorker(String jobId, String workerId) async {
    final job = await SupabaseService.getJobDetails(jobId);
    if (job == null) {
      return;
    }

    final acceptedWorkerIds = List<String>.from(
      job['accepted_worker_ids'] ?? [],
    );
    final appliedWorkerIds = List<String>.from(job['applied_worker_ids'] ?? []);
    if (!acceptedWorkerIds.contains(workerId)) {
      acceptedWorkerIds.add(workerId);
    }
    appliedWorkerIds.remove(workerId);

    await _updateJob(jobId, {
      'accepted_worker_ids': acceptedWorkerIds,
      'applied_worker_ids': appliedWorkerIds,
    });
  }

  Future<void> removeWorker(String jobId, String workerId) async {
    final job = await SupabaseService.getJobDetails(jobId);
    if (job == null) {
      return;
    }

    final acceptedWorkerIds = List<String>.from(
      job['accepted_worker_ids'] ?? [],
    );
    acceptedWorkerIds.remove(workerId);

    await _updateJob(jobId, {'accepted_worker_ids': acceptedWorkerIds});
  }

  Future<void> rejectWorker(String jobId, String workerId) async {
    final job = await SupabaseService.getJobDetails(jobId);
    if (job == null) {
      return;
    }

    final appliedWorkerIds = List<String>.from(job['applied_worker_ids'] ?? []);
    appliedWorkerIds.remove(workerId);

    await _updateJob(jobId, {'applied_worker_ids': appliedWorkerIds});
  }

  bool hasApplied(String jobId, String userId) {
    final jobIndex = _jobs.indexWhere((j) => j.id == jobId);
    if (jobIndex == -1) return false;
    return _jobs[jobIndex].appliedWorkerIds.contains(userId);
  }

  List<Job> getAppliedJobs(String userId) {
    return _jobs.where((job) => job.appliedWorkerIds.contains(userId)).toList();
  }

  List<Job> getPostedJobs(String userId) {
    return _jobs.where((job) => job.employerId == userId).toList();
  }

  Future<void> addJob(Job job) async {
    if (!SupabaseService.isConfigured) {
      return;
    }

    await SupabaseService.createJob(job);
    await fetchJobs();
  }

  Future<void> addPayment(String jobId, JobPayment payment) async {
    if (!SupabaseService.isConfigured) {
      return;
    }

    final job = await SupabaseService.getJobDetails(jobId);
    if (job == null) {
      return;
    }

    final payments = <Map<String, dynamic>>[
      ...List<Map<String, dynamic>>.from(
        (job['payments'] as List? ?? []).map(
          (paymentData) => Map<String, dynamic>.from(paymentData as Map),
        ),
      ),
      payment.toMap(),
    ];

    await _updateJob(jobId, {'payments': payments});
  }

  Future<void> _updateJob(String jobId, Map<String, dynamic> changes) async {
    if (!SupabaseService.isConfigured) {
      return;
    }

    await SupabaseService.client.from('jobs').update(changes).eq('id', jobId);
    await fetchJobs();
  }
}
