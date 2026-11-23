import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:nextgig/core/di/injection.dart';
import 'package:nextgig/core/router/app_routes.dart';
import 'package:nextgig/core/utils/formatters.dart';
import 'package:nextgig/core/widgets/empty_view.dart';
import 'package:nextgig/core/widgets/error_view.dart';
import 'package:nextgig/core/widgets/loading_view.dart';
import 'package:nextgig/core/widgets/user_avatar.dart';
import 'package:nextgig/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:nextgig/features/messages/presentation/cubit/conversations_cubit.dart';

/// Messages tab: every chat I'm part of, newest first.
class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = context.read<AuthCubit>().state.user?.uid ?? '';
    return BlocProvider<ConversationsCubit>(
      create: (_) => sl<ConversationsCubit>()..start(uid),
      child: _MessagesView(myUid: uid),
    );
  }
}

class _MessagesView extends StatelessWidget {
  const _MessagesView({required this.myUid});

  final String myUid;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Messages',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: false,
      ),
      body: BlocBuilder<ConversationsCubit, ConversationsState>(
        builder: (context, state) {
          switch (state.status) {
            case ConversationsStatus.loading:
              return const LoadingView();
            case ConversationsStatus.failure:
              return ErrorView(
                message: 'Could not load your chats.',
                onRetry: () => context.read<ConversationsCubit>().start(myUid),
              );
            case ConversationsStatus.loaded:
              if (state.conversations.isEmpty) {
                return const EmptyView(
                  icon: Icons.chat_bubble_outline,
                  message:
                      'No conversations yet.\n'
                      'Open any gig and tap "Message client" to start one.',
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: state.conversations.length,
                separatorBuilder: (context, index) =>
                    const Divider(height: 1, indent: 76),
                itemBuilder: (context, i) {
                  final c = state.conversations[i];
                  final name = c.otherName(myUid);
                  final when = c.lastMessageAt;
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    leading: UserAvatar(name: name, radius: 24),
                    title: Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if ((c.gigTitle ?? '').isNotEmpty)
                          Text(
                            c.gigTitle!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        Text(
                          c.lastMessageText.isEmpty
                              ? 'Say hello \u{1F44B}'
                              : c.lastMessageText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    trailing: when == null
                        ? null
                        : Text(timeAgo(when), style: theme.textTheme.bodySmall),
                    onTap: () =>
                        context.push(AppRoutes.chat(c.id), extra: name),
                  );
                },
              );
          }
        },
      ),
    );
  }
}
