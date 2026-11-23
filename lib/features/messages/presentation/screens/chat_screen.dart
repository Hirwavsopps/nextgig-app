import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nextgig/core/di/injection.dart';
import 'package:nextgig/core/widgets/error_view.dart';
import 'package:nextgig/core/widgets/loading_view.dart';
import 'package:nextgig/core/widgets/user_avatar.dart';
import 'package:nextgig/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:nextgig/features/messages/domain/entities/chat_message.dart';
import 'package:nextgig/features/messages/presentation/cubit/chat_cubit.dart';

/// Figma frame 9: Chat with one person.
class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key, required this.conversationId, this.title});

  final String conversationId;

  /// The other person's name. Can be null if the app was restarted on this
  /// page; then we show a generic title.
  final String? title;

  @override
  Widget build(BuildContext context) {
    final uid = context.read<AuthCubit>().state.user?.uid ?? '';
    return BlocProvider<ChatCubit>(
      create: (_) =>
          sl<ChatCubit>()..start(conversationId: conversationId, myUid: uid),
      child: _ChatView(myUid: uid, title: title ?? 'Chat'),
    );
  }
}

/// Stateful only to own and dispose the text controller; messages and the
/// sending flag live in [ChatCubit].
class _ChatView extends StatefulWidget {
  const _ChatView({required this.myUid, required this.title});

  final String myUid;
  final String title;

  @override
  State<_ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<_ChatView> {
  final _input = TextEditingController();

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final sent = await context.read<ChatCubit>().send(_input.text);
    if (sent) _input.clear();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return BlocListener<ChatCubit, ChatState>(
      listenWhen: (_, s) => s.errorMessage != null,
      listener: (context, s) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.errorMessage!), backgroundColor: scheme.error),
      ),
      child: Scaffold(
        appBar: AppBar(
          titleSpacing: 0,
          title: Row(
            children: [
              UserAvatar(name: widget.title, radius: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.title,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: BlocBuilder<ChatCubit, ChatState>(
                buildWhen: (a, b) =>
                    a.status != b.status || a.messages != b.messages,
                builder: (context, state) {
                  if (state.status == ChatStatus.loading) {
                    return const LoadingView();
                  }
                  if (state.status == ChatStatus.failure) {
                    return const ErrorView(message: 'Could not load messages.');
                  }
                  if (state.messages.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'No messages yet. Introduce yourself and ask about '
                          'the gig.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    );
                  }
                  // reverse: true keeps the newest message at the bottom and
                  // the list starts scrolled there, like any chat app.
                  final messages = state.messages.reversed.toList();
                  return ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.all(12),
                    itemCount: messages.length,
                    itemBuilder: (context, i) => _Bubble(
                      message: messages[i],
                      isMine: messages[i].senderId == widget.myUid,
                    ),
                  );
                },
              ),
            ),
            SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
                decoration: BoxDecoration(
                  color: scheme.surface,
                  border: Border(top: BorderSide(color: scheme.outlineVariant)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _input,
                        minLines: 1,
                        maxLines: 4,
                        maxLength: 2000,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          hintText: 'Write a message',
                          counterText: '',
                          filled: true,
                          fillColor: scheme.surfaceContainerHighest,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    BlocBuilder<ChatCubit, ChatState>(
                      buildWhen: (a, b) => a.isSending != b.isSending,
                      builder: (context, state) => IconButton.filled(
                        tooltip: 'Send',
                        onPressed: state.isSending ? null : _send,
                        icon: state.isSending
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.send),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message, required this.isMine});

  final ChatMessage message;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final time = message.createdAt;
    final timeText = time == null
        ? 'Sending...'
        : '${time.hour.toString().padLeft(2, '0')}:'
              '${time.minute.toString().padLeft(2, '0')}';
    final background = isMine ? scheme.primary : scheme.surfaceContainerHighest;
    final foreground = isMine ? scheme.onPrimary : scheme.onSurface;

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.75,
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(isMine ? 18 : 4),
              bottomRight: Radius.circular(isMine ? 4 : 18),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                message.text,
                style: theme.textTheme.bodyMedium?.copyWith(color: foreground),
              ),
              const SizedBox(height: 2),
              Text(
                timeText,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: foreground.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
