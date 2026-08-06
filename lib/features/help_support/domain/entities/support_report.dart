class SupportReport {
  const SupportReport({
    required this.id,
    required this.subject,
    required this.description,
    required this.createdAt,
    this.screenshotPath,
  });

  final String id;
  final String subject;
  final String description;
  final String? screenshotPath;
  final DateTime createdAt;

  Map<String, Object?> toJson() => {
    'id': id,
    'subject': subject,
    'description': description,
    'screenshotPath': screenshotPath,
    'createdAt': createdAt.toIso8601String(),
  };

  factory SupportReport.fromJson(Map<String, Object?> json) => SupportReport(
    id: json['id'] as String,
    subject: json['subject'] as String,
    description: json['description'] as String,
    screenshotPath: json['screenshotPath'] as String?,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}
