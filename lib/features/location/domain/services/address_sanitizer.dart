bool isAdministrativeDivisionName(String? value) {
  final normalized = value?.trim().toLowerCase();
  if (normalized == null || normalized.isEmpty) return false;

  return normalized.endsWith(' division') ||
      normalized.contains('presidency division') ||
      normalized.contains('revenue division') ||
      normalized.contains('administrative division');
}

String? firstFriendlyAddressPart(Iterable<String?> values) {
  for (final value in values) {
    final trimmed = value?.trim();
    if (trimmed != null &&
        trimmed.isNotEmpty &&
        !isAdministrativeDivisionName(trimmed)) {
      return trimmed;
    }
  }
  return null;
}

String? sanitizeFormattedAddress(String? address) {
  if (address == null || address.trim().isEmpty) return null;

  final parts = address
      .split(',')
      .map((part) => part.trim())
      .where((part) => part.isNotEmpty && !isAdministrativeDivisionName(part))
      .toSet()
      .toList();
  return parts.isEmpty ? null : parts.join(', ');
}
