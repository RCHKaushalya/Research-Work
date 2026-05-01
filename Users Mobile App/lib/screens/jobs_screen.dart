import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/job_provider.dart';
import '../providers/localization_provider.dart';
import '../widgets/job_card.dart';
import 'job_details_screen.dart';

class JobsScreen extends StatelessWidget {
  const JobsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final lp = context.watch<LocalizationProvider>();
    final authProvider = context.watch<AuthProvider>();
    final jobProvider = context.watch<JobProvider>();
    final user = authProvider.currentUser;

    if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final appliedJobs = jobProvider.getAppliedJobs(user.nic);
    final postedJobs = jobProvider.getPostedJobs(user.nic);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(lp.translate('jobTab')),
          bottom: TabBar(
            labelColor: Colors.blue.shade700,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.blue.shade700,
            tabs: [
              Tab(text: lp.translate('appliedJobs')),
              Tab(text: lp.translate('postedJobs')),
            ],
          ),
        ),
        body: Column(
          children: [
            // Worker Stats Header
            _buildStatsHeader(lp, user),
            
            Expanded(
              child: TabBarView(
                children: [
                  // Applied Jobs Tab
                  appliedJobs.isEmpty
                      ? _buildEmptyState(lp, 'appliedJobs')
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: appliedJobs.length,
                          itemBuilder: (context, index) {
                            final job = appliedJobs[index];
                            final matchScore = jobProvider.getMatchScore(job, user);
                            return JobCard(
                              job: job,
                              hasApplied: true,
                              isOwnJob: false,
                              matchScore: matchScore,
                              onApply: () {},
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => JobDetailsScreen(job: job),
                                  ),
                                );
                              },
                            );
                          },
                        ),

                  // My Posted Jobs Tab
                  postedJobs.isEmpty
                      ? _buildEmptyState(lp, 'postedJobs')
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: postedJobs.length,
                          itemBuilder: (context, index) {
                            final job = postedJobs[index];
                            return JobCard(
                              job: job,
                              hasApplied: false,
                              isOwnJob: true,
                              onApply: () {},
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => JobDetailsScreen(job: job),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsHeader(LocalizationProvider lp, dynamic user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        border: Border(bottom: BorderSide(color: Colors.blue.shade100)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            lp.translate('workerStats'),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(lp.translate('completedJobs'), user.completedJobsCount.toString(), Colors.green),
              _buildStatItem(lp.translate('appliedJobs'), user.jobCategoryIds.length.toString(), Colors.blue), // Using categories as a proxy for 'applied/potential'
              _buildStatItem(lp.translate('postedJobs'), '0', Colors.orange), // To be tracked
              _buildStatItem('Abandoned', user.abandonedJobsCount.toString(), Colors.red),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
        ),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
        ),
      ],
    );
  }

  Widget _buildEmptyState(LocalizationProvider lp, String key) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.work_off_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            lp.translate('noJobsFound'),
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}
