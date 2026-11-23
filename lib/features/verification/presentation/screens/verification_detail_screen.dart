import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:nextgig/core/router/app_routes.dart';
import 'package:nextgig/core/utils/formatters.dart';
import 'package:nextgig/core/utils/messenger.dart';
import 'package:nextgig/core/widgets/app_button.dart';
import 'package:nextgig/core/widgets/empty_view.dart';
import 'package:nextgig/core/widgets/loading_view.dart';
import 'package:nextgig/features/profile/domain/entities/skill.dart';
import 'package:nextgig/features/verification/domain/entities/verification_request.dart';
import 'package:nextgig/features/verification/domain/entities/verification_status.dart';
import 'package:nextgig/features/verification/presentation/cubit/skill_verification_cubit.dart';
import 'package:nextgig/features/verification/presentation/widgets/verification_badge.dart';
import 'package:nextgig/features/verification/presentation/widgets/verification_widgets.dart';

/// Status of one of the user's skills, the reviewer's feedback, and every
/// submission sent for it. Expects a [SkillVerificationCubit].
class VerificationDetailScreen extends StatelessWidget {
  const VerificationDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SkillVerificationCubit, SkillVerificationState>(
      listenWhen: (previous, current) =>
          current.error != null && previous.error != current.error,
      listener: (context, state) => showAppMessage(context, state.error!),
      builder: (context, state) {
        final skill = state.skill;
        return Scaffold(
          appBar: AppBar(title: Text(skill?.name ?? 'Skill verification')),
          body: state.loading
              ? const LoadingView()
              : skill == null
              ? const EmptyView(message: 'This skill was removed.')
              : _Body(skill: skill, requests: state.requests),
        );
      },
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.skill, required this.requests});

  final Skill skill;
  final List<VerificationRequest> requests;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final latest = requests.isEmpty ? null : requests.first;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _StatusPanel(skill: skill, latest: latest),
        if (skill.status.canSubmitEvidence) ...[
          const SizedBox(height: 16),
          AppButton(
            label: skill.status == VerificationStatus.rejected
                ? 'Submit new evidence'
                : 'Upload evidence',
            onPressed: () => context.push(
              AppRoutes.verificationUpload(skill.id),
              extra: skill,
            ),
          ),
        ],
        const SizedBox(height: 24),
        Text('Submissions', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        if (requests.isEmpty)
          Text(
            'Nothing sent yet. Certificates, course completions and '
            'portfolio screenshots all work.',
            style: theme.textTheme.bodySmall,
          )
        else
          for (final request in requests)
            VerificationRequestCard(
              request: request,
              onTap: () => _showSubmission(context, request),
            ),
      ],
    );
  }

  void _showSubmission(BuildContext context, VerificationRequest request) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: SubmissionDetails(request: request),
        ),
      ),
    );
  }
}

class _StatusPanel extends StatelessWidget {
  const _StatusPanel({required this.skill, required this.latest});

  final Skill skill;
  final VerificationRequest? latest;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = VerificationStyle.of(context, skill.status);
    final submitted = latest?.submittedAt;
    final explanation = switch (skill.status) {
      VerificationStatus.unverified =>
        'Upload a certificate or portfolio proof. A mentor, lecturer or past '
            'client will review it.',
      VerificationStatus.pending =>
        'Your evidence is with the reviewers'
            '${submitted != null ? ' since ${formatDate(submitted)}' : ''}. '
            'You will get a notification when they decide.',
      VerificationStatus.verified =>
        'This skill shows a verified badge on your profile.',
      VerificationStatus.rejected =>
        'A reviewer could not verify this skill yet. Read their feedback and '
            'send new evidence.',
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: style.background(context),
                  child: Icon(style.icon, color: style.foreground),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(skill.name, style: theme.textTheme.titleMedium),
                      Text(skill.proficiency, style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
                VerificationBadge(status: skill.status),
              ],
            ),
            const SizedBox(height: 12),
            Text(explanation, style: theme.textTheme.bodyMedium),
            if (skill.isVerified) ...[
              const SizedBox(height: 8),
              VerifiedByLine(skill: skill),
            ],
            if (skill.status == VerificationStatus.rejected &&
                latest != null &&
                latest!.reviewerComment.isNotEmpty) ...[
              const SizedBox(height: 12),
              ReviewerComment(request: latest!),
            ],
          ],
        ),
      ),
    );
  }
}

/// Everything recorded for one submission. Also used by reviewers.
class SubmissionDetails extends StatelessWidget {
  const SubmissionDetails({super.key, required this.request});

  final VerificationRequest request;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final submitted = request.submittedAt;
    final reviewed = request.reviewedAt;
    Widget row(String label, String value) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: theme.textTheme.bodySmall),
          ),
          Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                request.skillName,
                style: theme.textTheme.titleMedium,
              ),
            ),
            VerificationBadge(status: request.status),
          ],
        ),
        const SizedBox(height: 12),
        EvidencePreview(request: request),
        const SizedBox(height: 16),
        row('Evidence', request.evidenceType.label),
        row('File', request.evidenceFileName),
        if (submitted != null) row('Submitted', formatDate(submitted)),
        if (request.note.isNotEmpty) row('Note', request.note),
        if (reviewed != null) row('Reviewed', formatDate(reviewed)),
        if (request.reviewerComment.isNotEmpty) ...[
          const SizedBox(height: 4),
          ReviewerComment(request: request),
        ],
      ],
    );
  }
}
