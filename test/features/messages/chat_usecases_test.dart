import 'package:flutter_test/flutter_test.dart';
import 'package:nextgig/features/messages/domain/entities/chat_message.dart';
import 'package:nextgig/features/messages/domain/entities/conversation.dart';
import 'package:nextgig/features/messages/domain/repositories/chat_repository.dart';
import 'package:nextgig/features/messages/domain/usecases/chat_usecases.dart';

/// Records what the use cases pass to the repository.
class _FakeChatRepository implements ChatRepository {
  final sent = <String>[];

  @override
  Stream<List<Conversation>> watchConversations(String myUid) =>
      const Stream.empty();

  @override
  Stream<List<ChatMessage>> watchMessages(String conversationId) =>
      const Stream.empty();

  @override
  Future<String> openConversation({
    required String myUid,
    required String myName,
    required String otherUid,
    required String otherName,
    String? gigId,
    String? gigTitle,
  }) async => Conversation.idFor(myUid, otherUid);

  @override
  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String text,
  }) async => sent.add(text);
}

void main() {
  group('Conversation', () {
    test('idFor gives the same id whoever starts the chat', () {
      expect(Conversation.idFor('bob', 'alice'), 'alice_bob');
      expect(Conversation.idFor('alice', 'bob'), 'alice_bob');
    });

    test('otherName returns the other participant', () {
      const chat = Conversation(
        id: 'alice_bob',
        participantIds: ['alice', 'bob'],
        participantNames: {'alice': 'Alice', 'bob': 'Bob'},
      );
      expect(chat.otherName('alice'), 'Bob');
      expect(chat.otherName('bob'), 'Alice');
    });
  });

  group('chat use cases', () {
    late _FakeChatRepository repo;

    setUp(() => repo = _FakeChatRepository());

    test('OpenConversation refuses a chat with yourself', () {
      expect(
        () => OpenConversation(repo)(
          myUid: 'alice',
          myName: 'Alice',
          otherUid: 'alice',
          otherName: 'Alice',
        ),
        throwsArgumentError,
      );
    });

    test('SendMessage trims text and ignores empty messages', () async {
      final send = SendMessage(repo);

      await send(conversationId: 'c', senderId: 'alice', text: '   ');
      await send(conversationId: 'c', senderId: 'alice', text: '  Hello  ');

      expect(repo.sent, ['Hello']);
    });
  });
}
