import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:krishi_sech/core/localization/app_language.dart';
import 'package:krishi_sech/l10n/generated/app_localizations.dart';

abstract final class AppLocalizationConfig {
  static const delegates = <LocalizationsDelegate<dynamic>>[
    AppLocalizations.delegate,
    _FallbackMaterialDelegate(),
    GlobalMaterialLocalizations.delegate,
    _FallbackCupertinoDelegate(),
    GlobalCupertinoLocalizations.delegate,
    _FallbackWidgetsDelegate(),
    GlobalWidgetsLocalizations.delegate,
  ];

  static TextDirection directionFor(Locale locale) =>
      AppLanguageCatalog.fromCode(locale.languageCode).textDirection;
}

const _frameworkFallbackCodes = {
  'brx',
  'doi',
  'kok',
  'ks',
  'mai',
  'mni',
  'sa',
  'sat',
  'sd',
};

class _FallbackMaterialDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const _FallbackMaterialDelegate();

  @override
  bool isSupported(Locale locale) =>
      _frameworkFallbackCodes.contains(locale.languageCode);

  @override
  Future<MaterialLocalizations> load(Locale locale) =>
      SynchronousFuture(const DefaultMaterialLocalizations());

  @override
  bool shouldReload(_FallbackMaterialDelegate old) => false;
}

class _FallbackCupertinoDelegate
    extends LocalizationsDelegate<CupertinoLocalizations> {
  const _FallbackCupertinoDelegate();

  @override
  bool isSupported(Locale locale) =>
      _frameworkFallbackCodes.contains(locale.languageCode);

  @override
  Future<CupertinoLocalizations> load(Locale locale) =>
      SynchronousFuture(const DefaultCupertinoLocalizations());

  @override
  bool shouldReload(_FallbackCupertinoDelegate old) => false;
}

class _FallbackWidgetsDelegate
    extends LocalizationsDelegate<WidgetsLocalizations> {
  const _FallbackWidgetsDelegate();

  @override
  bool isSupported(Locale locale) =>
      _frameworkFallbackCodes.contains(locale.languageCode);

  @override
  Future<WidgetsLocalizations> load(Locale locale) =>
      SynchronousFuture(const DefaultWidgetsLocalizations());

  @override
  bool shouldReload(_FallbackWidgetsDelegate old) => false;
}
