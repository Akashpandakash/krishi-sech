import 'package:intl/intl.dart';

/// Date and time formatting that survives the app's full locale list.
///
/// The app ships 23 languages, but `intl` only carries CLDR date symbols for
/// the subset the Flutter framework localizes. For the rest — Bodo, Dogri,
/// Konkani, Kashmiri, Maithili, Manipuri, Sanskrit, Santali and Sindhi —
/// `DateFormat(pattern, languageCode)` throws `ArgumentError`, and it throws
/// at the call site rather than degrading, so a single unguarded format call
/// takes down whatever feature it sits in.
///
/// Every date or time the app formats for a user-visible string should go
/// through here. Constructing `DateFormat` with a language code directly is
/// the trap this module exists to close.
abstract final class AppDateFormat {
  /// Localized time of day, e.g. `3:30 PM`.
  static DateFormat time(String? languageCode) =>
      _resolve((locale) => DateFormat.jm(locale), languageCode);

  /// Localized date for an explicit skeleton, e.g. `dd MMM yyyy`.
  static DateFormat pattern(String pattern, String? languageCode) =>
      _resolve((locale) => DateFormat(pattern, locale), languageCode);

  /// Builds with the requested locale, falling back to the default locale when
  /// `intl` has no symbols for it. The fallback still produces a correct,
  /// readable string — just not one localized to a language `intl` cannot
  /// localize to anyway.
  ///
  /// The catch is deliberately untyped. `intl` signals missing symbols two
  /// different ways depending on how it was reached — `ArgumentError` from
  /// `verifiedLocale`, and `LocaleDataException` when no data is loaded at all
  /// — and the latter lives in `package:intl/src/`, so it cannot be named from
  /// here. Narrowing the catch would silently reopen the crash on whichever
  /// path was left out.
  ///
  /// A failure from the fallback itself is not swallowed: that would mean
  /// formatting is broken outright rather than merely unlocalized.
  static DateFormat _resolve(
    DateFormat Function(String? locale) build,
    String? languageCode,
  ) {
    if (languageCode == null || languageCode.isEmpty) return build(null);
    try {
      return build(languageCode);
    } catch (_) {
      return build(null);
    }
  }
}
