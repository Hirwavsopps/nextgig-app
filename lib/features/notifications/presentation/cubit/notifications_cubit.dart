import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/notification_usecases.dart';
import 'notifications_state.dart';

class NotificationsCubit extends Cubit<NotificationsState> {
  NotificationsCubit({
    required WatchNotifications watch,
    required MarkNotificationRead markRead,
    required MarkAllNotificationsRead markAllRead,
    required DeleteNotification delete,
  })  : _watch = watch,
        _markRead = markRead,
        _markAllRead = markAllRead,
        _delete = delete,
        super(const NotificationsState());

  final WatchNotifications _watch;
  final MarkNotificationRead _markRead;
  final MarkAllNotificationsRead _markAllRead;
  final DeleteNotification _delete;
  StreamSubscription<dynamic>? _sub;

  void start() {
    _sub?.cancel();
    emit(state.copyWith(status: NotificationsStatus.loading));
    try {
      _sub = _watch().listen(
        (items) => emit(
          state.copyWith(status: NotificationsStatus.loaded, items: items),
        ),
        onError: (Object e) => emit(
          state.copyWith(
            status: NotificationsStatus.failure,
            errorMessage: 'Could not load notifications.',
          ),
        ),
      );
    } catch (_) {
      emit(state.copyWith(
        status: NotificationsStatus.failure,
        errorMessage: 'Please sign in to see notifications.',
      ));
    }
  }

  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
    emit(const NotificationsState());
  }

  void setUnreadOnly(bool value) => emit(state.copyWith(unreadOnly: value));

  Future<void> markRead(String id) async {
    try {
      await _markRead(id);
    } catch (_) {}
  }

  Future<void> markAllRead() async {
    try {
      await _markAllRead();
    } catch (_) {
      emit(state.copyWith(errorMessage: 'Could not mark all as read.'));
    }
  }

  Future<void> delete(String id) async {
    try {
      await _delete(id);
    } catch (_) {
      emit(state.copyWith(errorMessage: 'Could not delete notification.'));
    }
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}