import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:nextgig/core/router/app_routes.dart';
import 'package:nextgig/core/theme/app_theme.dart';
import 'package:nextgig/core/utils/formatters.dart';
import 'package:nextgig/core/widgets/brand_logo.dart';
import 'package:nextgig/core/widgets/gig_image.dart';
import 'package:nextgig/core/widgets/mentor_tile.dart';
import 'package:nextgig/core/widgets/pill.dart';
import 'package:nextgig/core/widgets/skill_chip.dart';
import 'package:nextgig/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:nextgig/features/gigs/domain/entities/gig.dart';
import 'package:nextgig/features/messages/presentation/widgets/start_chat.dart';
import 'package:nextgig/features/gigs/presentation/cubit/bookmarks_cubit.dart';
import 'package:nextgig/features/gigs/presentation/widgets/gig_apply_bar.dart';

/// Gig Detail: the Figma "Gig Detail" screen. The Apply button is wired up
/// by the applications feature (member 5).
class GigDetailScreen extends StatelessWidget {
  const GigDetailScreen({super.key, required this.gig});

  final Gig gig;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mentor = gig.mentorName;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            BrandLogo(size: 28),
            SizedBox(width: 8),
            Text('Gig Detail'),
          ],
        ),
        actions: [
          BlocBuilder<BookmarksCubit, Set<String>>(
            builder: (context, saved) {
              final isSaved = saved.contains(gig.id);
              return IconButton(
                tooltip: isSaved ? 'Remove bookmark' : 'Bookmark gig',
                onPressed: () => context.read<BookmarksCubit>().toggle(gig.id),
                icon: Icon(isSaved ? Icons.bookmark : Icons.bookmark_border),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Pill(label: 'Open gig', dot: true),
            const SizedBox(height: 12),
            Text(
              gig.title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                GestureDetector(
                  onTap: () => context.push(AppRoutes.user(gig.posterId)),
                  child: Text(
                    gig.posterName,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (gig.verifiedClient)
                  const Pill(
                    label: 'Verified client',
                    icon: Icons.verified_outlined,
                    outlined: true,
                  ),
              ],
            ),
            if (gig.posterId.isNotEmpty &&
                gig.posterId != context.read<AuthCubit>().state.user?.uid) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: () => startChat(
                    context,
                    otherUid: gig.posterId,
                    otherName: gig.posterName,
                    gigId: gig.id,
                    gigTitle: gig.title,
                  ),
                  icon: const Icon(Icons.chat_bubble_outline, size: 18),
                  label: const Text('Message client'),
                ),
              ),
            ],
            const SizedBox(height: 14),
            _InfoRow(
              icon: Icons.place_outlined,
              text: 'Kigali, ${gig.neighborhood}',
            ),
            if (gig.deadline != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: _InfoRow(
                  icon: Icons.event,
                  text:
                      'Deadline ${gig.deadline!.year}-${gig.deadline!.month}-${gig.deadline!.day}',
                ),
              ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadii.control),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: GigImage(gig: gig),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _StatTile(
                    label: 'Payout',
                    value: formatRwfCompact(gig.pay),
                    note: gig.escrowFunded ? 'Escrow protected' : 'Fixed price',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatTile(
                    label: 'Duration',
                    value: gig.duration.isEmpty ? 'Flexible' : gig.duration,
                    note: 'Agreed with poster',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatTile(
                    label: 'Level',
                    value: gig.level.isEmpty ? 'Any' : gig.level,
                    note: mentor != null ? 'Mentorship incl.' : 'Open to all',
                  ),
                ),
              ],
            ),
            const _SectionTitle('About the project'),
            Text(gig.description, style: theme.textTheme.bodyLarge),
            if (gig.deliverables.isNotEmpty) ...[
              const _SectionTitle('Key deliverables'),
              for (final item in gig.deliverables) _Deliverable(text: item),
            ],
            if (gig.requiredSkills.isNotEmpty) ...[
              const _SectionTitle('Required skills'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final skill in gig.requiredSkills)
                    SkillChip(label: skill),
                ],
              ),
            ],
            if (mentor != null) ...[
              const _SectionTitle('Mentorship partner'),
              MentorTile(name: mentor, caption: 'Included 1-on-1'),
            ],
          ],
        ),
      ),
      bottomNavigationBar: GigApplyBar(gig: gig),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 10),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium
            ?.copyWith(fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.note,
  });

  final String label;
  final String value;
  final String note;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              letterSpacing: 0.6,
              fontWeight: FontWeight.w700,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            note,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _Deliverable extends StatelessWidget {
  const _Deliverable({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, size: 20, color: scheme.primary),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
