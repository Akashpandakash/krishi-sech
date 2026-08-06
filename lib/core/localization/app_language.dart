import 'package:flutter/widgets.dart';

class AppLanguage {
  const AppLanguage({
    required this.code,
    required this.englishName,
    required this.nativeName,
    this.textDirection = TextDirection.ltr,
    this.isFullyTranslated = false,
  });

  final String code;
  final String englishName;
  final String nativeName;
  final TextDirection textDirection;
  final bool isFullyTranslated;

  Locale get locale => Locale(code);
}

abstract final class AppLanguageCatalog {
  static const languages = <AppLanguage>[
    AppLanguage(code: 'as', englishName: 'Assamese', nativeName: 'অসমীয়া'),
    AppLanguage(
      code: 'bn',
      englishName: 'Bangla',
      nativeName: 'বাংলা',
      isFullyTranslated: true,
    ),
    AppLanguage(code: 'brx', englishName: 'Bodo', nativeName: "बर' राव"),
    AppLanguage(code: 'doi', englishName: 'Dogri', nativeName: 'डोगरी'),
    AppLanguage(code: 'gu', englishName: 'Gujarati', nativeName: 'ગુજરાતી'),
    AppLanguage(
      code: 'hi',
      englishName: 'Hindi',
      nativeName: 'हिन्दी',
      isFullyTranslated: true,
    ),
    AppLanguage(code: 'kn', englishName: 'Kannada', nativeName: 'ಕನ್ನಡ'),
    AppLanguage(
      code: 'ks',
      englishName: 'Kashmiri',
      nativeName: 'کٲشُر',
      textDirection: TextDirection.rtl,
    ),
    AppLanguage(code: 'kok', englishName: 'Konkani', nativeName: 'कोंकणी'),
    AppLanguage(code: 'mai', englishName: 'Maithili', nativeName: 'मैथिली'),
    AppLanguage(code: 'ml', englishName: 'Malayalam', nativeName: 'മലയാളം'),
    AppLanguage(code: 'mni', englishName: 'Manipuri', nativeName: 'ꯃꯤꯇꯩ ꯂꯣꯟ'),
    AppLanguage(code: 'mr', englishName: 'Marathi', nativeName: 'मराठी'),
    AppLanguage(code: 'ne', englishName: 'Nepali', nativeName: 'नेपाली'),
    AppLanguage(code: 'or', englishName: 'Odia', nativeName: 'ଓଡ଼ିଆ'),
    AppLanguage(code: 'pa', englishName: 'Punjabi', nativeName: 'ਪੰਜਾਬੀ'),
    AppLanguage(code: 'sa', englishName: 'Sanskrit', nativeName: 'संस्कृतम्'),
    AppLanguage(code: 'sat', englishName: 'Santali', nativeName: 'ᱥᱟᱱᱛᱟᱲᱤ'),
    AppLanguage(
      code: 'sd',
      englishName: 'Sindhi',
      nativeName: 'سنڌي',
      textDirection: TextDirection.rtl,
    ),
    AppLanguage(code: 'ta', englishName: 'Tamil', nativeName: 'தமிழ்'),
    AppLanguage(code: 'te', englishName: 'Telugu', nativeName: 'తెలుగు'),
    AppLanguage(
      code: 'ur',
      englishName: 'Urdu',
      nativeName: 'اردو',
      textDirection: TextDirection.rtl,
    ),
    AppLanguage(
      code: 'en',
      englishName: 'English',
      nativeName: 'English',
      isFullyTranslated: true,
    ),
  ];

  static final Set<String> supportedCodes = languages
      .map((language) => language.code)
      .toSet();

  static AppLanguage fromCode(String? code) => languages.firstWhere(
    (language) => language.code == code,
    orElse: () => languages.firstWhere((language) => language.code == 'bn'),
  );

  static List<AppLanguage> search(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return languages;
    return languages
        .where(
          (language) =>
              language.englishName.toLowerCase().contains(normalized) ||
              language.nativeName.toLowerCase().contains(normalized) ||
              language.code.toLowerCase().contains(normalized),
        )
        .toList(growable: false);
  }

  static String serviceCodeFor(String? code) {
    final language = fromCode(code);
    return language.isFullyTranslated ? language.code : 'en';
  }
}
