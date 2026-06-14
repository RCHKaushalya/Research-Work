import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/localization_provider.dart';
import 'registration_basic_info_screen.dart';

class RegistrationStartScreen extends StatelessWidget {
  const RegistrationStartScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<LocalizationProvider>(
      builder: (context, lp, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text(lp.translate('register')),
            centerTitle: true,
            elevation: 0,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),

                // Steps List
                _stepItem(
                  context,
                  lp,
                  icon: Icons.info_outline,
                  titleKey: 'basicInformation',
                  description: lp.translate('basicInfoDesc'),
                  isRequired: true,
                ),
                const SizedBox(height: 16),
                _stepItem(
                  context,
                  lp,
                  icon: Icons.location_on_outlined,
                  titleKey: 'location',
                  description: lp.translate('locationDesc'),
                  isRequired: true,
                ),
                const SizedBox(height: 16),
                _stepItem(
                  context,
                  lp,
                  icon: Icons.work_outline,
                  titleKey: 'jobCategory',
                  description: lp.translate('jobCategoryDesc'),
                  isRequired: false,
                ),
                const SizedBox(height: 16),
                _stepItem(
                  context,
                  lp,
                  icon: Icons.star_outline,
                  titleKey: 'skills',
                  description: lp.translate('skillsDesc'),
                  isRequired: false,
                ),
                const SizedBox(height: 16),
                _stepItem(
                  context,
                  lp,
                  icon: Icons.image_outlined,
                  titleKey: 'profilePhoto',
                  description: lp.translate('profilePhotoDesc'),
                  isRequired: false,
                ),
                const SizedBox(height: 48),

                // Start Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const RegistrationBasicInfoScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      lp.translate('nextButton'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _stepItem(
    BuildContext context,
    LocalizationProvider lp, {
    required IconData icon,
    required String titleKey,
    required String description,
    required bool isRequired,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, size: 32, color: Colors.blue.shade600),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      lp.translate(titleKey),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (isRequired)
                      const Icon(
                        Icons.check_circle,
                        size: 14,
                        color: Colors.blue,
                      )
                    else
                      const Icon(
                        Icons.circle_outlined,
                        size: 14,
                        color: Colors.grey,
                      ),
                  ],
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
