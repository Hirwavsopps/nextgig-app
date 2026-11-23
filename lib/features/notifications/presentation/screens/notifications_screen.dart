import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:nextgig/core/router/app_routes.dart';
import 'package:nextgig/core/widgets/empty_view.dart';
import 'package:nextgig/core/widgets/error_view.dart';
import 'package:nextgig/core/widgets/loading_view.dart';
import '../cubit/notifications_cubit.dart';
import '../cubit/notifications_state.dart';
import '../widgets/notification_tile.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<NotificationsCubit, NotificationsState>(
      listenWhen: (p, c) =>
          c.errorMessage != null && p.errorMessage != c.errorMessage,
      listener: (context, state) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(state.errorMessage!)));
      },
      builder: (context, state) {
        final cubit = context.read<NotificationsCubit>();
        return Scaffold(
          appBar: AppBar(
            title: const Text('Notifications'),
            actions: [
              TextButton(
                onPressed: state.unreadCount == 0 ? null : cubit.markAllRead,
                child: const Text('Mark all read'),
              ),
            ],
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Row(
                  children: [
                    ChoiceChip(
                      label: const Text('All'),
                      selected: !state.unreadOnly,
                      onSelected: (_) => cubit.setUnreadOnly(false),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: Text('Unread (${state.unreadCount})'),
                      selected: state.unreadOnly,
                      onSelected: (_) => cubit.setUnreadOnly(true),
                    ),
                  ],
                ),
              ),
              Expanded(child: _body(context, state, cubit)),
            ],
          ),
        );
      },
    );
  }

  Widget _body(
    BuildContext context,
    NotificationsState state,
    NotificationsCubit cubit,
  ) {
    switch (state.status) {
      case NotificationsStatus.initial:
      case NotificationsStatus.loading:
        return const LoadingView();
      case NotificationsStatus.failure:
        return ErrorView(
          message: state.errorMessage ?? 'Something went wrong.',
          onRetry: cubit.start,
        );
      case NotificationsStatus.loaded:
        final items = state.visible;
        if (items.isEmpty) {
          return EmptyView(
            message: state.unreadOnly
                ? "You're all caught up."
                : 'No notifications yet.',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            final n = items[i];
            return Dismissible(
              key: ValueKey(n.id),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.error,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.delete_outline, color: Colors.white),
              ),
              onDismissed: (_) => cubit.delete(n.id),
              child: NotificationTile(
                notification: n,
                onTap: () {
                  if (!n.isRead) cubit.markRead(n.id);
                  if (n.gigId != null) {
                    context.push(AppRoutes.gigDetail(n.gigId!));
                  }
                },
              ),
            );
          },
        );
    }
  }
}