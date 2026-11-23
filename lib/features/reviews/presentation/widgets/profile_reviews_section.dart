import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:nextgig/core/router/app_routes.dart';
import 'package:nextgig/core/theme/app_colors.dart';
import 'package:nextgig/core/utils/formatters.dart';
import 'package:nextgig/features/reviews/domain/entities/rating_summary.dart';
import 'package:nextgig/features/reviews/domain/entities/review.dart';
import 'package:nextgig/features/reviews/presentation/widgets/star_rating.dart';

/// Average rating, star breakdown and the latest reviews on a profile.
class ProfileReviewsSection extends StatelessWidget {
  const ProfileReviewsSection({
    super.key,
    required this.title,
    required this.reviews,
    this.initiallyShown = 3,
  });

  final String title;
  final List<Review> reviews;
  final int initiallyShown;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final summary = RatingSummary.fromReviews(reviews);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        if (summary.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.rate_review_outlined),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'No reviews yet. Clients can review after a gig is '
                      'completed.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          )
        else ...[
          RatingSummaryCard(summary: summary),
          const SizedBox(height: 8),
          for (final review in reviews.take(initiallyShown))
            ReviewCard(review: review),
          if (reviews.length > initiallyShown)
            TextButton(
              onPressed: () => _showAll(context),
              child: Text('See all ${reviews.length} reviews'),
            ),
        ],
      ],
    );
  }

  void _showAll(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        builder: (context, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [for (final review in reviews) ReviewCard(review: review)],
        ),
      ),
    );
  }
}

class RatingSummaryCard extends StatelessWidget {
  const RatingSummaryCard({super.key, required this.summary});

  final RatingSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Column(
              children: [
                Text(
                  summary.averageLabel,
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                StarRating(rating: summary.average),
                const SizedBox(height: 4),
                Text(
                  '${summary.count} review${summary.count == 1 ? '' : 's'}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                children: [
                  for (var stars = 5; stars >= 1; stars--)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 12,
                            child: Text(
                              '$stars',
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: summary.shareFor(stars),
                                minHeight: 6,
                                color: AppColors.accent,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          SizedBox(
                            width: 20,
                            child: Text(
                              '${summary.countFor(stars)}',
                              textAlign: TextAlign.end,
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ReviewCard extends StatelessWidget {
  const ReviewCard({super.key, required this.review});

  final Review review;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = review.reviewerName.isEmpty ? 'Client' : review.reviewerName;
    final created = review.createdAt;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: review.reviewerId.isEmpty
                        ? null
                        : () => context.push(AppRoutes.user(review.reviewerId)),
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall,
                    ),
                  ),
                ),
                StarRating(rating: review.rating.toDouble(), size: 14),
              ],
            ),
            if (created != null)
              Text(formatDate(created), style: theme.textTheme.bodySmall),
            const SizedBox(height: 6),
            Text(review.comment, style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
