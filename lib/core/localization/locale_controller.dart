import 'package:flutter/material.dart';
import 'package:krishi_sech/core/localization/app_language.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleController extends ChangeNotifier {
  LocaleController._({
    required this._locale,
    required this._hasSavedLocale,
    this._preferences,
  });

  static const preferenceKey = 'selected_language_code';
  static const defaultLocale = Locale('bn');
  static final supportedLanguageCodes = AppLanguageCatalog.supportedCodes;

  final SharedPreferences? _preferences;
  Locale _locale;
  bool _hasSavedLocale;

  Locale get locale => _locale;
  bool get hasSavedLocale => _hasSavedLocale;

  static Future<LocaleController> load() async {
    final preferences = await SharedPreferences.getInstance();
    final savedCode = preferences.getString(preferenceKey);
    final validCode = supportedLanguageCodes.contains(savedCode)
        ? savedCode
        : null;

    return LocaleController._(
      locale: Locale(validCode ?? defaultLocale.languageCode),
      hasSavedLocale: validCode != null,
      preferences: preferences,
    );
  }

  factory LocaleController.inMemory({
    Locale locale = defaultLocale,
    bool hasSavedLocale = false,
  }) {
    return LocaleController._(locale: locale, hasSavedLocale: hasSavedLocale);
  }

  Future<void> setLocale(Locale locale) async {
    if (!supportedLanguageCodes.contains(locale.languageCode)) {
      return;
    }

    final changed = _locale.languageCode != locale.languageCode;
    _locale = Locale(locale.languageCode);
    _hasSavedLocale = true;
    await _preferences?.setString(preferenceKey, locale.languageCode);

    if (changed) {
      notifyListeners();
    }
  }
}
