import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:nextgig/core/router/app_routes.dart';
import 'package:nextgig/core/theme/app_theme.dart';
import 'package:nextgig/core/widgets/empty_view.dart';
import 'package:nextgig/core/widgets/loading_view.dart';
import 'package:nextgig/features/profile/domain/entities/skill.dart';
import 'package:nextgig/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:nextgig/features/verification/domain/entities/verification_status.dart';
import 'package:nextgig/features/verification/presentation/widgets/verification_badge.dart';
import 'package:nextgig/features/verification/presentation/widgets/verification_widgets.dart';

/// The signed-in user's skills with their verification status. Expects a
/// [ProfileCubit] watching the user's own profile.
class SkillVerificationScreen extends StatelessWidget {
  const SkillVerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Skill verification')),
      body: BlocBuilder<ProfileCubit, ProfileState>(
        builder: (context, state) {
          if (state.profile == null && state.error == null) {
            return const LoadingView();
          }
          final skills = state.skills;
          if (skills.isEmpty) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const EmptyView(
                  icon: Icons.workspace_premium_outlined,
                  message:
                      'Add a skill to your profile, then upload a certificate '
                      'or portfolio piece to get it verified.',
                ),
                FilledButton.icon(
                  onPressed: () => context.push(AppRoutes.skillForm),
                  icon: const Icon(Icons.add),
                  label: const Text('Add a skill'),
                ),
              ],
            );
          }
          final verified = skills.where((s) => s.isVerified).length;
          final pending = skills
              .where((s) => s.status == VerificationStatus.pending)
              .length;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _Summary(
                total: skills.length,
                verified: verified,
                pending: pending,
              ),
              const SizedBox(height: 16),
              for (final skill in skills) _SkillCard(skill: skill),
            ],
          );
        },
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({
    required this.total,
    required this.verified,
    required this.pending,
  });

  final int total;
  final int verified;
  final int pending;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$verified of $total skills verified',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: total == 0 ? 0 : verified / total,
                minHeight: 8,
                color: VerificationStyle.of(
                  context,
                  VerificationStatus.verified,
                ).foreground,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              pending > 0
                  ? '$pending waiting for a mentor, lecturer or past client.'
                  : 'Verified skills stand out to clients and rank your gig '
                        'matches higher.',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _SkillCard extends StatelessWidget {
  const _SkillCard({required this.skill});

  final Skill skill;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final action = switch (skill.status) {
      VerificationStatus.unverified => 'Verify',
      VerificationStatus.rejected => 'Resubmit',
      _ => 'Details',
    };
    void open() => context.push(AppRoutes.verificationSkill(skill.id));
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.card),
        onTap: open,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(skill.name, style: theme.textTheme.titleSmall),
                        VerificationBadge(status: skill.status),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _capitalize(skill.proficiency),
                      style: theme.textTheme.bodySmall,
                    ),
                    if (skill.isVerified) ...[
                      const SizedBox(height: 4),
                      VerifiedByLine(skill: skill),
                    ],
                  ],
                ),
              ),
              TextButton(onPressed: open, child: Text(action)),
            ],
          ),
        ),
      ),
    );
  }
}

String _capitalize(String value) =>
    value.isEmpty ? value : value[0].toUpperCase() + value.substring(1);
