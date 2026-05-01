import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/registration_catalog.dart';
import '../models/app_user.dart';
import '../providers/localization_provider.dart';

class CandidateProfileScreen extends StatelessWidget {
  final AppUser user;

  const CandidateProfileScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final lp = context.watch<LocalizationProvider>();
    final lang = lp.currentLocale.languageCode;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(lp.translate('candidateProfile')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Header: Photo and Name
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.blue.shade50,
                    backgroundImage: (user.profilePhotoPath != null && File(user.profilePhotoPath!).existsSync()) 
                        ? FileImage(File(user.profilePhotoPath!)) 
                        : null,
                    child: (user.profilePhotoPath == null || !File(user.profilePhotoPath!).existsSync()) 
                        ? const Icon(Icons.person, size: 50, color: Colors.blue) 
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(user.fullName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, color: Colors.orange, size: 20),
                      const SizedBox(width: 4),
                      Text(user.rating.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(' (${user.reviews.length} ${lp.translate('reviews')})', style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Stats Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStat(lp.translate('completedJobs'), user.completedJobsCount.toString()),
                _buildStat(lp.translate('rank'), 'Level 2'),
                _buildStat(lp.translate('reviews'), user.reviews.length.toString()),
              ],
            ),
            
            const SizedBox(height: 32),

            // Portfolio Section
            if (user.portfolioPhotos.isNotEmpty) ...[
              _buildSection(context, lp.translate('publicProfile'), [
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: user.portfolioPhotos.length,
                    itemBuilder: (context, index) {
                      final path = user.portfolioPhotos[index];
                      if (!File(path).existsSync()) return const SizedBox();
                      return Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(File(path), width: 100, height: 100, fit: BoxFit.cover),
                        ),
                      );
                    },
                  ),
                ),
              ]),
              const SizedBox(height: 24),
            ],
            
            // Details List
            _buildSection(context, lp.translate('basicInformation'), [
              _buildInfoTile(Icons.phone, lp.translate('phoneNumber'), user.phone),
              _buildInfoTile(Icons.location_on, lp.translate('location'), '${user.dsAreaName}, ${user.districtName}'),
            ]),
            
            const SizedBox(height: 24),
            
            _buildSection(context, lp.translate('jobCategory'), [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: user.skillIds.map((id) {
                  final option = RegistrationCatalog.getOptionById(id);
                  return Chip(
                    avatar: Text(option?.icon ?? '⭐'),
                    label: Text(option?.labelFor(lang) ?? id),
                    backgroundColor: Colors.blue.shade50,
                  );
                }).toList(),
              ),
            ]),
            
            const SizedBox(height: 40),
            
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(lp.translate('messageWorker'))),
                  );
                },
                icon: const Icon(Icons.call),
                label: Text(lp.translate('contactCandidate')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blue.shade700),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }
}
