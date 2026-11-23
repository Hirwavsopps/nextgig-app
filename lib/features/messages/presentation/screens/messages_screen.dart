import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:nextgig/core/di/injection.dart';
import 'package:nextgig/core/l10n/app_strings.dart';
import 'package:nextgig/core/router/app_routes.dart';
import 'package:nextgig/core/settings/settings_cubit.dart';
import 'package:nextgig/core/utils/messenger.dart';
import 'package:nextgig/core/widgets/empty_view.dart';
import 'package:nextgig/core/widgets/error_view.dart';
import 'package:nextgig/core/widgets/loading_view.dart';
import 'package:nextgig/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:nextgig/features/messages/presentation/cubit/inbox_cubit.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = context.watch<AuthCubit>().state.user?.uid;
    if (uid == null) return const SizedBox.shrink();
    return BlocProvider(
      create: (_) => sl<InboxCubit>()..watch(uid),
      child: _InboxView(uid: uid),
    );
  }
}

class _InboxView extends StatelessWidget {
  const _InboxView({required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context) {
    final title = AppStrings.text(
      context.watch<SettingsCubit>().state.language,
      'nav_messages',
    );
    return BlocConsumer<InboxCubit, InboxState>(
      listener: (context, state) {
        if (state.error != null) showAppMessage(context, state.error!);
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(title: Text(title)),
          body: _body(context, state),
        );
      },
    );
  }

  Widget _body(BuildContext context, InboxState state) {
    if (!state.loaded && state.error == null) return const LoadingView();
    if (state.error != null && state.conversations.isEmpty) {
      return ErrorView(
        message: state.error!,
        onRetry: () => context.read<InboxCubit>().watch(uid),
      );
    }
    if (state.conversations.isEmpty) {
      return const EmptyView(message: 'No messages yet.');
    }
    return ListView.separated(
      itemCount: state.conversations.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final conversation = state.conversations[index];
        final other = conversation.otherId(uid);
        return ListTile(
          title: Text(conversation.nameFor(other)),
          subtitle: Text(
            conversation.lastText.isEmpty
                ? 'No messages yet'
                : conversation.lastText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          onTap: () => context.push(AppRoutes.message(conversation.id)),
        );
      },
    );
  }
}
