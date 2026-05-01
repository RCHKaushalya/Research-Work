import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_user.dart';
import '../providers/auth_provider.dart';
import '../providers/localization_provider.dart';
import 'registration_skills_screen.dart';

class RegistrationJobCategoryScreen extends StatefulWidget {
  final AppUser user;

  const RegistrationJobCategoryScreen({super.key, required this.user});

  @override
  State<RegistrationJobCategoryScreen> createState() =>
      _RegistrationJobCategoryScreenState();
}

class _RegistrationJobCategoryScreenState
    extends State<RegistrationJobCategoryScreen> {
  final List<Map<String, dynamic>> _categories = [
    {'id': 'C01', 'name': 'ඉදිකිරීම්', 'icon': Icons.construction},
    {'id': 'C02', 'name': 'ප්‍රවාහන', 'icon': Icons.local_shipping},
    {'id': 'C03', 'name': 'කෘෂිකර්ම', 'icon': Icons.agriculture},
    {'id': 'C04', 'name': 'පිරිසිදු කිරීම්', 'icon': Icons.cleaning_services},
    {'id': 'C05', 'name': 'තාක්ෂණික', 'icon': Icons.electrical_services},
  ];

  final List<String> _selectedIds = [];
  bool _submitting = false;

  Future<void> _submit() async {
    final authProvider = context.read<AuthProvider>();
    final lp = context.read<LocalizationProvider>();

    setState(() => _submitting = true);

    final selectedNames = _categories
        .where((c) => _selectedIds.contains(c['id']))
        .map((c) => c['name'] as String)
        .toList();

    final updatedUser = widget.user.copyWith(
      jobCategoryIds: _selectedIds,
      jobCategoryNames: selectedNames,
    );

    await authProvider.saveUser(updatedUser);

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RegistrationSkillsScreen(user: updatedUser),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LocalizationProvider>(
      builder: (context, lp, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text(lp.translate('jobCategory')),
            actions: [
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => RegistrationSkillsScreen(user: widget.user)),
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
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final cat = _categories[index];
                      final isSelected = _selectedIds.contains(cat['id']);
                      return InkWell(
                        onTap: () {
                          setState(() {
                            isSelected ? _selectedIds.remove(cat['id']) : _selectedIds.add(cat['id']);
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.blue.shade100 : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: isSelected ? Colors.blue : Colors.transparent),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(cat['icon'], size: 40, color: isSelected ? Colors.blue : Colors.grey),
                              const SizedBox(height: 12),
                              Text(cat['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
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
