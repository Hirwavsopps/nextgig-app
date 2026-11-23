import '../entities/app_notification.dart';

abstract class NotificationRepository {
  Stream<List<AppNotification>> watch();
  Future<void> markRead(String id);
  Future<void> markAllRead();
  Future<void> delete(String id);

  Future<void> send({
    required String toUserId,
    required NotificationType type,
    required String title,
    required String body,
    String? gigId,
  });
}
