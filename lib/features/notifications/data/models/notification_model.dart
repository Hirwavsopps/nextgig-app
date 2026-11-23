import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/app_notification.dart';

class NotificationModel extends AppNotification {
  const NotificationModel({
    required super.id,
    required super.userId,
    required super.type,
    required super.title,
    required super.body,
    required super.createdAt,
    super.senderId,
    super.gigId,
    super.isRead,
  });

  factory NotificationModel.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final map = doc.data() ?? {};
    final created = map['createdAt'];
    return NotificationModel(
      id: doc.id,
      userId: map['userId'] as String? ?? '',
      senderId: map['senderId'] as String?,
      type: NotificationType.values.firstWhere(
        (t) => t.name == map['type'],
        orElse: () => NotificationType.system,
      ),
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
      gigId: map['gigId'] as String?,
      isRead: map['isRead'] as bool? ?? false,
      // serverTimestamp is null for a moment on local writes
      createdAt: created is Timestamp ? created.toDate() : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'senderId': senderId,
    'type': type.name,
    'title': title,
    'body': body,
    if (gigId != null) 'gigId': gigId,
    'isRead': isRead,
    'createdAt': FieldValue.serverTimestamp(),
  };
}
