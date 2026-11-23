import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nextgig/features/messages/domain/entities/chat_message.dart';
import 'package:nextgig/features/messages/domain/entities/conversation.dart';
import 'package:nextgig/features/messages/domain/repositories/chat_repository.dart';

/// Firestore implementation of chat. Small enough that the data source and
/// repository are one class; the mapping helpers are at the bottom.
class ChatRepositoryImpl implements ChatRepository {
  ChatRepositoryImpl(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _conversations =>
      _firestore.collection('conversations');

  /// array-contains + orderBy on another field would need a composite index,
  /// so we sort on the phone (one person has few chats).
  @override
  Stream<List<Conversation>> watchConversations(String myUid) {
    return _conversations
        .where('participantIds', arrayContains: myUid)
        .snapshots()
        .map((snap) {
          final list = snap.docs.map(_toConversation).toList();
          list.sort((a, b) {
            final at = a.lastMessageAt ?? DateTime(0);
            final bt = b.lastMessageAt ?? DateTime(0);
            return bt.compareTo(at);
          });
          return list;
        });
  }

  @override
  Stream<List<ChatMessage>> watchMessages(String conversationId) {
    return _conversations
        .doc(conversationId)
        .collection('messages')
        .orderBy('createdAt')
        .limitToLast(200)
        .snapshots()
        .map(
          (snap) => snap.docs.map((doc) {
            final d = doc.data();
            // A message we just sent has no server time for a moment:
            // createdAt is null and the bubble shows "Sending...".
            final created = d['createdAt'];
            return ChatMessage(
              id: doc.id,
              senderId: d['senderId'] as String? ?? '',
              text: d['text'] as String? ?? '',
              createdAt: created is Timestamp ? created.toDate() : null,
            );
          }).toList(),
        );
  }

  @override
  Future<String> openConversation({
    required String myUid,
    required String myName,
    required String otherUid,
    required String otherName,
    String? gigId,
    String? gigTitle,
  }) async {
    final id = Conversation.idFor(myUid, otherUid);
    final ref = _conversations.doc(id);
    final existing = await ref.get();
    if (!existing.exists) {
      // CREATE the chat the first time these two people talk.
      await ref.set({
        'participantIds': [myUid, otherUid]..sort(),
        'participantNames': {myUid: myName, otherUid: otherName},
        'gigId': gigId,
        'gigTitle': gigTitle,
        'lastMessageText': '',
        'lastMessageAt': null,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    return id;
  }

  /// A batch writes both documents together: either both succeed or neither,
  /// so the chat list preview never disagrees with the messages.
  @override
  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String text,
  }) {
    final chat = _conversations.doc(conversationId);
    final batch = _firestore.batch();
    batch.set(chat.collection('messages').doc(), {
      'senderId': senderId,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.update(chat, {
      'lastMessageText': text.length > 120
          ? '${text.substring(0, 117)}...'
          : text,
      'lastMessageAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return batch.commit();
  }

  Conversation _toConversation(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const {};
    final last = d['lastMessageAt'];
    final names = (d['participantNames'] as Map?) ?? const {};
    return Conversation(
      id: doc.id,
      participantIds: List<String>.from(
        (d['participantIds'] as List?) ?? const [],
      ),
      participantNames: names.map((k, v) => MapEntry('$k', '$v')),
      gigId: d['gigId'] as String?,
      gigTitle: d['gigTitle'] as String?,
      lastMessageText: d['lastMessageText'] as String? ?? '',
      lastMessageAt: last is Timestamp ? last.toDate() : null,
    );
  }
}
