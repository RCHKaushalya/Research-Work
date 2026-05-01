import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_user.dart';
import '../providers/auth_provider.dart';
import '../providers/localization_provider.dart';
import 'registration_photo_screen.dart';

class RegistrationSkillsScreen extends StatefulWidget {
  final AppUser user;

  const RegistrationSkillsScreen({super.key, required this.user});

  @override
  State<RegistrationSkillsScreen> createState() => _RegistrationSkillsScreenState();
}

class _RegistrationSkillsScreenState extends State<RegistrationSkillsScreen> {
  final Map<String, List<Map<String, String>>> _allSkills = {
    'C01': [{'id': 'S01', 'name': 'මේසන්'}, {'id': 'S02', 'name': 'වඩු වැඩ'}],
    'C02': [{'id': 'S03', 'name': 'පැදවීම'}, {'id': 'S04', 'name': 'බෙදාහැරීම'}],
    'C03': [{'id': 'S05', 'name': 'වගාව'}, {'id': 'S06', 'name': 'අස්වනු නෙලීම'}],
    'C04': [{'id': 'S07', 'name': 'නිවාස පිරිසිදු කිරීම'}, {'id': 'S08', 'name': 'කාර්යාල පිරිසිදු කිරීම'}],
    'C05': [{'id': 'S09', 'name': 'විදුලි වැඩ'}, {'id': 'S10', 'name': 'නල වැඩ'}],
  };

  final List<String> _selectedIds = [];
  bool _submitting = false;

  Future<void> _submit() async {
    final authProvider = context.read<AuthProvider>();
    final lp = context.read<LocalizationProvider>();

    setState(() => _submitting = true);

    List<String> selectedNames = [];
    for (var catId in widget.user.jobCategoryIds) {
      final catSkills = _allSkills[catId] ?? [];
      for (var skill in catSkills) {
        if (_selectedIds.contains(skill['id'])) {
          selectedNames.add(skill['name']!);
        }
      }
    }

    final updatedUser = widget.user.copyWith(
      skillIds: _selectedIds,
      skillNames: selectedNames,
    );

    await authProvider.saveUser(updatedUser);

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => RegistrationPhotoScreen(user: updatedUser)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LocalizationProvider>(
      builder: (context, lp, _) {
        final List<Map<String, String>> availableSkills = [];
        for (var catId in widget.user.jobCategoryIds) {
          availableSkills.addAll(_allSkills[catId] ?? []);
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(lp.translate('skills')),
            actions: [
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => RegistrationPhotoScreen(user: widget.user)),
                ),
                child: Text(lp.translate('skip'), style: const TextStyle(color: Colors.blue)),
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: availableSkills.length,
                    itemBuilder: (context, index) {
                      final skill = availableSkills[index];
                      final isSelected = _selectedIds.contains(skill['id']);
                      return CheckboxListTile(
                        value: isSelected,
                        title: Text(skill['name']!),
                        onChanged: (val) {
                          setState(() {
                            val! ? _selectedIds.add(skill['id']!) : _selectedIds.remove(skill['id']);
                          });
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _selectedIds.isEmpty ? null : _submit,
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
