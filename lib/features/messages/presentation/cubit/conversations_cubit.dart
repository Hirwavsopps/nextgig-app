import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nextgig/features/messages/domain/entities/conversation.dart';
import 'package:nextgig/features/messages/domain/usecases/chat_usecases.dart';

enum ConversationsStatus { loading, loaded, failure }

class ConversationsState extends Equatable {
  const ConversationsState({
    this.status = ConversationsStatus.loading,
    this.conversations = const [],
  });

  final ConversationsStatus status;
  final List<Conversation> conversations;

  @override
  List<Object?> get props => [status, conversations];
}

/// The Messages tab: my chats, live.
class ConversationsCubit extends Cubit<ConversationsState> {
  ConversationsCubit(this._watch) : super(const ConversationsState());

  final WatchConversations _watch;
  StreamSubscription<List<Conversation>>? _sub;

  void start(String myUid) {
    _sub?.cancel();
    emit(const ConversationsState());
    _sub = _watch(myUid).listen(
      (list) => emit(
        ConversationsState(
          status: ConversationsStatus.loaded,
          conversations: list,
        ),
      ),
      onError: (Object _) =>
          emit(const ConversationsState(status: ConversationsStatus.failure)),
    );
  }

  @override
  Future<void> close() async {
    await _sub?.cancel();
    return super.close();
  }
}
