import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:nextgig/core/di/injection.dart';
import 'package:nextgig/core/l10n/app_strings.dart';
import 'package:nextgig/core/router/app_routes.dart';
import 'package:nextgig/core/settings/settings_cubit.dart';
import 'package:nextgig/core/utils/messenger.dart';
import 'package:nextgig/core/widgets/user_avatar.dart';
import 'package:nextgig/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:nextgig/features/auth/presentation/widgets/account_section.dart';
import 'package:nextgig/features/profile/domain/entities/skill.dart';
import 'package:nextgig/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:nextgig/features/profile/presentation/widgets/cv_card.dart';
import 'package:nextgig/features/reviews/presentation/widgets/profile_reviews_section.dart';
import 'package:nextgig/features/verification/domain/entities/verification_status.dart';
import 'package:nextgig/features/verification/presentation/cubit/verification_queue_cubit.dart';
import 'package:nextgig/features/verification/presentation/widgets/verification_badge.dart';
import 'package:nextgig/features/verification/presentation/widgets/verification_widgets.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, this.uid});

  /// Null means the signed-in user's own profile.
  final String? uid;

  @override
  Widget build(BuildContext context) {
    final me = context.watch<AuthCubit>().state.user;
    final profileUid = uid ?? me?.uid;
    if (profileUid == null) return const SizedBox.shrink();
    final mine = profileUid == me?.uid;
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<ProfileCubit>()..watch(profileUid)),
        // Whether the viewer may endorse skills; drives the reviewer actions.
        if (me != null)
          BlocProvider(
            create: (_) => sl<VerificationQueueCubit>()..watch(me.uid),
          ),
      ],
      child: _ProfileView(uid: profileUid, mine: mine),
    );
  }
}

class _ProfileView extends StatelessWidget {
  const _ProfileView({required this.uid, required this.mine});

  final String uid;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    final language = context.watch<SettingsCubit>().state.language;
    String t(String key) => AppStrings.text(language, key);
    return BlocConsumer<ProfileCubit, ProfileState>(
      listener: (context, state) {
        if (state.error != null) showAppMessage(context, state.error!);
      },
      builder: (context, state) {
        final profile = state.profile;
        return Scaffold(
          appBar: AppBar(
            title: Text(t('nav_profile')),
            actions: [
              if (mine) ...[
                IconButton(
                  tooltip: 'Edit profile',
                  onPressed: profile == null
                      ? null
                      : () =>
                            context.push(AppRoutes.editProfile, extra: profile),
                  icon: const Icon(Icons.edit_outlined),
                ),
                IconButton(
                  tooltip: t('settings'),
                  onPressed: () => context.push(AppRoutes.settings),
                  icon: const Icon(Icons.settings_outlined),
                ),
              ],
            ],
          ),
          floatingActionButton: mine
              ? FloatingActionButton.extended(
                  onPressed: () => context.push(AppRoutes.skillForm),
                  icon: const Icon(Icons.add),
                  label: Text(t('skills')),
                )
              : null,
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (mine)
                AccountSection(
                  photoUrl: profile?.photoUrl ?? '',
                  displayName: profile?.name,
                )
              else
                ListTile(
                  leading: UserAvatar(
                    name: profile?.name ?? '',
                    photoUrl: profile?.photoUrl,
                  ),
                  title: Text(
                    profile?.name.isEmpty ?? true
                        ? 'NextGig user'
                        : profile!.name,
                  ),
                  subtitle: Text(profile?.bio ?? ''),
                ),
              if ((profile?.bio.isNotEmpty ?? false) && mine) ...[
                const SizedBox(height: 8),
                Text(profile!.bio),
              ],
              if (profile?.location.isNotEmpty ?? false) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.place_outlined, size: 18),
                    const SizedBox(width: 6),
                    Text('Kigali, ${profile!.location}'),
                  ],
                ),
              ],
              if (profile != null) ...[
                const SizedBox(height: 12),
                CvCard(profile: profile, mine: mine),
              ],
              const SizedBox(height: 16),
              const _ReviewerEntry(),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      t('skills'),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  if (mine && state.skills.isNotEmpty)
                    TextButton.icon(
                      onPressed: () => context.push(AppRoutes.verification),
                      icon: const Icon(Icons.verified_outlined, size: 18),
                      label: const Text('Verify skills'),
                    ),
                ],
              ),
              if (state.skills.isEmpty) const Text('No skills yet.'),
              for (final skill in state.skills)
                _SkillTile(skill: skill, uid: uid, mine: mine),
              const SizedBox(height: 16),
              ProfileReviewsSection(
                title: t('reviews'),
                reviews: state.reviews,
              ),
              if (mine) ...[
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () => context.push(AppRoutes.earnings),
                  child: Text(t('earnings')),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _SkillTile extends StatelessWidget {
  const _SkillTile({
    required this.skill,
    required this.uid,
    required this.mine,
  });

  final Skill skill;
  final String uid;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    final portfolio = [
      for (final item in skill.portfolio)
        if (item.title.trim().isNotEmpty ||
            item.imageUrl.isNotEmpty ||
            item.link.isNotEmpty)
          item,
    ];
    final proof = skill.proofUrl;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(skill.name),
              VerificationBadge(status: skill.status),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(skill.proficiency),
              if (skill.isVerified) VerifiedByLine(skill: skill),
            ],
          ),
          trailing: mine
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Verification',
                      onPressed: () =>
                          context.push(AppRoutes.verificationSkill(skill.id)),
                      icon: const Icon(Icons.verified_outlined),
                    ),
                    IconButton(
                      onPressed: () =>
                          context.push(AppRoutes.skillForm, extra: skill),
                      icon: const Icon(Icons.edit_outlined),
                    ),
                    IconButton(
                      onPressed: () => context.read<ProfileCubit>().deleteSkill(
                        uid,
                        skill.id,
                      ),
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ],
                )
              : _ReviewAction(skill: skill),
        ),
        for (final item in portfolio) ...[
          if (item.title.trim().isNotEmpty)
            Text(item.title, style: Theme.of(context).textTheme.bodyMedium),
          if (item.imageUrl.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  item.imageUrl,
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const Text('Could not load this image.'),
                ),
              ),
            ),
          if (item.link.isNotEmpty)
            TextButton(
              onPressed: () => _open(context, item.link),
              child: Text(
                item.link,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
        if (proof != null && proof.isNotEmpty)
          TextButton(
            onPressed: () => _open(context, proof),
            child: const Text('Proof document'),
          ),
      ],
    );
  }

  Future<void> _open(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null ||
        !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) showAppMessage(context, 'Could not open the file.');
    }
  }
}

/// Shown to authorized reviewers only: a shortcut to their queue.
class _ReviewerEntry extends StatelessWidget {
  const _ReviewerEntry();

  @override
  Widget build(BuildContext context) {
    final queue = context.watch<VerificationQueueCubit?>()?.state;
    if (queue == null || !queue.isReviewer) return const SizedBox.shrink();
    final waiting = queue.pending.length;
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: const Icon(Icons.fact_check_outlined),
        title: const Text('Endorsement queue'),
        subtitle: Text(
          waiting == 0
              ? 'No skills waiting for you'
              : '$waiting skill${waiting == 1 ? '' : 's'} waiting for review',
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push(AppRoutes.verificationQueue),
      ),
    );
  }
}

/// On someone else's profile, reviewers can open a pending skill's evidence.
class _ReviewAction extends StatelessWidget {
  const _ReviewAction({required this.skill});

  final Skill skill;

  @override
  Widget build(BuildContext context) {
    final queue = context.watch<VerificationQueueCubit?>()?.state;
    final requestId = skill.verificationId;
    if (queue == null ||
        !queue.isReviewer ||
        skill.status != VerificationStatus.pending ||
        requestId == null) {
      return const SizedBox.shrink();
    }
    return TextButton(
      onPressed: () => context.push(AppRoutes.verificationRequest(requestId)),
      child: const Text('Review'),
    );
  }
}
