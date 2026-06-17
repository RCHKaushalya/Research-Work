import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/localization_provider.dart';
import '../services/location_service.dart';

class UpdateAreaScreen extends StatefulWidget {
  const UpdateAreaScreen({Key? key}) : super(key: key);

  @override
  State<UpdateAreaScreen> createState() => _UpdateAreaScreenState();
}

class _UpdateAreaScreenState extends State<UpdateAreaScreen> {
  final _locationService = LocationService();
  String? _selectedDistrictId;
  String? _selectedDsAreaId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    await _locationService.init();
    final user = context.read<AuthProvider>().currentUser;
    setState(() {
      _selectedDistrictId = user?.districtId;
      _selectedDsAreaId = user?.dsAreaId;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final lp = context.watch<LocalizationProvider>();
    final auth = context.watch<AuthProvider>();
    _locationService.updateLocale(lp.currentLocale.languageCode);

    return Scaffold(
      appBar: AppBar(title: Text(lp.translate('location'))),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    value: _selectedDistrictId,
                    items: _locationService
                        .getDistricts()
                        .map(
                          (d) => DropdownMenuItem(
                            value: d.id,
                            child: Text(d.name),
                          ),
                        )
                        .toList(),
                    onChanged: (val) => setState(() {
                      _selectedDistrictId = val;
                      _selectedDsAreaId = null;
                    }),
                    decoration: InputDecoration(
                      labelText: lp.translate('district'),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (_selectedDistrictId != null)
                    DropdownButtonFormField<String>(
                      value: _selectedDsAreaId,
                      items: _locationService
                          .getDSAreas(_selectedDistrictId!)
                          .map(
                            (a) => DropdownMenuItem(
                              value: a.id,
                              child: Text(a.name),
                            ),
                          )
                          .toList(),
                      onChanged: (val) =>
                          setState(() => _selectedDsAreaId = val),
                      decoration: InputDecoration(
                        labelText: lp.translate('dsArea'),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (_selectedDistrictId != null &&
                            _selectedDsAreaId != null) {
                          final dist = _locationService
                              .getDistricts()
                              .firstWhere((d) => d.id == _selectedDistrictId);
                          final area = _locationService
                              .getDSAreas(_selectedDistrictId!)
                              .firstWhere((a) => a.id == _selectedDsAreaId);
                          final updated = auth.currentUser!.copyWith(
                            districtId: dist.id,
                            districtName: dist.name,
                            dsAreaId: area.id,
                            dsAreaName: area.name,
                          );
                          await auth.saveUser(updated);
                          if (mounted) Navigator.pop(context);
                        }
                      },
                      child: Text(lp.translate('save')),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
