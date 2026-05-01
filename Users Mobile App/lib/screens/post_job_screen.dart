import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../data/registration_catalog.dart';
import '../models/job.dart';
import '../providers/auth_provider.dart';
import '../providers/job_provider.dart';
import '../providers/alerts_provider.dart';
import '../providers/localization_provider.dart';
import '../services/location_service.dart';

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
    
    if (_selectedCategoryId == null || _selectedDistrictId == null || _selectedDsAreaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(lp.translate('error'))),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final authProvider = context.read<AuthProvider>();
    final jobProvider = context.read<JobProvider>();
    final user = authProvider.currentUser;

    if (user == null) return;

    final category = RegistrationCatalog.jobCategories.firstWhere((c) => c.id == _selectedCategoryId);
    final district = _districts.firstWhere((d) => d.id == _selectedDistrictId);

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

    jobProvider.addJob(newJob);

    // Simulation: Trigger an alert
    final matchScore = jobProvider.getMatchScore(newJob, user);
    if (matchScore >= 75) {
      if (mounted) {
        context.read<AlertsProvider>().addNotification(
          lp.translate('alerts'),
          '${newJob.title}: ${matchScore.toInt()}% ${lp.translate('matchScore')}',
        );
      }
    }

    setState(() {
      _isSubmitting = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(lp.translate('success'))),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final lp = context.watch<LocalizationProvider>();
    
    return Scaffold(
      appBar: AppBar(
        title: Text(lp.translate('postJob')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                lp.translate('jobTab'),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: lp.translate('jobTitle'),
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.work),
                ),
                validator: (value) => value == null || value.isEmpty ? lp.translate('error') : null,
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
                validator: (value) => value == null || value.isEmpty ? lp.translate('error') : null,
              ),
              const SizedBox(height: 24),
              
              Text(
                lp.translate('jobCategory'),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                ),
                hint: Text(lp.translate('selectCategory')),
                value: _selectedCategoryId,
                items: RegistrationCatalog.jobCategories.map((cat) {
                  return DropdownMenuItem(
                    value: cat.id,
                    child: Text('${cat.icon} ${cat.labelFor(lp.currentLocale.languageCode)}'),
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
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: (RegistrationCatalog.skillsByCategory[_selectedCategoryId] ?? []).map((skill) {
                    final isSelected = _selectedSkillIds.contains(skill.id);
                    return FilterChip(
                      label: Text(skill.labelFor(lp.currentLocale.languageCode)),
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
                  }).toList(),
                ),
              ],
              
              const SizedBox(height: 24),
              
              Text(
                lp.translate('location'),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
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
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
