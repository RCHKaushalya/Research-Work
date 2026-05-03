import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_user.dart';
import '../providers/auth_provider.dart';
import '../providers/localization_provider.dart';
import 'registration_location_screen.dart';

class RegistrationBasicInfoScreen extends StatefulWidget {
  const RegistrationBasicInfoScreen({Key? key}) : super(key: key);

  @override
  State<RegistrationBasicInfoScreen> createState() =>
      _RegistrationBasicInfoScreenState();
}

class _RegistrationBasicInfoScreenState
    extends State<RegistrationBasicInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _nicController = TextEditingController();
  final _phoneController = TextEditingController();
  final _pinController = TextEditingController();

  bool _obscurePin = true;
  bool _submitting = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _nicController.dispose();
    _phoneController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _submitting = true;
    });

    final lp = context.read<LocalizationProvider>();
    final user = AppUser(
      nic: _nicController.text.trim().toUpperCase(),
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      phone: _phoneController.text.trim(),
      pin: _pinController.text.trim(),
    );

    setState(() {
      _submitting = false;
    });

    // Navigate to location screen
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RegistrationLocationScreen(user: user),
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
            title: Text(
              lp.translate('basicInformation'),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _firstNameController,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: lp.translate('firstName'),
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return lp.translate('firstName');
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _lastNameController,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: lp.translate('lastName'),
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return lp.translate('lastName');
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nicController,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: lp.translate('nic'),
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      final normalized = (value ?? '').trim();
                      if (normalized.isEmpty) {
                        return lp.translate('nic');
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneController,
                    textInputAction: TextInputAction.next,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: lp.translate('phoneNumber'),
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      final normalized = (value ?? '').trim();
                      if (normalized.isEmpty) {
                        return lp.translate('phoneNumber');
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _pinController,
                    obscureText: _obscurePin,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: lp.translate('pin'),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _obscurePin = !_obscurePin;
                          });
                        },
                        icon: Icon(
                          _obscurePin ? Icons.visibility : Icons.visibility_off,
                        ),
                      ),
                    ),
                    validator: (value) {
                      final normalized = (value ?? '').trim();
                      if (normalized.isEmpty) {
                        return lp.translate('pin');
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _submitting ? null : _submit,
                      child: _submitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              lp.translate('nextButton'),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
