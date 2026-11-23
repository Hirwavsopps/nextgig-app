import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:nextgig/core/router/app_routes.dart';
import 'package:nextgig/core/utils/messenger.dart';
import 'package:nextgig/core/widgets/app_text_field.dart';
import 'package:nextgig/core/widgets/empty_view.dart';
import 'package:nextgig/core/widgets/loading_view.dart';
import 'package:nextgig/features/verification/domain/entities/verification_request.dart';
import 'package:nextgig/features/verification/domain/entities/verification_status.dart';
import 'package:nextgig/features/verification/domain/usecases/verification_usecases.dart';
import 'package:nextgig/features/verification/presentation/cubit/verification_decision_cubit.dart';
import 'package:nextgig/features/verification/presentation/screens/verification_detail_screen.dart';
import 'package:nextgig/features/verification/presentation/widgets/verification_badge.dart';

/// A reviewer opens one request, checks the evidence and approves or rejects
/// it with a comment. Expects a [VerificationDecisionCubit].
class ReviewRequestScreen extends StatefulWidget {
  const ReviewRequestScreen({super.key});

  @override
  State<ReviewRequestScreen> createState() => _ReviewRequestScreenState();
}

class _ReviewRequestScreenState extends State<ReviewRequestScreen> {
  final _comment = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<VerificationDecisionCubit, VerificationDecisionState>(
      listenWhen: (previous, current) =>
          (current.error != null && current.error != previous.error) ||
          (current.message != null && current.message != previous.message),
      listener: (context, state) {
        showAppMessage(context, state.error ?? state.message!);
      },
      builder: (context, state) {
        final request = state.request;
        return Scaffold(
          appBar: AppBar(title: const Text('Review evidence')),
          body: state.loading
              ? const LoadingView()
              : request == null
              ? EmptyView(
                  icon: Icons.lock_outline,
                  message: state.error ?? 'This request is not available.',
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _OwnerTile(request: request),
                    const SizedBox(height: 12),
                    SubmissionDetails(request: request),
                    const SizedBox(height: 20),
                    _decisionArea(context, state, request),
                  ],
                ),
        );
      },
    );
  }

  Widget _decisionArea(
    BuildContext context,
    VerificationDecisionState state,
    VerificationRequest request,
  ) {
    final blocked = state.blockReason;
    if (blocked != null) {
      // Decided requests already show the reviewer's comment above.
      if (!request.status.awaitingReview) return const SizedBox.shrink();
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              const Icon(Icons.info_outline),
              const SizedBox(width: 10),
              Expanded(child: Text(blocked)),
            ],
          ),
        ),
      );
    }
    final approve = VerificationStyle.of(context, VerificationStatus.verified);
    final reject = VerificationStyle.of(context, VerificationStatus.rejected);
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Your decision', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          AppTextField(
            controller: _comment,
            label:
                'Comment for ${request.userName.isEmpty ? 'the user' : request.userName}',
            hint: 'What convinced you, or what is missing?',
            maxLines: 3,
            validator: (value) {
              final text = value?.trim() ?? '';
              if (text.length < DecideVerification.minCommentLength) {
                return 'Add a short comment explaining your decision.';
              }
              if (text.length > DecideVerification.maxCommentLength) {
                return 'Keep it under ${DecideVerification.maxCommentLength} characters.';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: reject.foreground,
                    minimumSize: const Size.fromHeight(52),
                  ),
                  onPressed: state.submitting
                      ? null
                      : () => _decide(context, request, approve: false),
                  icon: const Icon(Icons.close),
                  label: const Text('Reject'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: approve.foreground,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(52),
                  ),
                  onPressed: state.submitting
                      ? null
                      : () => _decide(context, request, approve: true),
                  icon: state.submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.verified),
                  label: const Text('Endorse'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _decide(
    BuildContext context,
    VerificationRequest request, {
    required bool approve,
  }) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          approve ? 'Endorse ${request.skillName}?' : 'Reject this evidence?',
        ),
        content: Text(
          approve
              ? '${request.userName} will get a verified badge, signed with '
                    'your name. This cannot be undone.'
              : '${request.userName} will see your comment and can send new '
                    'evidence.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(approve ? 'Endorse' : 'Reject'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final saved = await context.read<VerificationDecisionCubit>().decide(
      approve: approve,
      comment: _comment.text,
    );
    if (saved) _comment.clear();
  }
}

class _OwnerTile extends StatelessWidget {
  const _OwnerTile({required this.request});

  final VerificationRequest request;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.person_outline)),
        title: Text(
          request.userName.isEmpty ? 'NextGig user' : request.userName,
        ),
        subtitle: const Text('View profile'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push(AppRoutes.user(request.userId)),
      ),
    );
  }
}
