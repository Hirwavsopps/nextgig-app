import 'package:equatable/equatable.dart';

/// One message (`conversations/{id}/messages/{messageId}`).
class ChatMessage extends Equatable {
  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    this.createdAt,
  });

  final String id;
  final String senderId;
  final String text;

  /// Null for a moment after sending, until Firestore sets the server time.
  final DateTime? createdAt;

  @override
  List<Object?> get props => [id, senderId, text, createdAt];
}
