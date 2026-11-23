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
import 'package:nextgig/features/messages/presentation/widgets/start_chat.dart';

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
            child: isPoster
                ? AppButton(
                    label: 'Review applicants',
                    onPressed: () => _openApplicants(context),
                  )
                : mineApplication == null
                ? Row(
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
                : Row(
                    children: [
                      Expanded(
                        child: Text(_statusLabel(mineApplication.status)),
                      ),
                      TextButton(
                        onPressed: () => context.go(AppRoutes.gigs),
                        child: const Text('View in Gigs'),
                      ),
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
    } catch (_) {}
  }

  void _openApplicants(BuildContext context) {
    final cubit = context.read<GigApplicationsCubit>();
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => BlocProvider<GigApplicationsCubit>.value(
        value: cubit,
        child: _ApplicantsSheet(gig: gig, host: context),
      ),
    );
  }
}

String _statusLabel(ApplicationStatus status) {
  final name = status.name;
  return name[0].toUpperCase() + name.substring(1);
}

class _ApplicantsSheet extends StatelessWidget {
  const _ApplicantsSheet({required this.gig, required this.host});

  final Gig gig;

  /// Context under the gig screen, still mounted after this sheet closes.
  final BuildContext host;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: BlocBuilder<GigApplicationsCubit, GigApplicationsState>(
        builder: (context, state) {
          final applications = state.applications;
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Applicants',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                if (applications.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Text('No applications yet.'),
                  )
                else
                  for (final application in applications)
                    _ApplicantRow(
                      gig: gig,
                      application: application,
                      host: host,
                    ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ApplicantRow extends StatelessWidget {
  const _ApplicantRow({
    required this.gig,
    required this.application,
    required this.host,
  });

  final Gig gig;
  final GigApplication application;
  final BuildContext host;

  void _closeAnd(BuildContext sheetContext, VoidCallback action) {
    Navigator.of(sheetContext).pop();
    // Pushing in the same frame as the sheet pop reuses a route key.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!host.mounted) return;
      action();
    });
  }

  @override
  Widget build(BuildContext context) {
    final name = application.applicantName.isEmpty
        ? 'Applicant'
        : application.applicantName;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _closeAnd(
                    context,
                    () => host.push(AppRoutes.user(application.applicantId)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      name,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Message',
                onPressed: () => _closeAnd(
                  context,
                  () => startChat(
                    host,
                    otherUid: application.applicantId,
                    otherName: name,
                    gigId: gig.id,
                    gigTitle: gig.title,
                  ),
                ),
                icon: const Icon(Icons.chat_bubble_outline),
              ),
            ],
          ),
          DropdownButton<ApplicationStatus>(
            value: application.status,
            isExpanded: true,
            items: [
              for (final status in ApplicationStatus.values)
                DropdownMenuItem(
                  value: status,
                  child: Text(_statusLabel(status)),
                ),
            ],
            onChanged: (status) {
              if (status == null || status == application.status) return;
              _setStatus(context, status);
            },
          ),
          if (application.status == ApplicationStatus.completed)
            TextButton(
              onPressed: () => _review(context),
              child: const Text('Leave a review'),
            ),
        ],
      ),
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
