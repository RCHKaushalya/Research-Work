import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LocalizationProvider extends ChangeNotifier {
  static const List<String> _supportedLocales = ['si', 'ta'];
  static const Map<String, String> _localeNames = {
    'si': 'Sinhala',
    'ta': 'Tamil',
  };

  Locale _currentLocale = const Locale('si');
  Map<String, dynamic> _localizedStrings = {};

  LocalizationProvider() {
    _loadTranslations('si');
  }

  Locale get currentLocale => _currentLocale;
  String get currentLanguageName => _localeNames[_currentLocale.languageCode] ?? 'Sinhala';
  Map<String, dynamic> get localizedStrings => _localizedStrings;
  List<String> get supportedLocales => _supportedLocales;

  Future<void> _loadTranslations(String languageCode) async {
    try {
      String jsonString = await rootBundle
          .loadString('assets/translations/$languageCode.json');
      _localizedStrings = jsonDecode(jsonString);
    } catch (e) {
      print('Error loading translations for $languageCode: $e');
      if (languageCode != 'si') {
        await _loadTranslations('si');
      }
    }
  }

  Future<void> setLanguage(String languageCode) async {
    if (!_supportedLocales.contains(languageCode)) return;

    await _loadTranslations(languageCode);
    _currentLocale = Locale(languageCode);
    notifyListeners();
  }

  String translate(String key) {
    return _localizedStrings[key] ?? key;
  }

  String? translateNullable(String key) {
    return _localizedStrings[key] as String?;
  }
}
