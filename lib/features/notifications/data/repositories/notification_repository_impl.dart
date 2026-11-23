import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notification_repository.dart';
import '../datasources/notification_remote_data_source.dart';
import '../models/notification_model.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  NotificationRepositoryImpl(this._remote, this._auth);

  final NotificationRemoteDataSource _remote;
  final FirebaseAuth _auth;

  String get _uid {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('Not signed in');
    return uid;
  }

  @override
  Stream<List<AppNotification>> watch() => _remote.watch(_uid);

  @override
  Future<void> markRead(String id) => _remote.markRead(_uid, id);

  @override
  Future<void> markAllRead() => _remote.markAllRead(_uid);

  @override
  Future<void> delete(String id) => _remote.delete(_uid, id);

  @override
  Future<void> send({
    required String toUserId,
    required NotificationType type,
    required String title,
    required String body,
    String? gigId,
  }) {
    return _remote.create(
      toUserId,
      NotificationModel(
        id: '',
        userId: toUserId,
        senderId: _uid,
        type: type,
        title: title,
        body: body,
        gigId: gigId,
        createdAt: DateTime.now(),
      ),
    );
  }
}
