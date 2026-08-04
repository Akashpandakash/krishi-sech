import 'dart:convert';

import 'package:krishi_sech/features/disease_scan/domain/models/disease_scan_result.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalDiseaseDiagnosisStore {
  static const lastKey = 'last_disease_diagnosis_json';
  static const historyKey = 'disease_diagnosis_history_json';

  Future<DiseaseScanResult?> getLast() async {
    final raw = (await SharedPreferences.getInstance()).getString(lastKey);
    if (raw == null) return null;
    try {
      return DiseaseScanResult.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }

  Future<List<DiseaseScanResult>> getHistory() async {
    final raw = (await SharedPreferences.getInstance()).getString(historyKey);
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .map(DiseaseScanResult.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> save(DiseaseScanResult result) async {
    final preferences = await SharedPreferences.getInstance();
    final history = await getHistory();
    history.insert(0, result);
    if (history.length > 50) history.removeRange(50, history.length);
    await Future.wait([
      preferences.setString(lastKey, jsonEncode(result.toJson())),
      preferences.setString(
        historyKey,
        jsonEncode(history.map((item) => item.toJson()).toList()),
      ),
    ]);
  }
}
