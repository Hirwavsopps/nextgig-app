import 'package:nextgig/features/messages/domain/entities/chat_message.dart';
import 'package:nextgig/features/messages/domain/entities/conversation.dart';
import 'package:nextgig/features/messages/domain/repositories/chat_repository.dart';

class WatchConversations {
  const WatchConversations(this._repository);
  final ChatRepository _repository;

  Stream<List<Conversation>> call(String myUid) =>
      _repository.watchConversations(myUid);
}

class WatchMessages {
  const WatchMessages(this._repository);
  final ChatRepository _repository;

  Stream<List<ChatMessage>> call(String conversationId) =>
      _repository.watchMessages(conversationId);
}

class OpenConversation {
  const OpenConversation(this._repository);
  final ChatRepository _repository;

  Future<String> call({
    required String myUid,
    required String myName,
    required String otherUid,
    required String otherName,
    String? gigId,
    String? gigTitle,
  }) {
    if (myUid == otherUid) {
      throw ArgumentError('You cannot start a chat with yourself.');
    }
    return _repository.openConversation(
      myUid: myUid,
      myName: myName,
      otherUid: otherUid,
      otherName: otherName,
      gigId: gigId,
      gigTitle: gigTitle,
    );
  }
}

class SendMessage {
  const SendMessage(this._repository);
  final ChatRepository _repository;

  /// Trims the text and ignores empty messages.
  Future<void> call({
    required String conversationId,
    required String senderId,
    required String text,
  }) async {
    final clean = text.trim();
    if (clean.isEmpty) return;
    await _repository.sendMessage(
      conversationId: conversationId,
      senderId: senderId,
      text: clean.length > 2000 ? clean.substring(0, 2000) : clean,
    );
  }
}
