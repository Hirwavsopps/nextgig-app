import 'package:equatable/equatable.dart';

enum NotificationType { application, message, match, payment, system }

class AppNotification extends Equatable {
  const AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    this.senderId,
    this.gigId,
    this.isRead = false,
  });

  final String id;
  final String userId;
  final String? senderId;
  final NotificationType type;
  final String title;
  final String body;
  final String? gigId;
  final bool isRead;
  final DateTime createdAt;

  @override
  List<Object?> get props => [
    id,
    userId,
    senderId,
    type,
    title,
    body,
    gigId,
    isRead,
    createdAt,
  ];
}
