import 'package:nextgig/features/messages/domain/entities/chat_message.dart';
import 'package:nextgig/features/messages/domain/entities/conversation.dart';

abstract class ChatRepository {
  /// READ: my chats, most recent first.
  Stream<List<Conversation>> watchConversations(String myUid);

  /// READ: the messages in one chat, oldest first.
  Stream<List<ChatMessage>> watchMessages(String conversationId);

  /// Returns the chat between two people, CREATEing it the first time.
  Future<String> openConversation({
    required String myUid,
    required String myName,
    required String otherUid,
    required String otherName,
    String? gigId,
    String? gigTitle,
  });

  /// CREATE a message and UPDATE the chat's last-message preview.
  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String text,
  });
}
