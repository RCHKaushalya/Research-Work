import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/registration_catalog.dart';
import '../providers/auth_provider.dart';
import '../providers/localization_provider.dart';

class UpdateSkillsScreen extends StatefulWidget {
  const UpdateSkillsScreen({Key? key}) : super(key: key);

  @override
  State<UpdateSkillsScreen> createState() => _UpdateSkillsScreenState();
}

class _UpdateSkillsScreenState extends State<UpdateSkillsScreen> {
  final List<String> _selectedCategoryIds = [];
  final List<String> _selectedSkillIds = [];

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser;
    if (user != null) {
      _selectedCategoryIds.addAll(user.jobCategoryIds);
      _selectedSkillIds.addAll(user.skillIds);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lp = context.watch<LocalizationProvider>();
    final auth = context.watch<AuthProvider>();
    final lang = lp.currentLocale.languageCode;

    return Scaffold(
      appBar: AppBar(title: Text(lp.translate('updateSkills'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(lp.translate('jobCategory'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 2.5,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: RegistrationCatalog.jobCategories.length,
              itemBuilder: (context, index) {
                final cat = RegistrationCatalog.jobCategories[index];
                final isSelected = _selectedCategoryIds.contains(cat.id);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) _selectedCategoryIds.remove(cat.id);
                      else _selectedCategoryIds.add(cat.id);
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blue.shade100 : Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isSelected ? Colors.blue : Colors.blue.shade100),
                    ),
                    child: Row(
                      children: [
                        Text(cat.icon, style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            cat.labelFor(lang),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            
            const SizedBox(height: 32),
            Text(lp.translate('skills'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 16),
            
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 2.5,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: RegistrationCatalog.skillsForCategories(_selectedCategoryIds).length,
              itemBuilder: (context, index) {
                final skill = RegistrationCatalog.skillsForCategories(_selectedCategoryIds)[index];
                final isSelected = _selectedSkillIds.contains(skill.id);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) _selectedSkillIds.remove(skill.id);
                      else _selectedSkillIds.add(skill.id);
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.orange.shade100 : Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isSelected ? Colors.orange : Colors.orange.shade100),
                    ),
                    child: Row(
                      children: [
                        Text(skill.icon, style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            skill.labelFor(lang),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () async {
                  final catNames = RegistrationCatalog.jobCategories.where((c) => _selectedCategoryIds.contains(c.id)).map((c) => c.labelFor(lang)).toList();
                  final skillNames = RegistrationCatalog.skillsForCategories(_selectedCategoryIds).where((s) => _selectedSkillIds.contains(s.id)).map((s) => s.labelFor(lang)).toList();
                  
                  final updated = auth.currentUser!.copyWith(
                    jobCategoryIds: _selectedCategoryIds,
                    jobCategoryNames: catNames,
                    skillIds: _selectedSkillIds,
                    skillNames: skillNames,
                  );
                  await auth.saveUser(updated);
                  if (mounted) Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(lp.translate('save'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
