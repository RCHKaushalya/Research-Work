import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/job.dart';
import '../models/app_user.dart';
import '../providers/auth_provider.dart';
import '../providers/job_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/localization_provider.dart';
import '../services/location_service.dart';
import 'candidate_profile_screen.dart';
import 'review_workers_screen.dart';
import 'chat_screen.dart';

class JobDetailsScreen extends StatelessWidget {
  final Job job;

  const JobDetailsScreen({super.key, required this.job});

  @override
  Widget build(BuildContext context) {
    return Consumer3<AuthProvider, JobProvider, LocalizationProvider>(
      builder: (context, authProvider, jobProvider, localizationProvider, _) {
        final user = authProvider.currentUser;
        if (user == null)
          return Scaffold(
            body: Center(child: Text(localizationProvider.translate('error'))),
          );

        final isEmployer = job.employerId == user.nic;
        final currentJob = jobProvider.jobs.firstWhere(
          (j) => j.id == job.id,
          orElse: () => job,
        );
        final hasApplied = jobProvider.hasApplied(job.id, user.nic);
        final matchScore = jobProvider.getMatchScore(job, user);
        final locationService = LocationService()
          ..updateLocale(localizationProvider.currentLocale.languageCode);
        final locationLabel = locationService.getLocationName(job.location);

        return Scaffold(
          appBar: AppBar(
            title: Text(
              isEmployer
                  ? localizationProvider.translate('jobTab')
                  : localizationProvider.translate('publicProfile'),
            ),
            actions: [
              if (isEmployer &&
                  (currentJob.status == 'open' ||
                      currentJob.status == 'in_progress'))
                PopupMenuButton<String>(
                  onSelected: (val) async {
                    if (val == 'cancel') {
                      jobProvider.cancelJob(job.id);
                      Navigator.pop(context);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'cancel',
                      child: Text(localizationProvider.translate('cancelJob')),
                    ),
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
                      color: currentJob.status == 'cancelled'
                          ? Colors.red.shade600
                          : (currentJob.status == 'completed'
                                ? Colors.green.shade600
                                : (currentJob.status == 'in_progress'
                                      ? Colors.orange.shade600
                                      : Colors.blue.shade600)),
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
                          child: Icon(
                            Icons.work,
                            size: 48,
                            color: currentJob.status == 'cancelled'
                                ? Colors.red
                                : (currentJob.status == 'completed'
                                      ? Colors.green
                                      : Colors.blue),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          job.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${currentJob.status.toUpperCase()} - ${job.employerName}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                        if (isEmployer) ...[
                          const SizedBox(height: 24),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            alignment: WrapAlignment.center,
                            children: [
                              if (currentJob.status == 'open' &&
                                  currentJob.acceptedWorkerIds.isNotEmpty)
                                ElevatedButton.icon(
                                  onPressed: () => jobProvider.startJob(job.id),
                                  icon: const Icon(Icons.play_arrow),
                                  label: Text(
                                    localizationProvider
                                        .translate('markInProgress')
                                        .toUpperCase(),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: Colors.orange.shade700,
                                  ),
                                ),
                              if (currentJob.status == 'in_progress' ||
                                  (currentJob.status == 'open' &&
                                      currentJob.acceptedWorkerIds.isNotEmpty))
                                ElevatedButton.icon(
                                  onPressed: () async {
                                    final workers = await authProvider.getUsers(
                                      currentJob.acceptedWorkerIds,
                                    );
                                    if (context.mounted) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => ReviewWorkersScreen(
                                            job: currentJob,
                                            workers: workers,
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.check),
                                  label: Text(
                                    localizationProvider
                                        .translate('markCompleted')
                                        .toUpperCase(),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: Colors.green.shade700,
                                  ),
                                ),
                              if (currentJob.acceptedWorkerIds.isNotEmpty)
                                ElevatedButton.icon(
                                  onPressed: () async {
                                    final chatProvider = context
                                        .read<ChatProvider>();
                                    final chatId = await chatProvider
                                        .getOrCreateGroupChat(currentJob.id, [
                                          user.nic,
                                          ...currentJob.acceptedWorkerIds,
                                        ], currentJob.title);
                                    if (context.mounted) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => ChatScreen(
                                            chatId: chatId,
                                            title:
                                                '${currentJob.title} (Group)',
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.group),
                                  label: Text(
                                    localizationProvider
                                        .translate('openGroupChat')
                                        .toUpperCase(),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue.shade900,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                            ],
                          ),
                        ] else if (currentJob.acceptedWorkerIds.contains(
                          user.nic,
                        )) ...[
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton.icon(
                                onPressed: () async {
                                  final chatProvider = context
                                      .read<ChatProvider>();
                                  final chatId = await chatProvider
                                      .getOrCreateDirectChat(
                                        user.nic,
                                        currentJob.employerId,
                                      );
                                  if (context.mounted) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ChatScreen(
                                          chatId: chatId,
                                          title:
                                              '${localizationProvider.translate('messageTab')} - Employer',
                                        ),
                                      ),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.message),
                                label: Text(
                                  localizationProvider
                                      .translate('messageWorker')
                                      .toUpperCase(),
                                ), // Using messageWorker key for consistency
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.blue.shade700,
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton.icon(
                                onPressed: () async {
                                  final chatProvider = context
                                      .read<ChatProvider>();
                                  final chatId = await chatProvider
                                      .getOrCreateGroupChat(currentJob.id, [
                                        currentJob.employerId,
                                        ...currentJob.acceptedWorkerIds,
                                      ], currentJob.title);
                                  if (context.mounted) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ChatScreen(
                                          chatId: chatId,
                                          title: '${currentJob.title} (Group)',
                                        ),
                                      ),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.group),
                                label: Text(
                                  localizationProvider
                                      .translate('openGroupChat')
                                      .toUpperCase(),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue.shade900,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ],
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
                            color: matchScore >= 75
                                ? Colors.orange.shade50
                                : Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: matchScore >= 75
                                  ? Colors.orange.shade200
                                  : Colors.blue.shade200,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                matchScore >= 75
                                    ? Icons.fireplace
                                    : Icons.check_circle,
                                color: matchScore >= 75
                                    ? Colors.orange
                                    : Colors.blue,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${matchScore.toInt()}% ${localizationProvider.translate('matchScore')}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: matchScore >= 75
                                            ? Colors.orange.shade900
                                            : Colors.blue.shade900,
                                      ),
                                    ),
                                    Text(
                                      localizationProvider.translate('skills'),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Details
                      _buildDetailRow(
                        Icons.location_on,
                        localizationProvider.translate('location'),
                        locationLabel,
                      ),
                      const SizedBox(height: 16),
                      _buildDetailRow(
                        Icons.category,
                        localizationProvider.translate('jobCategory'),
                        job.categoryName,
                      ),

                      const SizedBox(height: 32),
                      Text(
                        job.description,
                        style: const TextStyle(fontSize: 16, height: 1.5),
                      ),

                      const SizedBox(height: 32),
                      Text(
                        localizationProvider.translate('salaryLog'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (currentJob.payments.isEmpty)
                        Text(
                          localizationProvider.translate('noJobsFound'),
                          style: const TextStyle(color: Colors.grey),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: currentJob.payments.length,
                          itemBuilder: (context, index) {
                            final payment = currentJob.payments[index];
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(
                                Icons.payment,
                                color: Colors.green,
                              ),
                              title: Text(
                                'Rs. ${payment.amount}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                '${payment.date.day}/${payment.date.month} - ${payment.note ?? ""}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              trailing: FutureBuilder<AppUser?>(
                                future: authProvider
                                    .getUsers([payment.workerId])
                                    .then(
                                      (list) =>
                                          list.isNotEmpty ? list.first : null,
                                    ),
                                builder: (context, snap) => Text(
                                  snap.data?.firstName ??
                                      localizationProvider.translate(
                                        'workerStats',
                                      ),
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            );
                          },
                        ),

                      const SizedBox(height: 40),

                      // Actions
                      if (isEmployer) ...[
                        const Divider(),
                        const SizedBox(height: 16),
                        Text(
                          '${localizationProvider.translate('viewAppliedWorkers')} (${job.appliedWorkerIds.length})',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (job.appliedWorkerIds.isEmpty &&
                            job.acceptedWorkerIds.isEmpty)
                          Center(
                            child: Text(
                              localizationProvider.translate('noJobsFound'),
                            ),
                          )
                        else
                          FutureBuilder<List<AppUser>>(
                            future: authProvider.getUsers([
                              ...job.appliedWorkerIds,
                              ...job.acceptedWorkerIds,
                            ]),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }
                              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                return Center(
                                  child: Text(
                                    localizationProvider.translate('error'),
                                  ),
                                );
                              }

                              final applicants = snapshot.data!;
                              return ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: applicants.length,
                                itemBuilder: (context, index) {
                                  final applicant = applicants[index];
                                  final isAccepted = currentJob
                                      .acceptedWorkerIds
                                      .contains(applicant.nic);

                                  return Card(
                                    margin: const EdgeInsets.symmetric(
                                      vertical: 4,
                                    ),
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundImage: _imageProvider(
                                          applicant.profilePhotoPath,
                                        ),
                                        child:
                                            _imageProvider(
                                                  applicant.profilePhotoPath,
                                                ) ==
                                                null
                                            ? const Icon(Icons.person)
                                            : null,
                                      ),
                                      title: Text(
                                        applicant.fullName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      subtitle: Row(
                                        children: [
                                          const Icon(
                                            Icons.star,
                                            color: Colors.orange,
                                            size: 14,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${applicant.rating} (${applicant.reviews.length})',
                                            style: const TextStyle(
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              applicant.skillNames
                                                  .take(2)
                                                  .join(', '),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      trailing: isAccepted
                                          ? Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Chip(
                                                  label: Text(
                                                    localizationProvider
                                                        .translate('accepted'),
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 10,
                                                    ),
                                                  ),
                                                  backgroundColor: Colors.green,
                                                ),
                                                if (currentJob.status ==
                                                        'open' ||
                                                    currentJob.status ==
                                                        'in_progress') ...[
                                                  IconButton(
                                                    icon: const Icon(
                                                      Icons.message,
                                                      color: Colors.blue,
                                                      size: 20,
                                                    ),
                                                    tooltip:
                                                        localizationProvider
                                                            .translate(
                                                              'messageWorker',
                                                            ),
                                                    onPressed: () async {
                                                      final chatProvider =
                                                          context
                                                              .read<
                                                                ChatProvider
                                                              >();
                                                      final chatId =
                                                          await chatProvider
                                                              .getOrCreateDirectChat(
                                                                user.nic,
                                                                applicant.nic,
                                                              );
                                                      if (context.mounted) {
                                                        Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder: (_) =>
                                                                ChatScreen(
                                                                  chatId:
                                                                      chatId,
                                                                  title:
                                                                      '${localizationProvider.translate('messageTab')} - ${applicant.firstName}',
                                                                ),
                                                          ),
                                                        );
                                                      }
                                                    },
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(
                                                      Icons.payments,
                                                      color: Colors.green,
                                                      size: 20,
                                                    ),
                                                    tooltip:
                                                        localizationProvider
                                                            .translate(
                                                              'logPayment',
                                                            ),
                                                    onPressed: () =>
                                                        _showPaymentDialog(
                                                          context,
                                                          jobProvider,
                                                          currentJob.id,
                                                          applicant,
                                                        ),
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(
                                                      Icons.person_remove,
                                                      color: Colors.red,
                                                      size: 20,
                                                    ),
                                                    tooltip:
                                                        localizationProvider
                                                            .translate(
                                                              'removeWorker',
                                                            ),
                                                    onPressed: () {
                                                      jobProvider.removeWorker(
                                                        currentJob.id,
                                                        applicant.nic,
                                                      );
                                                      ScaffoldMessenger.of(
                                                        context,
                                                      ).showSnackBar(
                                                        SnackBar(
                                                          content: Text(
                                                            '${localizationProvider.translate('removed')} ${applicant.firstName}',
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                ],
                                              ],
                                            )
                                          : Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.check_circle,
                                                    color: Colors.green,
                                                  ),
                                                  onPressed: () {
                                                    jobProvider.acceptWorker(
                                                      currentJob.id,
                                                      applicant.nic,
                                                    );
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                          '${localizationProvider.translate('accepted')} ${applicant.firstName}',
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                ),
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.cancel,
                                                    color: Colors.red,
                                                  ),
                                                  onPressed: () {
                                                    jobProvider.rejectWorker(
                                                      currentJob.id,
                                                      applicant.nic,
                                                    );
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                          '${localizationProvider.translate('cancel')} ${applicant.firstName}',
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ],
                                            ),
                                      onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              CandidateProfileScreen(
                                                user: applicant,
                                              ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                      ] else ...[
                        if (currentJob.status == 'open')
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: hasApplied
                                  ? null
                                  : () {
                                      jobProvider.applyToJob(job.id, user.nic);
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            localizationProvider.translate(
                                              'success',
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: hasApplied
                                    ? Colors.grey
                                    : Colors.blue.shade600,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Text(
                                hasApplied
                                    ? localizationProvider
                                          .translate('alreadyApplied')
                                          .toUpperCase()
                                    : localizationProvider
                                          .translate('applyNow')
                                          .toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
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

  ImageProvider? _imageProvider(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http')) return NetworkImage(path);
    if (kIsWeb) return null;
    final file = File(path);
    return file.existsSync() ? FileImage(file) : null;
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: Colors.blue),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            Text(
              value,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }

  void _showPaymentDialog(
    BuildContext context,
    JobProvider jobProvider,
    String jobId,
    AppUser worker,
  ) {
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    final lp = context.read<LocalizationProvider>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${lp.translate('logPayment')} - ${worker.firstName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              decoration: InputDecoration(labelText: lp.translate('amount')),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: noteController,
              decoration: InputDecoration(labelText: lp.translate('note')),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(lp.translate('cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(amountController.text) ?? 0;
              if (amount > 0) {
                jobProvider.addPayment(
                  jobId,
                  JobPayment(
                    workerId: worker.nic,
                    amount: amount,
                    date: DateTime.now(),
                    note: noteController.text.isNotEmpty
                        ? noteController.text
                        : null,
                  ),
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(lp.translate('success'))),
                );
              }
            },
            child: Text(lp.translate('logPayment')),
          ),
        ],
      ),
    );
  }
}
