import 'dart:convert';

import 'package:krishi_sech/features/help_support/domain/entities/support_report.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalSupportReportDataSource {
  const LocalSupportReportDataSource(this._preferences);

  static const storageKey = 'help_support_demo_reports_v1';
  final SharedPreferences _preferences;

  Future<List<SupportReport>> getReports() async {
    final encoded = _preferences.getString(storageKey);
    if (encoded == null || encoded.isEmpty) return const [];
    final values = jsonDecode(encoded) as List<dynamic>;
    return values
        .map(
          (value) =>
              SupportReport.fromJson(Map<String, Object?>.from(value as Map)),
        )
        .toList(growable: false);
  }

  Future<void> saveReports(List<SupportReport> reports) =>
      _preferences.setString(
        storageKey,
        jsonEncode(reports.map((report) => report.toJson()).toList()),
      );
}
