import '../entities/app_notification.dart';
import '../repositories/notification_repository.dart';

class WatchNotifications {
  const WatchNotifications(this._repo);
  final NotificationRepository _repo;
  Stream<List<AppNotification>> call() => _repo.watch();
}

class MarkNotificationRead {
  const MarkNotificationRead(this._repo);
  final NotificationRepository _repo;
  Future<void> call(String id) => _repo.markRead(id);
}

class MarkAllNotificationsRead {
  const MarkAllNotificationsRead(this._repo);
  final NotificationRepository _repo;
  Future<void> call() => _repo.markAllRead();
}

class DeleteNotification {
  const DeleteNotification(this._repo);
  final NotificationRepository _repo;
  Future<void> call(String id) => _repo.delete(id);
}

class SendNotification {
  const SendNotification(this._repo);
  final NotificationRepository _repo;
  Future<void> call({
    required String toUserId,
    required NotificationType type,
    required String title,
    required String body,
    String? gigId,
  }) => _repo.send(
    toUserId: toUserId,
    type: type,
    title: title,
    body: body,
    gigId: gigId,
  );
}
