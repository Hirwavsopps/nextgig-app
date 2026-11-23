import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nextgig/features/messages/data/message_repository.dart';
import 'package:nextgig/features/messages/domain/entities/conversation.dart';

class InboxState extends Equatable {
  const InboxState({
    this.conversations = const [],
    this.loaded = false,
    this.error,
  });

  final List<Conversation> conversations;
  final bool loaded;
  final String? error;

  @override
  List<Object?> get props => [conversations, loaded, error];
}

class InboxCubit extends Cubit<InboxState> {
  InboxCubit(this._messages) : super(const InboxState());

  final MessageRepository _messages;
  StreamSubscription<List<Conversation>>? _sub;

  void watch(String uid) {
    _sub?.cancel();
    _sub = _messages
        .watchInbox(uid)
        .listen(
          (conversations) =>
              emit(InboxState(conversations: conversations, loaded: true)),
          onError: (Object error) => emit(InboxState(error: '$error')),
        );
  }

  @override
  Future<void> close() async {
    await _sub?.cancel();
    return super.close();
  }
}
