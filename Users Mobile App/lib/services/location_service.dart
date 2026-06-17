import '../data/local_location_data.dart';

class LocationData {
  final String id;
  final String
  name; // Holds localized name based on locale, or JSON string. For simplicity we will adapt it below.
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

  String _currentLocale = 'si';

  LocationService._internal();

  factory LocationService() {
    return _instance;
  }

  Future<void> init() async {
    return;
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

  String getDistrictName(String districtId) {
    if (districtId.isEmpty) return '';
    final district = getDistricts().where((item) => item.id == districtId);
    return district.isNotEmpty ? district.first.name : districtId;
  }

  String getDSAreaName(String dsAreaId, [String? districtId]) {
    if (dsAreaId.isEmpty) return '';
    final districtIds = districtId != null && districtId.isNotEmpty
        ? [districtId]
        : LocalLocationData.dsAreas.keys;

    for (final id in districtIds) {
      final area = getDSAreas(id).where((item) => item.id == dsAreaId);
      if (area.isNotEmpty) return area.first.name;
    }

    return dsAreaId;
  }

  String getLocationName(String locationId) {
    if (locationId.isEmpty) return '';
    final dsAreaName = getDSAreaName(locationId);
    if (dsAreaName != locationId) return dsAreaName;
    return getDistrictName(locationId);
  }
}
