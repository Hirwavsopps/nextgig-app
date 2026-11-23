import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nextgig/features/messages/data/message_repository.dart';
import 'package:nextgig/features/messages/domain/entities/chat_message.dart';

class ThreadState extends Equatable {
  const ThreadState({
    this.messages = const [],
    this.title = 'Messages',
    this.error,
  });

  final List<ChatMessage> messages;
  final String title;
  final String? error;

  ThreadState copyWith({
    List<ChatMessage>? messages,
    String? title,
    String? error,
  }) {
    return ThreadState(
      messages: messages ?? this.messages,
      title: title ?? this.title,
      error: error,
    );
  }

  @override
  List<Object?> get props => [messages, title, error];
}

class ThreadCubit extends Cubit<ThreadState> {
  ThreadCubit(this._messages) : super(const ThreadState());

  final MessageRepository _messages;
  StreamSubscription<List<ChatMessage>>? _messagesSub;
  StreamSubscription<Object?>? _conversationSub;
  String? _id;

  void watch(String conversationId, String me) {
    _id = conversationId;
    _messagesSub?.cancel();
    _conversationSub?.cancel();
    _messagesSub = _messages
        .watchMessages(conversationId)
        .listen(
          (messages) => emit(state.copyWith(messages: messages)),
          onError: (Object error) => emit(state.copyWith(error: '$error')),
        );
    _conversationSub = _messages.watchConversation(conversationId).listen((
      conversation,
    ) {
      if (conversation == null) return;
      emit(
        state.copyWith(title: conversation.nameFor(conversation.otherId(me))),
      );
    }, onError: (Object error) => emit(state.copyWith(error: '$error')));
  }

  Future<void> send(String senderId, String text) async {
    final id = _id;
    if (id == null) return;
    try {
      await _messages.send(conversationId: id, senderId: senderId, text: text);
    } catch (error) {
      emit(state.copyWith(error: '$error'));
      rethrow;
    }
  }

  @override
  Future<void> close() async {
    await _messagesSub?.cancel();
    await _conversationSub?.cancel();
    return super.close();
  }
}
