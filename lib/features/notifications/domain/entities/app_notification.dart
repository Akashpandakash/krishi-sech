/// Mirrors the backend's broadcast categories, which is what the inbox
/// actually carries.
enum AppNotificationType { general, weather, advisory, market, maintenance }

/// One message in the in-app inbox.
///
/// [title] and [message] are authored by an operator and delivered by the
/// backend, so they travel with the notification rather than being looked up
/// from a per-type table in the app.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.createdAt,
    this.deepLink,
    this.isRead = false,
  });

  final String id;
  final AppNotificationType type;
  final String title;
  final String message;
  final DateTime createdAt;
  final String? deepLink;
  final bool isRead;

  AppNotification copyWith({bool? isRead}) => AppNotification(
    id: id,
    type: type,
    title: title,
    message: message,
    createdAt: createdAt,
    deepLink: deepLink,
    isRead: isRead ?? this.isRead,
  );
}
