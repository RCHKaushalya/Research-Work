import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/localization_provider.dart';
import 'edit_profile_screen.dart';
import 'change_pin_screen.dart';
import 'update_area_screen.dart';
import 'update_skills_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  Future<void> _updateProfilePhoto(
    BuildContext context,
    AuthProvider auth,
  ) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Uploading profile photo...')),
        );
      }
      final success = await auth.uploadProfilePhoto(
        bytes: await pickedFile.readAsBytes(),
        fileName: pickedFile.name,
      );
      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile photo updated successfully!')),
        );
      } else if (context.mounted) {
        final updatedUser = auth.currentUser!.copyWith(
          profilePhotoPath: pickedFile.path,
        );
        auth.saveLocalUser(updatedUser);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo preview saved for this session.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lp = context.watch<LocalizationProvider>();
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: Text(lp.translate('settingsTab')),
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
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 20),
        children: [
          // Profile Photo Update
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.blue.shade50,
                  key: ValueKey(user?.profilePhotoPath),
                  backgroundImage: _getImageProvider(user?.profilePhotoPath),
                  child: user?.profilePhotoPath == null
                      ? const Icon(Icons.person, size: 50, color: Colors.blue)
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: CircleAvatar(
                    backgroundColor: Colors.blue,
                    radius: 18,
                    child: IconButton(
                      icon: const Icon(
                        Icons.camera_alt,
                        size: 18,
                        color: Colors.white,
                      ),
                      onPressed: () => _updateProfilePhoto(context, auth),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),

          _buildSectionHeader(lp.translate('basicInformation')),
          _buildSettingsTile(
            context,
            icon: Icons.person_outline,
            title: lp.translate('editBasicInfo'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EditProfileScreen()),
            ),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.location_on_outlined,
            title: lp.translate('location'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const UpdateAreaScreen()),
            ),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.lock_outline,
            title: lp.translate('changePin'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ChangePinScreen()),
            ),
          ),

          const Divider(height: 32),
          _buildSectionHeader(lp.translate('skills')),
          _buildSettingsTile(
            context,
            icon: Icons.star_outline,
            title: lp.translate('updateSkills'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const UpdateSkillsScreen()),
            ),
          ),

          const Divider(height: 32),
          _buildSectionHeader('Support'),
          _buildSettingsTile(
            context,
            icon: Icons.help,
            title: 'FAQ',
            onTap: () {},
          ),
          _buildSettingsTile(
            context,
            icon: Icons.support_agent,
            title: 'Contact Us',
            onTap: () {},
          ),

          const Divider(height: 32),
          _buildSectionHeader('Legal'),
          _buildSettingsTile(
            context,
            icon: Icons.security,
            title: 'Privacy Policy',
            onTap: () {},
          ),
          _buildSettingsTile(
            context,
            icon: Icons.article,
            title: 'Terms of Service',
            onTap: () {},
          ),

          const SizedBox(height: 40),
          Center(
            child: Text(
              'Version 1.0.0',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  ImageProvider? _getImageProvider(String? path) {
    if (path == null) return null;
    if (path.startsWith('http')) return NetworkImage(path);
    if (kIsWeb) return null;
    return FileImage(File(path));
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.blue,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey.shade700),
      title: Text(title, style: const TextStyle(fontSize: 16)),
      trailing: trailing ?? const Icon(Icons.chevron_right, size: 20),
      onTap: onTap,
    );
  }
}
