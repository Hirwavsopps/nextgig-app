import 'package:equatable/equatable.dart';

class Conversation extends Equatable {
  const Conversation({
    required this.id,
    required this.participantIds,
    required this.names,
    this.lastText = '',
    this.updatedAt,
    this.gigId,
  });

  final String id;
  final List<String> participantIds;
  final Map<String, String> names;
  final String lastText;
  final DateTime? updatedAt;
  final String? gigId;

  String otherId(String me) {
    for (final id in participantIds) {
      if (id != me) return id;
    }
    return me;
  }

  String nameFor(String uid) => names[uid] ?? 'User';

  @override
  List<Object?> get props => [
    id,
    participantIds,
    names,
    lastText,
    updatedAt,
    gigId,
  ];
}
