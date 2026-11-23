import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:nextgig/core/di/injection.dart';
import 'package:nextgig/core/l10n/app_strings.dart';
import 'package:nextgig/core/router/app_routes.dart';
import 'package:nextgig/core/settings/settings_cubit.dart';
import 'package:nextgig/core/utils/formatters.dart';
import 'package:nextgig/core/utils/messenger.dart';
import 'package:nextgig/core/widgets/app_button.dart';
import 'package:nextgig/features/applications/domain/entities/gig_application.dart';
import 'package:nextgig/features/applications/presentation/cubit/gig_applications_cubit.dart';
import 'package:nextgig/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:nextgig/features/gigs/domain/entities/gig.dart';

class GigApplyBar extends StatelessWidget {
  const GigApplyBar({super.key, required this.gig});

  final Gig gig;

  @override
  Widget build(BuildContext context) {
    final uid = context.read<AuthCubit>().state.user?.uid;
    if (uid == null) return const SizedBox.shrink();
    return BlocProvider(
      create: (_) =>
          sl<GigApplicationsCubit>()
            ..watch(gig.id, viewerId: uid, viewerIsPoster: gig.posterId == uid),
      child: _ApplyBody(gig: gig, uid: uid),
    );
  }
}

class _ApplyBody extends StatelessWidget {
  const _ApplyBody({required this.gig, required this.uid});

  final Gig gig;
  final String uid;

  @override
  Widget build(BuildContext context) {
    final language = context.watch<SettingsCubit>().state.language;
    final scheme = Theme.of(context).colorScheme;
    return BlocConsumer<GigApplicationsCubit, GigApplicationsState>(
      listener: (context, state) {
        if (state.error != null) showAppMessage(context, state.error!);
      },
      builder: (context, state) {
        final mine = state.applications.where(
          (item) => item.applicantId == uid,
        );
        final mineApplication = mine.isEmpty ? null : mine.first;
        final isPoster = gig.posterId == uid;
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: BoxDecoration(
              color: scheme.surface,
              border: Border(top: BorderSide(color: scheme.outlineVariant)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isPoster)
                  for (final application in state.applications)
                    _PosterRow(gig: gig, application: application)
                else if (mineApplication == null)
                  Row(
                    children: [
                      Text(
                        formatRwf(gig.pay),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: AppButton(
                          label: AppStrings.text(language, 'apply'),
                          onPressed: () => _apply(context),
                        ),
                      ),
                    ],
                  )
                else
                  _SeekerStatus(gig: gig, application: mineApplication),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _apply(BuildContext context) async {
    final user = context.read<AuthCubit>().state.user;
    if (user == null) return;
    try {
      await context.read<GigApplicationsCubit>().apply(
        gigId: gig.id,
        gigTitle: gig.title,
        applicantId: user.uid,
        applicantName: user.name.isEmpty ? user.email : user.name,
        posterId: gig.posterId,
      );
      if (context.mounted) showAppMessage(context, 'Application sent.');
    } catch (_) {}
  }
}

class _SeekerStatus extends StatelessWidget {
  const _SeekerStatus({required this.gig, required this.application});

  final Gig gig;
  final GigApplication application;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Status: ${application.status.name}'),
        if (application.status == ApplicationStatus.completed) ...[
          const SizedBox(height: 8),
          AppButton(
            label: AppStrings.text(
              context.watch<SettingsCubit>().state.language,
              'record_earnings',
            ),
            onPressed: () => context.push(
              '${AppRoutes.earnings}?gigTitle=${Uri.encodeComponent(gig.title)}&gigId=${gig.id}',
            ),
          ),
        ],
      ],
    );
  }
}

class _PosterRow extends StatelessWidget {
  const _PosterRow({required this.gig, required this.application});

  final Gig gig;
  final GigApplication application;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${application.applicantName} · ${application.status.name}'),
        Wrap(
          spacing: 4,
          children: [
            for (final status in ApplicationStatus.values)
              TextButton(
                onPressed: status == application.status
                    ? null
                    : () => _setStatus(context, status),
                child: Text(status.name),
              ),
          ],
        ),
        if (application.status == ApplicationStatus.completed)
          TextButton(
            onPressed: () => _review(context),
            child: const Text('Leave a review'),
          ),
      ],
    );
  }

  Future<void> _setStatus(
    BuildContext context,
    ApplicationStatus status,
  ) async {
    try {
      await context.read<GigApplicationsCubit>().setStatus(
        application.id,
        status,
      );
      if (context.mounted) showAppMessage(context, 'Status updated.');
    } catch (_) {}
  }

  Future<void> _review(BuildContext context) async {
    var rating = 5;
    final comment = TextEditingController();
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Review'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<int>(
              initialValue: rating,
              items: [
                for (var value = 1; value <= 5; value++)
                  DropdownMenuItem(value: value, child: Text('$value')),
              ],
              onChanged: (value) {
                if (value != null) rating = value;
              },
            ),
            TextField(
              controller: comment,
              decoration: const InputDecoration(labelText: 'Comment'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (saved != true || !context.mounted) {
      comment.dispose();
      return;
    }
    final me = context.read<AuthCubit>().state.user;
    if (me == null) {
      comment.dispose();
      return;
    }
    try {
      await context.read<GigApplicationsCubit>().review(
        applicationId: application.id,
        gigId: gig.id,
        reviewerId: me.uid,
        revieweeId: application.applicantId,
        rating: rating,
        comment: comment.text,
      );
      if (context.mounted) showAppMessage(context, 'Review saved.');
    } catch (_) {}
    comment.dispose();
  }
}
