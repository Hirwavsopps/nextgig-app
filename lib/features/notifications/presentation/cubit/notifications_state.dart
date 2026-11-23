import 'package:equatable/equatable.dart';
import '../../domain/entities/app_notification.dart';

enum NotificationsStatus { initial, loading, loaded, failure }

class NotificationsState extends Equatable {
  const NotificationsState({
    this.status = NotificationsStatus.initial,
    this.items = const [],
    this.unreadOnly = false,
    this.errorMessage,
  });

  final NotificationsStatus status;
  final List<AppNotification> items;
  final bool unreadOnly;
  final String? errorMessage;

  int get unreadCount => items.where((n) => !n.isRead).length;

  List<AppNotification> get visible =>
      unreadOnly ? items.where((n) => !n.isRead).toList() : items;

  NotificationsState copyWith({
    NotificationsStatus? status,
    List<AppNotification>? items,
    bool? unreadOnly,
    String? errorMessage,
  }) =>
      NotificationsState(
        status: status ?? this.status,
        items: items ?? this.items,
        unreadOnly: unreadOnly ?? this.unreadOnly,
        errorMessage: errorMessage,
      );

  @override
  List<Object?> get props => [status, items, unreadOnly, errorMessage];
}