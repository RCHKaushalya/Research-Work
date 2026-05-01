import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/job_provider.dart';
import '../providers/localization_provider.dart';
import '../widgets/job_card.dart';
import 'job_details_screen.dart';
import 'post_job_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final lp = context.watch<LocalizationProvider>();
    final authProvider = context.watch<AuthProvider>();
    final jobProvider = context.watch<JobProvider>();
    final user = authProvider.currentUser;

    if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final suitableJobs = jobProvider.getSuitableJobsForCategories(user);
    final isSinhala = lp.currentLocale.languageCode == 'si';

    return Scaffold(
      appBar: AppBar(
        title: Text(lp.translate('dashboard')),
        actions: [
          IconButton(
            icon: Icon(isSinhala ? Icons.translate : Icons.language, color: Colors.blue),
            onPressed: () => lp.setLanguage(isSinhala ? 'ta' : 'si'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => Future.delayed(const Duration(seconds: 1)),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Text
              Text(
                '${lp.translate('welcome')}, ${user.firstName}!',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                lp.translate('suitableJobs'),
                style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
              ),
              
              const SizedBox(height: 24),

              // Jobs List
              if (suitableJobs.isEmpty)
                Center(
                  child: Column(
                    children: [
                      const SizedBox(height: 40),
                      Icon(Icons.work_outline, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text(lp.translate('noJobsFound'), style: TextStyle(color: Colors.grey.shade500)),
                    ],
                  ),
                )
              else
                ...suitableJobs.map((job) {
                  final matchScore = jobProvider.getMatchScore(job, user);
                  final hasApplied = jobProvider.hasApplied(job.id, user.nic);
                  
                  return JobCard(
                    job: job,
                    hasApplied: hasApplied,
                    isOwnJob: job.employerId == user.nic,
                    matchScore: matchScore,
                    onApply: () {
                      jobProvider.applyToJob(job.id, user.nic);
                    },
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => JobDetailsScreen(job: job)),
                      );
                    },
                  );
                }),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PostJobScreen())),
        label: Text(lp.translate('postJob')),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
      ),
    );
  }
}
