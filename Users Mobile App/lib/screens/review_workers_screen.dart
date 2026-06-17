import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/job.dart';
import '../models/app_user.dart';
import '../providers/auth_provider.dart';
import '../providers/job_provider.dart';
import '../providers/localization_provider.dart';

class ReviewWorkersScreen extends StatefulWidget {
  final Job job;
  final List<AppUser> workers;

  const ReviewWorkersScreen({
    super.key,
    required this.job,
    required this.workers,
  });

  @override
  State<ReviewWorkersScreen> createState() => _ReviewWorkersScreenState();
}

class _ReviewWorkersScreenState extends State<ReviewWorkersScreen> {
  final Map<String, double> _ratings = {};
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    for (var worker in widget.workers) {
      _ratings[worker.nic] = 5.0;
      _controllers[worker.nic] = TextEditingController();
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lp = context.read<LocalizationProvider>();

    return Scaffold(
      appBar: AppBar(title: Text(lp.translate('giveReview'))),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: widget.workers.length,
        itemBuilder: (context, index) {
          final worker = widget.workers[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundImage: _imageProvider(
                          worker.profilePhotoPath,
                        ),
                        child: _imageProvider(worker.profilePhotoPath) == null
                            ? const Icon(Icons.person)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        worker.fullName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text('${lp.translate('rank')}:'),
                  Row(
                    children: List.generate(5, (starIndex) {
                      return IconButton(
                        icon: Icon(
                          starIndex < _ratings[worker.nic]!
                              ? Icons.star
                              : Icons.star_border,
                          color: Colors.orange,
                        ),
                        onPressed: () {
                          setState(() {
                            _ratings[worker.nic] = starIndex + 1.0;
                          });
                        },
                      );
                    }),
                  ),
                  TextField(
                    controller: _controllers[worker.nic],
                    decoration: InputDecoration(
                      hintText:
                          '${lp.translate('note')} (${lp.translate('skip').toLowerCase()})',
                      border: const OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          onPressed: () async {
            final auth = context.read<AuthProvider>();
            final jobProvider = context.read<JobProvider>();

            for (var worker in widget.workers) {
              await auth.addReview(
                worker.nic,
                Review(
                  authorName: auth.currentUser?.fullName ?? 'Employer',
                  comment: _controllers[worker.nic]!.text,
                  rating: _ratings[worker.nic]!,
                  date: DateTime.now(),
                ),
              );
            }

            await jobProvider.completeJob(widget.job.id);
            if (mounted) {
              Navigator.pop(context);
              Navigator.pop(context); // Go back to profile
            }
          },
          child: Text(
            lp.translate('finish').toUpperCase(),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  ImageProvider? _imageProvider(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http')) return NetworkImage(path);
    if (kIsWeb) return null;
    final file = File(path);
    return file.existsSync() ? FileImage(file) : null;
  }
}
