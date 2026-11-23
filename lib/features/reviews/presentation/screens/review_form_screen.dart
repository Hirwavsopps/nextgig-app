import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:nextgig/core/router/app_routes.dart';
import 'package:nextgig/core/utils/messenger.dart';
import 'package:nextgig/core/widgets/app_button.dart';
import 'package:nextgig/core/widgets/loading_view.dart';
import 'package:nextgig/features/applications/domain/entities/gig_application.dart';
import 'package:nextgig/features/reviews/domain/usecases/review_usecases.dart';
import 'package:nextgig/features/reviews/presentation/cubit/review_form_cubit.dart';
import 'package:nextgig/features/reviews/presentation/widgets/profile_reviews_section.dart';
import 'package:nextgig/features/reviews/presentation/widgets/star_rating.dart';

/// The client rates the talent they hired for a completed gig.
/// Expects a [ReviewFormCubit].
class ReviewFormScreen extends StatefulWidget {
  const ReviewFormScreen({super.key, required this.application});

  final GigApplication application;

  @override
  State<ReviewFormScreen> createState() => _ReviewFormScreenState();
}

class _ReviewFormScreenState extends State<ReviewFormScreen> {
  final _comment = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final application = widget.application;
    final name = application.applicantName.isEmpty
        ? 'the talent'
        : application.applicantName;
    return BlocConsumer<ReviewFormCubit, ReviewFormState>(
      listenWhen: (previous, current) =>
          (current.error != null && current.error != previous.error) ||
          (current.submitted && !previous.submitted),
      listener: (context, state) {
        if (state.error != null) showAppMessage(context, state.error!);
        if (state.submitted) {
          showAppMessage(
            context,
            'Thanks! Your review is on $name\'s profile.',
          );
          context.pop();
        }
      },
      builder: (context, state) {
        final cubit = context.read<ReviewFormCubit>();
        return Scaffold(
          appBar: AppBar(title: const Text('Review')),
          body: state.loading
              ? const LoadingView()
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Card(
                      child: ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.person_outline),
                        ),
                        title: Text(name),
                        subtitle: Text(
                          application.gigTitle.isEmpty
                              ? 'Completed gig'
                              : application.gigTitle,
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push(
                          AppRoutes.user(application.applicantId),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (state.existing != null) ...[
                      Text('Your review', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 8),
                      ReviewCard(review: state.existing!),
                    ] else if (state.eligibility != ReviewEligibility.eligible)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline),
                              const SizedBox(width: 12),
                              Expanded(child: Text(state.eligibility.message)),
                            ],
                          ),
                        ),
                      )
                    else
                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'How did $name do?',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            StarRatingInput(
                              rating: state.rating,
                              onChanged: state.canEdit ? cubit.setRating : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              key: const ValueKey('review-comment'),
                              controller: _comment,
                              enabled: state.canEdit,
                              maxLines: 4,
                              maxLength: ReviewPolicy.maxComment,
                              decoration: const InputDecoration(
                                labelText: 'Your review',
                                hintText:
                                    'Quality, communication, meeting the '
                                    'deadline…',
                                alignLabelWithHint: true,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(12),
                                  ),
                                ),
                              ),
                              validator: (value) =>
                                  ReviewPolicy.validateComment(value ?? ''),
                            ),
                            const SizedBox(height: 8),
                            AppButton(
                              label: 'Submit review',
                              isLoading: state.submitting,
                              onPressed: state.rating == 0
                                  ? null
                                  : () {
                                      if (_formKey.currentState?.validate() ??
                                          false) {
                                        cubit.submit(_comment.text);
                                      }
                                    },
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Reviews are public and cannot be edited later.',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
        );
      },
    );
  }
}
