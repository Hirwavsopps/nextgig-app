import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/notification_model.dart';

class NotificationRemoteDataSource {
  NotificationRemoteDataSource(this._db);
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _col(String uid) =>
      _db.collection('users').doc(uid).collection('notifications');

  Stream<List<NotificationModel>> watch(String uid) {
    return _col(uid)
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map((snap) => snap.docs.map(NotificationModel.fromDoc).toList());
  }

  Future<void> markRead(String uid, String id) =>
      _col(uid).doc(id).update({'isRead': true});

  Future<void> markAllRead(String uid) async {
    final unread = await _col(uid).where('isRead', isEqualTo: false).get();
    if (unread.docs.isEmpty) return;
    final batch = _db.batch();
    for (final doc in unread.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  Future<void> delete(String uid, String id) => _col(uid).doc(id).delete();

  Future<void> create(String toUserId, NotificationModel model) =>
      _col(toUserId).add(model.toMap());
}
