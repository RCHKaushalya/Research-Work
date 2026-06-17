import 'package:flutter/material.dart';
import '../models/job.dart';
import '../providers/localization_provider.dart';
import '../services/location_service.dart';
import 'package:provider/provider.dart';

class JobCard extends StatelessWidget {
  final Job job;
  final bool hasApplied;
  final bool isOwnJob;
  final double? matchScore;
  final VoidCallback onApply;
  final VoidCallback onTap;

  const JobCard({
    Key? key,
    required this.job,
    required this.hasApplied,
    this.isOwnJob = false,
    this.matchScore,
    required this.onApply,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final lp = context.watch<LocalizationProvider>();
    final locationService = LocationService()
      ..updateLocale(lp.currentLocale.languageCode);
    final locationLabel = locationService.getLocationName(job.location);
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Hero(
                    tag: 'job_icon_${job.id}',
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.work,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          job.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          job.employerName,
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (matchScore != null && !isOwnJob)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: matchScore! >= 75 ? Colors.orange.shade100 : Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            matchScore! >= 75 ? Icons.fireplace : Icons.check_circle_outline,
                            size: 14,
                            color: matchScore! >= 75 ? Colors.orange.shade900 : Colors.blue.shade700,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${matchScore!.toInt()}% ${lp.translate('match')}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: matchScore! >= 75 ? Colors.orange.shade900 : Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    locationLabel,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.category, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      job.categoryName,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                job.description,
                style: const TextStyle(fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _getTimeAgo(job.createdAt, lp),
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
                  if (!isOwnJob)
                    SizedBox(
                      height: 36,
                      child: ElevatedButton(
                        onPressed: hasApplied ? null : onApply,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: hasApplied ? Colors.grey.shade300 : Colors.blue.shade600,
                          foregroundColor: hasApplied ? Colors.grey.shade700 : Colors.white,
                          elevation: hasApplied ? 0 : 2,
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: Text(hasApplied ? lp.translate('applied') : lp.translate('apply')),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        lp.translate('yourPost'),
                        style: TextStyle(
                          color: Colors.amber.shade900,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime, LocalizationProvider lp) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inDays > 0) {
      return '${difference.inDays} ${lp.translate('daysAgo')}';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${lp.translate('hoursAgo')}';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${lp.translate('minutesAgo')}';
    } else {
      return lp.translate('justNow');
    }
  }
}
