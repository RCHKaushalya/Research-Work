import '../data/local_location_data.dart';
import 'package:flutter/material.dart';

class LocationData {
  final String id;
  final String name; // Holds localized name based on locale, or JSON string. For simplicity we will adapt it below.
  final Map<String, dynamic> rawName;

  LocationData({required this.id, required this.name, required this.rawName});

  factory LocationData.fromJson(Map<String, dynamic> json, String locale) {
    final nameObj = json['name'] as Map<String, dynamic>? ?? {};
    final String localizedName = nameObj[locale] ?? nameObj['si'] ?? '';
    return LocationData(
      id: json['id'] as String? ?? '',
      name: localizedName,
      rawName: nameObj,
    );
  }
}

class LocationService {
  static final LocationService _instance = LocationService._internal();

  bool _initialized = false;
  String _currentLocale = 'si';

  LocationService._internal();

  factory LocationService() {
    return _instance;
  }

  Future<void> init() async {
    _initialized = true;
  }
  
  void updateLocale(String locale) {
    _currentLocale = locale;
  }

  List<LocationData> getDistricts() {
    return LocalLocationData.districtsList
        .map((item) => LocationData.fromJson(item, _currentLocale))
        .toList();
  }

  List<LocationData> getDSAreas(String districtId) {
    final areas = LocalLocationData.dsAreas[districtId] ?? [];
    return areas
        .map((item) => LocationData.fromJson(item, _currentLocale))
        .toList();
  }
}
