import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/job.dart';
import '../providers/auth_provider.dart';
import '../providers/job_provider.dart';
import '../providers/localization_provider.dart';
import 'candidate_profile_screen.dart';

class JobDetailsScreen extends StatelessWidget {
  final Job job;

  const JobDetailsScreen({super.key, required this.job});

  @override
  Widget build(BuildContext context) {
    return Consumer3<AuthProvider, JobProvider, LocalizationProvider>(
      builder: (context, authProvider, jobProvider, localizationProvider, _) {
        final user = authProvider.currentUser;
        if (user == null) return Scaffold(body: Center(child: Text(localizationProvider.translate('error'))));

        final isEmployer = job.employerId == user.nic;
        final hasApplied = jobProvider.hasApplied(job.id, user.nic);
        final matchScore = jobProvider.getMatchScore(job, user);
        final currentJob = jobProvider.jobs.firstWhere((j) => j.id == job.id, orElse: () => job);

        return Scaffold(
          appBar: AppBar(
            title: Text(isEmployer ? localizationProvider.translate('jobTab') : localizationProvider.translate('publicProfile')),
            actions: [
              if (isEmployer && currentJob.status == 'open')
                PopupMenuButton<String>(
                  onSelected: (val) {
                    if (val == 'cancel') {
                      jobProvider.cancelJob(job.id);
                      Navigator.pop(context);
                    } else if (val == 'complete') {
                      jobProvider.completeJob(job.id);
                      Navigator.pop(context);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'complete', child: Text('Mark as Completed')),
                    const PopupMenuItem(value: 'cancel', child: Text('Cancel Job')),
                  ],
                ),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hero Image / Header
                Hero(
                  tag: 'job_icon_${job.id}',
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: currentJob.status == 'cancelled' ? Colors.red.shade600 : (currentJob.status == 'completed' ? Colors.green.shade600 : Colors.blue.shade600),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(32),
                        bottomRight: Radius.circular(32),
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.work, size: 48, color: currentJob.status == 'cancelled' ? Colors.red : (currentJob.status == 'completed' ? Colors.green : Colors.blue)),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          job.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${currentJob.status.toUpperCase()} - ${job.employerName}',
                          style: const TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Match Score for Workers
                      if (!isEmployer && currentJob.status == 'open') ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: matchScore >= 75 ? Colors.orange.shade50 : Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: matchScore >= 75 ? Colors.orange.shade200 : Colors.blue.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(matchScore >= 75 ? Icons.fireplace : Icons.check_circle, color: matchScore >= 75 ? Colors.orange : Colors.blue),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${matchScore.toInt()}% ${localizationProvider.translate('matchScore')}',
                                      style: TextStyle(fontWeight: FontWeight.bold, color: matchScore >= 75 ? Colors.orange.shade900 : Colors.blue.shade900),
                                    ),
                                    Text(localizationProvider.translate('skills'), style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Details
                      _buildDetailRow(Icons.location_on, localizationProvider.translate('location'), job.location),
                      const SizedBox(height: 16),
                      _buildDetailRow(Icons.category, localizationProvider.translate('jobCategory'), job.categoryName),
                      
                      const SizedBox(height: 32),
                      Text(localizationProvider.translate('jobDescription'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Text(job.description, style: const TextStyle(fontSize: 16, height: 1.5)),

                      const SizedBox(height: 40),

                      // Actions
                      if (isEmployer) ...[
                        const Divider(),
                        const SizedBox(height: 16),
                        Text(
                          '${localizationProvider.translate('viewAppliedWorkers')} (${job.appliedWorkerIds.length})',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        if (job.appliedWorkerIds.isEmpty)
                          const Center(child: Text('No applicants yet.'))
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: job.appliedWorkerIds.length,
                            itemBuilder: (context, index) {
                              final nic = job.appliedWorkerIds[index];
                              final applicant = authProvider.getUser(nic);
                              if (applicant == null) return const SizedBox();
                              return ListTile(
                                leading: const CircleAvatar(child: Icon(Icons.person)),
                                title: Text(applicant.fullName),
                                subtitle: Text(applicant.skillNames.take(2).join(', ')),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CandidateProfileScreen(user: applicant))),
                              );
                            },
                          ),
                      ] else ...[
                        if (currentJob.status == 'open')
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: hasApplied ? null : () {
                                jobProvider.applyToJob(job.id, user.nic);
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(localizationProvider.translate('success'))));
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: hasApplied ? Colors.grey : Colors.blue.shade600,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              child: Text(
                                hasApplied ? localizationProvider.translate('alreadyApplied').toUpperCase() : localizationProvider.translate('applyNow').toUpperCase(),
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 20, color: Colors.blue),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }
}
