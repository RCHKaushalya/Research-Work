import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/registration_catalog.dart';
import '../models/app_user.dart';
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
  final List<String> _selectedIds = [];
  bool _submitting = false;

  Future<void> _submit() async {
    final lp = context.read<LocalizationProvider>();

    setState(() => _submitting = true);

    final selectedNames = RegistrationCatalog.jobCategories
        .where((c) => _selectedIds.contains(c.id))
        .map((c) => c.labelFor(lp.currentLocale.languageCode))
        .toList();

    final updatedUser = widget.user.copyWith(
      jobCategoryIds: _selectedIds,
      jobCategoryNames: selectedNames,
    );

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
                  MaterialPageRoute(
                    builder: (context) =>
                        RegistrationSkillsScreen(user: widget.user),
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
                  lp.translate('jobCategory'),
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  lp.translate('selectJobCategory'),
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                          childAspectRatio: 1.05,
                        ),
                    itemCount: RegistrationCatalog.jobCategories.length,
                    itemBuilder: (context, index) {
                      final cat = RegistrationCatalog.jobCategories[index];
                      final isSelected = _selectedIds.contains(cat.id);
                      return InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedIds.remove(cat.id);
                            } else {
                              _selectedIds.add(cat.id);
                            }
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          decoration: BoxDecoration(
                            gradient: isSelected
                                ? LinearGradient(
                                    colors: [
                                      Colors.blue.shade600,
                                      Colors.blue.shade400,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : LinearGradient(
                                    colors: [Colors.white, Colors.blue.shade50],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.blue.shade700
                                  : Colors.blue.shade100,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    cat.icon,
                                    style: const TextStyle(fontSize: 30),
                                  ),
                                  Icon(
                                    isSelected
                                        ? Icons.check_circle
                                        : Icons.radio_button_unchecked,
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.blueGrey,
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    cat.labelFor(lp.currentLocale.languageCode),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${RegistrationCatalog.skillsByCategory[cat.id]?.length ?? 0} ${lp.translate('skills')}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isSelected
                                          ? Colors.white.withOpacity(0.85)
                                          : Colors.blueGrey,
                                    ),
                                  ),
                                ],
                              ),
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
