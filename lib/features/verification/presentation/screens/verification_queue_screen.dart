import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:nextgig/core/router/app_routes.dart';
import 'package:nextgig/core/widgets/empty_view.dart';
import 'package:nextgig/core/widgets/error_view.dart';
import 'package:nextgig/core/widgets/loading_view.dart';
import 'package:nextgig/features/verification/domain/entities/verification_request.dart';
import 'package:nextgig/features/verification/presentation/cubit/verification_queue_cubit.dart';
import 'package:nextgig/features/verification/presentation/widgets/verification_widgets.dart';

/// Skills waiting for endorsement, for authorized reviewers. Expects a
/// [VerificationQueueCubit].
class VerificationQueueScreen extends StatelessWidget {
  const VerificationQueueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VerificationQueueCubit, VerificationQueueState>(
      builder: (context, state) {
        if (state.loading) {
          return Scaffold(
            appBar: AppBar(title: const Text('Endorsements')),
            body: const LoadingView(),
          );
        }
        if (!state.isReviewer) {
          return Scaffold(
            appBar: AppBar(title: const Text('Endorsements')),
            body: const EmptyView(
              icon: Icons.lock_outline,
              message:
                  'Only authorized mentors, lecturers and past clients can '
                  'endorse skills. Ask the NextGig team to add you as a '
                  'reviewer.',
            ),
          );
        }
        final reviewer = state.reviewer!;
        return DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Endorsements'),
              bottom: TabBar(
                tabs: [
                  Tab(text: 'Waiting (${state.pending.length})'),
                  const Tab(text: 'Reviewed'),
                ],
              ),
            ),
            body: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Row(
                    children: [
                      const Icon(Icons.badge_outlined, size: 18),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Reviewing as ${reviewer.name} · '
                          '${reviewer.relationshipLabel}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _RequestList(
                        requests: state.pending,
                        error: state.error,
                        empty: 'No skills are waiting for endorsement.',
                      ),
                      _RequestList(
                        requests: state.reviewed,
                        error: null,
                        empty: 'Skills you approve or reject appear here.',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _RequestList extends StatelessWidget {
  const _RequestList({
    required this.requests,
    required this.error,
    required this.empty,
  });

  final List<VerificationRequest> requests;
  final String? error;
  final String empty;

  @override
  Widget build(BuildContext context) {
    if (error != null && requests.isEmpty) return ErrorView(message: error!);
    if (requests.isEmpty) {
      return EmptyView(icon: Icons.task_alt_outlined, message: empty);
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final request = requests[index];
        return VerificationRequestCard(
          request: request,
          showOwner: true,
          onTap: () => context.push(AppRoutes.verificationRequest(request.id)),
        );
      },
    );
  }
}
