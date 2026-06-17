import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../data/registration_catalog.dart';
import '../models/job.dart';
import '../providers/auth_provider.dart';
import '../providers/job_provider.dart';
import '../providers/localization_provider.dart';
import '../services/location_service.dart';
import '../services/sms_gateway_service.dart';
import '../services/supabase_service.dart';

class PostJobScreen extends StatefulWidget {
  const PostJobScreen({super.key});

  @override
  State<PostJobScreen> createState() => _PostJobScreenState();
}

class _PostJobScreenState extends State<PostJobScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  String? _selectedCategoryId;
  Set<String> _selectedSkillIds = {};
  String? _selectedDistrictId;
  String? _selectedDsAreaId;

  late final LocationService _locationService;
  List<LocationData> _districts = [];
  List<LocationData> _dsAreas = [];

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _locationService = LocationService();
    _loadLocationData();
  }

  void _loadLocationData() {
    _districts = _locationService.getDistricts();
    setState(() {});
  }

  void _onDistrictChanged(String? districtId) {
    setState(() {
      _selectedDistrictId = districtId;
      _selectedDsAreaId = null;
      if (districtId != null) {
        _dsAreas = _locationService.getDSAreas(districtId);
      } else {
        _dsAreas = [];
      }
    });
  }

  Future<void> _submitJob() async {
    final lp = context.read<LocalizationProvider>();
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCategoryId == null ||
        _selectedDistrictId == null ||
        _selectedDsAreaId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(lp.translate('error'))));
      return;
    }

    setState(() => _isSubmitting = true);

    final authProvider = context.read<AuthProvider>();
    final jobProvider = context.read<JobProvider>();
    final user = authProvider.currentUser;
    if (user == null) {
      setState(() => _isSubmitting = false);
      return;
    }

    final category = RegistrationCatalog.jobCategories.firstWhere(
      (c) => c.id == _selectedCategoryId,
    );
    final district = _districts.firstWhere((d) => d.id == _selectedDistrictId);
    final dsArea = _dsAreas.isNotEmpty
        ? _dsAreas.firstWhere(
            (a) => a.id == _selectedDsAreaId,
            orElse: () => _dsAreas.first,
          )
        : null;

    final newJob = Job(
      id: const Uuid().v4(),
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      employerId: user.nic,
      employerName: user.fullName,
      categoryId: category.id,
      categoryName: category.labelFor(lp.currentLocale.languageCode),
      location: district.name,
      requiredSkillIds: _selectedSkillIds.toList(),
      createdAt: DateTime.now(),
    );

    try {
      // 1. Save job to Supabase and get the persisted row (with real UUID)
      final createdJob = await jobProvider.addJob(newJob);

      if (createdJob != null && mounted) {
        // 2. Notify matching workers in the area via the SMS Gateway API.
        final notifiedCount = await _notifyMatchingWorkers(
          job: createdJob,
          district: district.name,
          dsArea: dsArea?.name ?? '',
        );

        final message = notifiedCount > 0
            ? '${lp.translate('success')} — $notifiedCount workers notified via SMS.'
            : lp.translate('success');

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      } else if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(lp.translate('success'))));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${lp.translate('error')}: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }

    if (mounted) Navigator.pop(context);
  }

  /// Queries workers matching [district] / [dsArea] / skill overlap,
  /// then sends an SMS notification via the SMS Gateway API for each.
  /// Returns the number of workers successfully notified.
  Future<int> _notifyMatchingWorkers({
    required Job job,
    required String district,
    required String dsArea,
  }) async {
    final jobPrefix = job.id.length >= 4 ? job.id.substring(0, 4) : job.id;

    List<Map<String, dynamic>> matchingWorkers;
    try {
      matchingWorkers = await SupabaseService.fetchMatchingWorkers(
        district: district,
        dsArea: dsArea,
        skillIds: job.requiredSkillIds,
      );
    } catch (_) {
      return 0;
    }

    // Exclude the employer themselves
    matchingWorkers = matchingWorkers
        .where((w) => w['nic'] != job.employerId)
        .toList();

    int notifiedCount = 0;
    final smsMessage =
        'New Job: "${job.title}" in $district. '
        'Reply "$jobPrefix 1" to apply. (SMS users only)';

    for (final worker in matchingWorkers) {
      final phone = (worker['phone'] ?? '').toString();
      if (phone.isEmpty) continue;

      try {
        final sent = await SmsGatewayService.sendSms(
          phoneNumber: phone,
          message: smsMessage,
        );
        if (sent) notifiedCount++;
      } catch (_) {
        // Non-fatal: continue notifying remaining workers
      }
    }

    return notifiedCount;
  }

  @override
  Widget build(BuildContext context) {
    final lp = context.watch<LocalizationProvider>();

    return Scaffold(
      appBar: AppBar(title: Text(lp.translate('postJob'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                lp.translate('jobTab'),
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: lp.translate('jobTitle'),
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.work),
                ),
                validator: (value) => value == null || value.isEmpty
                    ? lp.translate('error')
                    : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _descController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: lp.translate('jobDescription'),
                  border: const OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                validator: (value) => value == null || value.isEmpty
                    ? lp.translate('error')
                    : null,
              ),
              const SizedBox(height: 24),

              Text(
                lp.translate('jobCategory'),
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 16,
                  ),
                ),
                hint: Text(lp.translate('selectCategory')),
                value: _selectedCategoryId,
                items: RegistrationCatalog.jobCategories.map((cat) {
                  return DropdownMenuItem(
                    value: cat.id,
                    child: Text(
                      '${cat.icon} ${cat.labelFor(lp.currentLocale.languageCode)}',
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedCategoryId = val;
                    _selectedSkillIds.clear();
                  });
                },
              ),

              if (_selectedCategoryId != null) ...[
                const SizedBox(height: 24),
                Text(
                  lp.translate('skills'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      (RegistrationCatalog
                                  .skillsByCategory[_selectedCategoryId] ??
                              [])
                          .map((skill) {
                            final isSelected = _selectedSkillIds.contains(
                              skill.id,
                            );
                            return FilterChip(
                              label: Text(
                                skill.labelFor(lp.currentLocale.languageCode),
                              ),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    _selectedSkillIds.add(skill.id);
                                  } else {
                                    _selectedSkillIds.remove(skill.id);
                                  }
                                });
                              },
                            );
                          })
                          .toList(),
                ),
              ],

              const SizedBox(height: 24),

              Text(
                lp.translate('location'),
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: lp.translate('district'),
                ),
                value: _selectedDistrictId,
                items: _districts.map((d) {
                  return DropdownMenuItem(value: d.id, child: Text(d.name));
                }).toList(),
                onChanged: _onDistrictChanged,
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: lp.translate('dsArea'),
                ),
                value: _selectedDsAreaId,
                items: _dsAreas.map((a) {
                  return DropdownMenuItem(value: a.id, child: Text(a.name));
                }).toList(),
                onChanged: (val) => setState(() => _selectedDsAreaId = val),
              ),

              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitJob,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          lp.translate('postJobButton'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
