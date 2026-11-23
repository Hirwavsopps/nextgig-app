import 'package:equatable/equatable.dart';

/// A one-to-one chat (`conversations/{id}` in docs/ERD.md).
class Conversation extends Equatable {
  const Conversation({
    required this.id,
    required this.participantIds,
    this.participantNames = const {},
    this.gigId,
    this.gigTitle,
    this.lastMessageText = '',
    this.lastMessageAt,
  });

  /// Always the two uids sorted and joined with "_", so the same two people
  /// always get the same chat (no duplicates). See [idFor].
  final String id;
  final List<String> participantIds;

  /// uid -> display name, copied in when the chat starts so the chat list
  /// doesn't need to load every profile.
  final Map<String, String> participantNames;

  /// The gig the chat started from, if any.
  final String? gigId;
  final String? gigTitle;
  final String lastMessageText;
  final DateTime? lastMessageAt;

  static String idFor(String uidA, String uidB) {
    final pair = [uidA, uidB]..sort();
    return pair.join('_');
  }

  /// The other person's name, from my point of view.
  String otherName(String myUid) {
    for (final entry in participantNames.entries) {
      if (entry.key != myUid && entry.value.trim().isNotEmpty) {
        return entry.value;
      }
    }
    return 'NextGig user';
  }

  @override
  List<Object?> get props => [
    id,
    participantIds,
    participantNames,
    gigId,
    gigTitle,
    lastMessageText,
    lastMessageAt,
  ];
}
