import 'package:material_ui/material_ui.dart';
import 'package:nextgig/core/theme/app_theme.dart';
import 'package:nextgig/core/utils/category_icons.dart';
import 'package:nextgig/core/utils/formatters.dart';
import 'package:nextgig/core/widgets/gig_image.dart';
import 'package:nextgig/core/widgets/mentor_tile.dart';
import 'package:nextgig/core/widgets/pill.dart';
import 'package:nextgig/core/widgets/skill_chip.dart';
import 'package:nextgig/features/gigs/domain/entities/gig.dart';

/// Gig card from the Figma "Curated Opportunities" list. Reusable for
/// saved gigs, my postings, and so on.
class GigCard extends StatelessWidget {
  const GigCard({
    super.key,
    required this.gig,
    required this.isBookmarked,
    required this.onTap,
    required this.onBookmarkTap,
  });

  final Gig gig;
  final bool isBookmarked;
  final VoidCallback onTap;
  final VoidCallback onBookmarkTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final secondary = theme.textTheme.bodySmall?.copyWith(
      color: scheme.onSurfaceVariant,
    );
    final createdAt = gig.createdAt;
    final mentor = gig.mentorName;
    final applicants =
        '${gig.applicantCount} ${gig.applicantCount == 1 ? 'applicant' : 'applicants'}';
    final meta = createdAt == null
        ? applicants
        : 'Posted ${timeAgo(createdAt)} \u2022 $applicants';

    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(AppRadii.card),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.card),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.card),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    height: 36,
                    width: 36,
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(categoryIcon(gig.category), size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      gig.category.toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        letterSpacing: 0.8,
                        fontWeight: FontWeight.w700,
                        color: scheme.secondary,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: isBookmarked ? 'Remove bookmark' : 'Bookmark gig',
                    onPressed: onBookmarkTap,
                    icon: Icon(
                      isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                gig.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 14,
                runSpacing: 4,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.storefront_outlined, size: 14),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          gig.posterName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: secondary,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.place_outlined, size: 14),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          'Kigali, ${gig.neighborhood}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: secondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _GigImage(gig: gig),
              const SizedBox(height: 12),
              Text(
                formatRwf(gig.pay),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: scheme.secondary,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  const Pill(label: 'Fixed price', outlined: true),
                  if (gig.escrowFunded)
                    const Pill(
                      label: 'Verified escrow',
                      icon: Icons.verified_outlined,
                      outlined: true,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(meta, style: secondary),
              if (mentor != null) ...[
                const SizedBox(height: 12),
                MentorTile(name: mentor),
              ],
              if (gig.requiredSkills.isNotEmpty) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text('Skills:', style: secondary),
                          for (final skill in gig.requiredSkills.take(3))
                            SkillChip(label: skill),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'View gig',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward, size: 14),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _GigImage extends StatelessWidget {
  const _GigImage({required this.gig});

  final Gig gig;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          fit: StackFit.expand,
          children: [
            GigImage(gig: gig),
            if (gig.escrowFunded)
              const Positioned(
                left: 10,
                bottom: 10,
                child: Pill(
                  label: 'Escrow funded',
                  icon: Icons.lock_outline,
                  filled: true,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
