import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/job.dart';
import '../models/app_user.dart';
import '../services/api_service.dart';

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
    
    try {
      final response = await ApiService.get('/jobs');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _jobs = data.map((j) => _mapBackendJobToJob(j)).toList();
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<Job> getSuitableJobsForCategories(AppUser? user) {
    if (user == null) return _jobs;
    final userCategoryIds = user.jobCategoryIds;
    
    List<Job> filtered;
    if (userCategoryIds.isEmpty) {
      filtered = _jobs.where((j) => j.status == 'open').toList();
    } else {
      filtered = _jobs.where((job) => userCategoryIds.contains(job.categoryId) && job.status == 'open').toList();
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
    final response = await ApiService.post('/jobs/$jobId/apply', {});
    if (response.statusCode == 200) {
      final jobIndex = _jobs.indexWhere((j) => j.id == jobId);
      if (jobIndex != -1) {
        final job = _jobs[jobIndex];
        final updatedAppliedIds = List<String>.from(job.appliedWorkerIds)..add(userId);
        _jobs[jobIndex] = job.copyWith(appliedWorkerIds: updatedAppliedIds);
        notifyListeners();
      }
    }
  }

  Future<void> cancelJob(String jobId) async {
    final response = await ApiService.put('/jobs/$jobId/status', {'status': 'cancelled'});
    if (response.statusCode == 200) {
      final jobIndex = _jobs.indexWhere((j) => j.id == jobId);
      if (jobIndex != -1) {
        _jobs[jobIndex] = _jobs[jobIndex].copyWith(status: 'cancelled');
        notifyListeners();
      }
    }
  }

  Future<void> completeJob(String jobId) async {
    final response = await ApiService.put('/jobs/$jobId/status', {'status': 'completed'});
    if (response.statusCode == 200) {
      final jobIndex = _jobs.indexWhere((j) => j.id == jobId);
      if (jobIndex != -1) {
        _jobs[jobIndex] = _jobs[jobIndex].copyWith(status: 'completed');
        notifyListeners();
      }
    }
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
    final response = await ApiService.post('/jobs', {
      'title': job.title,
      'description': job.description,
      'area': job.location,
      'skill_ids_needed': job.requiredSkillIds,
    });
    
    if (response.statusCode == 200) {
      final newJob = _mapBackendJobToJob(jsonDecode(response.body));
      _jobs.insert(0, newJob);
      notifyListeners();
    }
  }

  Job _mapBackendJobToJob(Map<String, dynamic> data) {
    return Job(
      id: data['id'],
      title: data['title'],
      description: data['description'],
      employerId: data['employer_id'],
      employerName: 'User ${data['employer_id'].toString().substring(0, 4)}', // In real app, fetch name or include in API
      categoryId: '', // Backend should ideally return category_id
      categoryName: '',
      location: data['area'],
      status: data['status'],
      appliedWorkerIds: List<String>.from(data['applied_worker_ids'] ?? []), // Backend needs to return this or fetch apps
      requiredSkillIds: List<String>.from(data['skill_ids_needed'] ?? []),
      createdAt: DateTime.parse(data['created_at']),
    );
  }
}
