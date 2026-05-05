import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/job.dart';
import '../models/app_user.dart';
import '../services/firebase_service.dart';

class JobProvider extends ChangeNotifier {
  List<Job> _jobs = [];
  bool _isLoading = false;

  List<Job> get jobs => _jobs;
  bool get isLoading => _isLoading;

  JobProvider() {
    fetchJobs();
  }

  void fetchJobs() {
    _isLoading = true;
    notifyListeners();
    
    // Listen to all jobs for now (in a real app, you'd paginate or filter)
    FirebaseService.db.collection('jobs').snapshots().listen((snapshot) {
      _jobs = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return _mapBackendJobToJob(data);
      }).toList();
      
      _isLoading = false;
      notifyListeners();
    }, onError: (e) {
      _isLoading = false;
      notifyListeners();
    });
  }

  List<Job> getSuitableJobsForCategories(AppUser? user) {
    if (user == null) return _jobs;
    final userCategoryIds = user.jobCategoryIds;
    
    List<Job> filtered;
    if (userCategoryIds.isEmpty) {
      filtered = _jobs.where((j) => j.status == 'open').toList();
    } else {
      // In the real app, we use area/skills
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
    await FirebaseService.applyForJob(jobId, userId);
    // Realtime listener will automatically update the job list
  }

  Future<void> cancelJob(String jobId) async {
    await FirebaseService.db.collection('jobs').doc(jobId).update({'status': 'cancelled'});
  }

  Future<void> completeJob(String jobId) async {
    await FirebaseService.db.collection('jobs').doc(jobId).update({'status': 'completed'});
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
    final docRef = FirebaseService.db.collection('jobs').doc();
    await docRef.set({
      'title': job.title,
      'description': job.description,
      'area': job.location,
      'skill_ids_needed': job.requiredSkillIds,
      'employer_id': job.employerId,
      'status': 'open',
      'applied_worker_ids': [],
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  Job _mapBackendJobToJob(Map<String, dynamic> data) {
    return Job(
      id: data['id'],
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      employerId: data['employer_id'] ?? '',
      employerName: 'User ${(data['employer_id'] ?? '').toString().length >= 4 ? data['employer_id'].toString().substring(0, 4) : ''}', 
      categoryId: '', 
      categoryName: '',
      location: data['area'] ?? '',
      status: data['status'] ?? 'open',
      appliedWorkerIds: List<String>.from(data['applied_worker_ids'] ?? []), 
      requiredSkillIds: List<String>.from(data['skill_ids_needed'] ?? []),
      createdAt: data['created_at'] != null 
          ? (data['created_at'] is Timestamp ? (data['created_at'] as Timestamp).toDate() : DateTime.now()) 
          : DateTime.now(),
    );
  }
}
