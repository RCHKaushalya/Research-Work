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
                // Header Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade600, Colors.blue.shade800],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.person_add, size: 48, color: Colors.white),
                      const SizedBox(height: 12),
                      Text(
                        lp.translate('basicInformation'),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '1 / 5',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Description
                Text(
                  lp.translate('register'),
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 32),

                // Steps List
                _stepItem(
                  context,
                  lp,
                  icon: Icons.info_outline,
                  titleKey: 'basicInformation',
                  description: 'NIC, PIN, ...',
                  isRequired: true,
                ),
                const SizedBox(height: 16),
                _stepItem(
                  context,
                  lp,
                  icon: Icons.location_on_outlined,
                  titleKey: 'location',
                  description: '...',
                  isRequired: true,
                ),
                const SizedBox(height: 16),
                _stepItem(
                  context,
                  lp,
                  icon: Icons.work_outline,
                  titleKey: 'jobCategory',
                  description: '...',
                  isRequired: false,
                ),
                const SizedBox(height: 16),
                _stepItem(
                  context,
                  lp,
                  icon: Icons.star_outline,
                  titleKey: 'skills',
                  description: '...',
                  isRequired: false,
                ),
                const SizedBox(height: 16),
                _stepItem(
                  context,
                  lp,
                  icon: Icons.image_outlined,
                  titleKey: 'profilePhoto',
                  description: '...',
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
                      const Icon(Icons.check_circle, size: 14, color: Colors.blue)
                    else
                      const Icon(Icons.circle_outlined, size: 14, color: Colors.grey),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
