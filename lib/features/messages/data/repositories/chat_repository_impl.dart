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
        .asyncMap((snap) async {
          final list = await Future.wait(
            snap.docs.map((doc) => _withProfile(_toConversation(doc), myUid)),
          );
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
    final last = d['lastMessageAt'] ?? d['updatedAt'];
    // Older chats stored names under `names` / preview under `lastText`.
    final names = <String, String>{
      ..._stringMap(d['names']),
      ..._stringMap(d['participantNames']),
    };
    return Conversation(
      id: doc.id,
      participantIds: List<String>.from(
        (d['participantIds'] as List?) ?? const [],
      ),
      participantNames: names,
      participantPhotos: _stringMap(d['participantPhotos']),
      gigId: d['gigId'] as String?,
      gigTitle: d['gigTitle'] as String?,
      lastMessageText:
          d['lastMessageText'] as String? ?? d['lastText'] as String? ?? '',
      lastMessageAt: last is Timestamp ? last.toDate() : null,
    );
  }

  Map<String, String> _stringMap(Object? raw) {
    if (raw is! Map) return const {};
    return raw.map((k, v) => MapEntry('$k', '$v'));
  }

  /// Fill blank name/photo from the other user's profile doc.
  Future<Conversation> _withProfile(Conversation chat, String myUid) async {
    final other = chat.otherId(myUid);
    if (other == null) return chat;
    final storedName = chat.participantNames[other]?.trim() ?? '';
    final storedPhoto = chat.participantPhotos[other] ?? '';
    if (storedName.isNotEmpty && storedPhoto.isNotEmpty) return chat;

    final snap = await _firestore.collection('users').doc(other).get();
    final data = snap.data();
    if (data == null) return chat;
    final name = (data['name'] as String?)?.trim() ?? '';
    final photo = (data['photoUrl'] as String?) ?? '';
    if (name.isEmpty && photo.isEmpty) return chat;

    return Conversation(
      id: chat.id,
      participantIds: chat.participantIds,
      participantNames: {
        ...chat.participantNames,
        if (storedName.isEmpty && name.isNotEmpty) other: name,
      },
      participantPhotos: {
        ...chat.participantPhotos,
        if (storedPhoto.isEmpty && photo.isNotEmpty) other: photo,
      },
      gigId: chat.gigId,
      gigTitle: chat.gigTitle,
      lastMessageText: chat.lastMessageText,
      lastMessageAt: chat.lastMessageAt,
    );
  }
}
