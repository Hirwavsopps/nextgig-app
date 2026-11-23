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
import 'package:nextgig/features/messages/presentation/open_thread.dart';
import 'package:nextgig/features/mentorship/presentation/cubit/mentors_cubit.dart';

class MentorsScreen extends StatelessWidget {
  const MentorsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<MentorsCubit>()..watch(),
      child: const _MentorsView(),
    );
  }
}

class _MentorsView extends StatelessWidget {
  const _MentorsView();

  @override
  Widget build(BuildContext context) {
    final title = AppStrings.text(
      context.watch<SettingsCubit>().state.language,
      'nav_mentors',
    );
    return BlocConsumer<MentorsCubit, MentorsState>(
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

  Widget _body(BuildContext context, MentorsState state) {
    if (!state.loaded && state.error == null) return const LoadingView();
    if (state.error != null && state.mentors.isEmpty) {
      return ErrorView(
        message: state.error!,
        onRetry: () => context.read<MentorsCubit>().watch(),
      );
    }
    if (state.mentors.isEmpty) {
      return const EmptyView(
        message: 'No mentors yet.',
        icon: Icons.school_outlined,
      );
    }
    return ListView.separated(
      itemCount: state.mentors.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final mentor = state.mentors[index];
        return ListTile(
          title: Text(mentor.name.isEmpty ? 'Mentor' : mentor.name),
          subtitle: Text(
            mentor.bio.isEmpty ? 'Mentor' : mentor.bio,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          onTap: () => context.push(AppRoutes.user(mentor.uid)),
          trailing: IconButton(
            tooltip: 'Message',
            onPressed: () => openThread(
              context,
              otherId: mentor.uid,
              otherName: mentor.name.isEmpty ? 'Mentor' : mentor.name,
            ),
            icon: const Icon(Icons.chat_bubble_outline),
          ),
        );
      },
    );
  }
}
