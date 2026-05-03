import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_user.dart';
import '../providers/auth_provider.dart';
import '../providers/localization_provider.dart';
import '../services/location_service.dart';
import 'registration_job_category_screen.dart';

class RegistrationLocationScreen extends StatefulWidget {
  final AppUser user;

  const RegistrationLocationScreen({super.key, required this.user});

  @override
  State<RegistrationLocationScreen> createState() =>
      _RegistrationLocationScreenState();
}

class _RegistrationLocationScreenState
    extends State<RegistrationLocationScreen> {
  final _locationService = LocationService();
  late Future<void> _initFuture;

  String? _selectedDistrictId;
  String? _selectedDSAreaId;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _initFuture = _locationService.init();
  }

  Future<void> _submit() async {
    final lp = context.read<LocalizationProvider>();
    if (_selectedDistrictId == null || _selectedDSAreaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(lp.translate('error'))),
      );
      return;
    }

    setState(() {
      _submitting = true;
    });

    try {
      final districts = _locationService.getDistricts();
      final dsAreas = _locationService.getDSAreas(_selectedDistrictId!);

      final selectedDistrict = districts.firstWhere(
        (d) => d.id == _selectedDistrictId,
        orElse: () => districts.first,
      );
      final selectedDSArea = dsAreas.firstWhere(
        (d) => d.id == _selectedDSAreaId,
        orElse: () => dsAreas.first,
      );

      final updatedUser = widget.user.copyWith(
        districtId: selectedDistrict.id,
        districtName: selectedDistrict.name,
        dsAreaId: selectedDSArea.id,
        dsAreaName: selectedDSArea.name,
      );

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                RegistrationJobCategoryScreen(user: updatedUser),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LocalizationProvider>(
      builder: (context, lp, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text(lp.translate('location')),
          ),
          body: FutureBuilder<void>(
            future: _initFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final districts = _locationService.getDistricts();
              final dsAreas = _selectedDistrictId != null
                  ? _locationService.getDSAreas(_selectedDistrictId!)
                  : <LocationData>[];

              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lp.translate('district'),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedDistrictId,
                      items: districts
                          .map<DropdownMenuItem<String>>(
                            (district) => DropdownMenuItem<String>(
                              value: district.id,
                              child: Text(district.name),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedDistrictId = value;
                          _selectedDSAreaId = null;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: lp.translate('selectDistrict'),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (_selectedDistrictId != null) ...[
                      Text(
                        lp.translate('dsArea'),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedDSAreaId,
                        items: dsAreas
                            .map<DropdownMenuItem<String>>(
                              (area) => DropdownMenuItem<String>(
                                value: area.id,
                                child: Text(area.name),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedDSAreaId = value;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: lp.translate('selectDsArea'),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ],
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _submitting ? null : _submit,
                        child: _submitting
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text(lp.translate('nextButton')),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
