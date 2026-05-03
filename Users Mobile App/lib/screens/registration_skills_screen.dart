import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/registration_catalog.dart';
import '../models/app_user.dart';
import '../providers/auth_provider.dart';
import '../providers/localization_provider.dart';
import 'registration_photo_screen.dart';

class RegistrationSkillsScreen extends StatefulWidget {
  final AppUser user;

  const RegistrationSkillsScreen({super.key, required this.user});

  @override
  State<RegistrationSkillsScreen> createState() =>
      _RegistrationSkillsScreenState();
}

class _RegistrationSkillsScreenState extends State<RegistrationSkillsScreen> {
  final List<String> _selectedIds = [];
  bool _submitting = false;

  Future<void> _submit() async {
    final authProvider = context.read<AuthProvider>();
    final lp = context.read<LocalizationProvider>();

    setState(() => _submitting = true);

    final selectedNames =
        RegistrationCatalog.skillsForCategories(widget.user.jobCategoryIds)
            .where((skill) => _selectedIds.contains(skill.id))
            .map((skill) => skill.labelFor(lp.currentLocale.languageCode))
            .toList();

    final updatedUser = widget.user.copyWith(
      skillIds: _selectedIds,
      skillNames: selectedNames,
    );

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RegistrationPhotoScreen(user: updatedUser),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LocalizationProvider>(
      builder: (context, lp, _) {
        final availableSkills = RegistrationCatalog.skillsForCategories(
          widget.user.jobCategoryIds,
        );

        return Scaffold(
          appBar: AppBar(
            title: Text(lp.translate('skills')),
            actions: [
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        RegistrationPhotoScreen(user: widget.user),
                  ),
                ),
                child: Text(
                  lp.translate('skip'),
                  style: const TextStyle(color: Colors.blue),
                ),
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lp.translate('skills'),
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Pick the skills that match your work',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: availableSkills.isEmpty
                      ? Center(
                          child: Text(
                            'Select job categories first',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        )
                      : SingleChildScrollView(
                          child: Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: availableSkills.map((skill) {
                              final isSelected = _selectedIds.contains(
                                skill.id,
                              );
                              return FilterChip(
                                selected: isSelected,
                                avatar: Text(skill.icon),
                                label: Text(
                                  skill.labelFor(lp.currentLocale.languageCode),
                                ),
                                onSelected: (selected) {
                                  setState(() {
                                    if (selected) {
                                      _selectedIds.add(skill.id);
                                    } else {
                                      _selectedIds.remove(skill.id);
                                    }
                                  });
                                },
                              );
                            }).toList(),
                          ),
                        ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _selectedIds.isEmpty ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _submitting
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(lp.translate('nextButton')),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
