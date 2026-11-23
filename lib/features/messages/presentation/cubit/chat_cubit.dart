import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nextgig/features/messages/domain/entities/chat_message.dart';
import 'package:nextgig/features/messages/domain/usecases/chat_usecases.dart';

enum ChatStatus { loading, loaded, failure }

class ChatState extends Equatable {
  const ChatState({
    this.status = ChatStatus.loading,
    this.messages = const [],
    this.isSending = false,
    this.errorMessage,
  });

  final ChatStatus status;
  final List<ChatMessage> messages;
  final bool isSending;
  final String? errorMessage;

  ChatState copyWith({
    ChatStatus? status,
    List<ChatMessage>? messages,
    bool? isSending,
    String? errorMessage,
  }) {
    return ChatState(
      status: status ?? this.status,
      messages: messages ?? this.messages,
      isSending: isSending ?? this.isSending,
      errorMessage: errorMessage, // one-shot
    );
  }

  @override
  List<Object?> get props => [status, messages, isSending, errorMessage];
}

/// One open chat: live messages plus sending.
class ChatCubit extends Cubit<ChatState> {
  ChatCubit(this._watchMessages, this._sendMessage) : super(const ChatState());

  final WatchMessages _watchMessages;
  final SendMessage _sendMessage;
  StreamSubscription<List<ChatMessage>>? _sub;
  late String _conversationId;
  late String _myUid;

  void start({required String conversationId, required String myUid}) {
    _conversationId = conversationId;
    _myUid = myUid;
    _sub?.cancel();
    _sub = _watchMessages(conversationId).listen(
      (messages) =>
          emit(state.copyWith(status: ChatStatus.loaded, messages: messages)),
      onError: (Object _) => emit(state.copyWith(status: ChatStatus.failure)),
    );
  }

  /// Returns true if sent, so the screen can clear the text box.
  Future<bool> send(String text) async {
    if (text.trim().isEmpty || state.isSending) return false;
    emit(state.copyWith(isSending: true));
    try {
      await _sendMessage(
        conversationId: _conversationId,
        senderId: _myUid,
        text: text,
      );
      emit(state.copyWith(isSending: false));
      return true;
    } catch (_) {
      emit(
        state.copyWith(
          isSending: false,
          errorMessage: 'Message not sent. Check your connection.',
        ),
      );
      return false;
    }
  }

  @override
  Future<void> close() async {
    await _sub?.cancel();
    return super.close();
  }
}
