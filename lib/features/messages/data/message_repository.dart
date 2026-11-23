import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nextgig/features/messages/domain/conversation_id.dart';
import 'package:nextgig/features/messages/domain/entities/chat_message.dart';
import 'package:nextgig/features/messages/domain/entities/conversation.dart';

class MessageRepository {
  MessageRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _conversations =>
      _firestore.collection('conversations');

  Stream<List<Conversation>> watchInbox(String uid) {
    return _conversations
        .where('participantIds', arrayContains: uid)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => _conversation(doc.id, doc.data()))
              .toList(),
        );
  }

  Stream<Conversation?> watchConversation(String id) {
    return _conversations.doc(id).snapshots().map((doc) {
      final data = doc.data();
      if (data == null) return null;
      return _conversation(doc.id, data);
    });
  }

  Stream<List<ChatMessage>> watchMessages(String conversationId) {
    return _conversations
        .doc(conversationId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            final created = data['createdAt'];
            return ChatMessage(
              id: doc.id,
              senderId: data['senderId'] as String? ?? '',
              text: data['text'] as String? ?? '',
              createdAt: created is Timestamp ? created.toDate() : null,
            );
          }).toList(),
        );
  }

  /// Creates the thread if this pair does not have one yet. Returns its id.
  Future<String> open({
    required String meId,
    required String otherId,
    required String myName,
    required String otherName,
    String? gigId,
  }) async {
    final id = conversationId(meId, otherId);
    final ref = _conversations.doc(id);
    final existing = await ref.get();
    if (existing.exists) return id;
    final ids = [meId, otherId]..sort();
    await ref.set({
      'participantIds': ids,
      'names': {meId: myName, otherId: otherName},
      'lastText': '',
      'updatedAt': FieldValue.serverTimestamp(),
      'gigId': ?gigId,
    });
    return id;
  }

  Future<void> send({
    required String conversationId,
    required String senderId,
    required String text,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    final conversation = _conversations.doc(conversationId);
    final batch = _firestore.batch();
    batch.set(conversation.collection('messages').doc(), {
      'senderId': senderId,
      'text': trimmed,
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.update(conversation, {
      'lastText': trimmed,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  Conversation _conversation(String id, Map<String, dynamic> data) {
    final updated = data['updatedAt'];
    final names = data['names'];
    return Conversation(
      id: id,
      participantIds: List<String>.from(
        data['participantIds'] as List<dynamic>? ?? const <String>[],
      ),
      names: names is Map
          ? names.map((key, value) => MapEntry('$key', '$value'))
          : const <String, String>{},
      lastText: data['lastText'] as String? ?? '',
      updatedAt: updated is Timestamp ? updated.toDate() : null,
      gigId: data['gigId'] as String?,
    );
  }
}
