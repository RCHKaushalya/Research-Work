import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../data/registration_catalog.dart';
import '../providers/auth_provider.dart';
import '../providers/localization_provider.dart';
import '../providers/job_provider.dart';
import 'landing_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  Future<void> _addPortfolioPhoto(
    BuildContext context,
    AuthProvider auth,
  ) async {
    final lp = context.read<LocalizationProvider>();
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    final uploaded = await auth.uploadPortfolioPhoto(
      bytes: await pickedFile.readAsBytes(),
      fileName: pickedFile.name,
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            uploaded ? lp.translate('success') : lp.translate('error'),
          ),
        ),
      );
    }
  }

  Future<void> _updateProfilePhoto(
    BuildContext context,
    AuthProvider auth,
  ) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final uploaded = await auth.uploadProfilePhoto(
        bytes: await pickedFile.readAsBytes(),
        fileName: pickedFile.name,
      );
      if (!uploaded && auth.currentUser != null) {
        auth.saveLocalUser(
          auth.currentUser!.copyWith(profilePhotoPath: pickedFile.path),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<AuthProvider, LocalizationProvider, JobProvider>(
      builder: (context, authProvider, lp, jobProvider, _) {
        final user = authProvider.currentUser;
        if (user == null)
          return const Center(child: CircularProgressIndicator());

        final appliedJobs = jobProvider.getAppliedJobs(user.nic);
        final postedJobs = jobProvider.getPostedJobs(user.nic);
        return Scaffold(
          appBar: AppBar(
            title: Text(lp.translate('profileTab')),
            actions: [
              PopupMenuButton<String>(
                onSelected: lp.setLanguage,
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'si', child: Text('සිංහල')),
                  PopupMenuItem(value: 'ta', child: Text('தமிழ்')),
                  PopupMenuItem(value: 'en', child: Text('English')),
                ],
                icon: const Icon(Icons.language, color: Colors.blue),
              ),
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.red),
                onPressed: () async {
                  await authProvider.logout();
                  if (context.mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LandingScreen()),
                      (route) => false,
                    );
                  }
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Header
                Center(
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: () => _updateProfilePhoto(context, authProvider),
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.blue.shade50,
                          key: ValueKey(user.profilePhotoPath),
                          backgroundImage: _getImageProvider(
                            user.profilePhotoPath,
                          ),
                          child: user.profilePhotoPath == null
                              ? const Icon(
                                  Icons.camera_alt,
                                  size: 50,
                                  color: Colors.blue,
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        user.fullName,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star,
                            color: Colors.orange,
                            size: 20,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            user.rating.toString(),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            ' (${user.reviews.length} ${lp.translate('reviews')})',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // Stats Row
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatTile(
                        lp.translate('completedJobs'),
                        user.completedJobsCount.toString(),
                        Colors.green,
                      ),
                      _buildStatTile(
                        lp.translate('appliedJobs'),
                        appliedJobs.length.toString(),
                        Colors.blue,
                      ),
                      _buildStatTile(
                        lp.translate('postedJobs'),
                        postedJobs.length.toString(),
                        Colors.orange,
                      ),
                      _buildStatTile(
                        lp.translate('abandoned'),
                        user.abandonedJobsCount.toString(),
                        Colors.red,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // Portfolio Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      lp.translate('publicProfile'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_a_photo, color: Colors.blue),
                      onPressed: () =>
                          _addPortfolioPhoto(context, authProvider),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                user.portfolioPhotos.isEmpty
                    ? Container(
                        height: 100,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Icon(Icons.photo_library, color: Colors.grey),
                        ),
                      )
                    : SizedBox(
                        height: 120,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: user.portfolioPhotos.length,
                          itemBuilder: (context, index) {
                            final path = user.portfolioPhotos[index];
                            return Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image(
                                  image: _getImageProvider(path)!,
                                  width: 120,
                                  height: 120,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                        color: Colors.grey,
                                        child: const Icon(Icons.error),
                                      ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                const SizedBox(height: 30),

                // Skills Tiles
                Text(
                  lp.translate('skills'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: user.skillIds.length,
                  itemBuilder: (context, index) {
                    final id = user.skillIds[index];
                    final option = RegistrationCatalog.getOptionById(id);
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade100),
                      ),
                      child: Row(
                        children: [
                          Text(
                            option?.icon ?? '⭐',
                            style: const TextStyle(fontSize: 20),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              option?.labelFor(lp.currentLocale.languageCode) ??
                                  id,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 30),

                // Reviews Section
                Text(
                  lp.translate('reviews'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                if (user.reviews.isEmpty)
                  Text(
                    lp.translate('noReviews'),
                    style: const TextStyle(color: Colors.grey),
                  )
                else
                  ...user.reviews.map((r) => _buildReviewTile(r)),
              ],
            ),
          ),
        );
      },
    );
  }

  ImageProvider? _getImageProvider(String? path) {
    if (path == null) return null;
    if (path.startsWith('http')) return NetworkImage(path);
    if (kIsWeb) return null;
    return FileImage(File(path));
  }

  Widget _buildStatTile(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  Widget _buildReviewTile(dynamic review) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        title: Text(
          review.authorName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(review.comment),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star, color: Colors.orange, size: 16),
            Text(review.rating.toString()),
          ],
        ),
      ),
    );
  }
}
