import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/app_user.dart';
import '../providers/auth_provider.dart';
import '../providers/localization_provider.dart';
import 'main_layout_screen.dart';

class RegistrationPhotoScreen extends StatefulWidget {
  final AppUser user;

  const RegistrationPhotoScreen({super.key, required this.user});

  @override
  State<RegistrationPhotoScreen> createState() =>
      _RegistrationPhotoScreenState();
}

class _RegistrationPhotoScreenState extends State<RegistrationPhotoScreen> {
  XFile? _image;
  final _picker = ImagePicker();
  bool _submitting = false;

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _image = pickedFile);
    }
  }

  Future<void> _submit() async {
    final authProvider = context.read<AuthProvider>();
    setState(() => _submitting = true);

    try {
      final result = await authProvider.completeRegistration(widget.user);

      if (result.isSuccess) {
        if (_image != null) {
          // Try to upload photo to server
          final uploadSuccess = await authProvider.uploadProfilePhoto(
            _image!.path,
          );

          // If server upload fails, save the local path as fallback
          if (!uploadSuccess && authProvider.currentUser != null) {
            final userWithPhoto = authProvider.currentUser!.copyWith(
              profilePhotoPath: _image!.path,
            );
            await authProvider.saveUser(userWithPhoto);
          }
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Registration completed successfully!'),
            ),
          );
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const MainLayoutScreen()),
            (route) => false,
          );
        }
      } else {
        if (mounted) {
          setState(() => _submitting = false);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(result.message)));
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LocalizationProvider>(
      builder: (context, lp, _) {
        return Scaffold(
          appBar: AppBar(title: Text(lp.translate('profilePhoto'))),
          body: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const SizedBox(height: 40),
                Center(
                  child: InkWell(
                    onTap: _pickImage,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.blue.shade200,
                          width: 2,
                        ),
                      ),
                      child: _image != null
                          ? ClipOval(
                              child: kIsWeb
                                  ? Image.network(
                                      _image!.path,
                                      fit: BoxFit.cover,
                                    )
                                  : Image.file(
                                      io.File(_image!.path),
                                      fit: BoxFit.cover,
                                    ),
                            )
                          : Icon(
                              Icons.add_a_photo,
                              size: 60,
                              color: Colors.blue.shade300,
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  lp.translate('uploadPhoto'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _submitting ? null : _submit,
                    child: _submitting
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(lp.translate('finish')),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _submit,
                  child: Text(lp.translate('skip')),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
