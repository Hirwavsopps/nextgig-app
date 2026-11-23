import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:nextgig/core/di/injection.dart';
import 'package:nextgig/core/l10n/app_strings.dart';
import 'package:nextgig/core/router/app_routes.dart';
import 'package:nextgig/core/settings/settings_cubit.dart';
import 'package:nextgig/core/utils/messenger.dart';
import 'package:nextgig/core/widgets/skill_chip.dart';
import 'package:nextgig/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:nextgig/features/auth/presentation/widgets/account_section.dart';
import 'package:nextgig/features/profile/domain/entities/skill.dart';
import 'package:nextgig/features/profile/presentation/cubit/profile_cubit.dart';

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
    return BlocProvider(
      create: (_) => sl<ProfileCubit>()..watch(profileUid),
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
                  leading: CircleAvatar(
                    backgroundImage: (profile?.photoUrl.isNotEmpty ?? false)
                        ? NetworkImage(profile!.photoUrl)
                        : null,
                    child: (profile?.photoUrl.isEmpty ?? true)
                        ? const Icon(Icons.person)
                        : null,
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
              const SizedBox(height: 16),
              Text(t('skills'), style: Theme.of(context).textTheme.titleMedium),
              if (state.skills.isEmpty) const Text('No skills yet.'),
              for (final skill in state.skills)
                _SkillTile(skill: skill, uid: uid, mine: mine),
              const SizedBox(height: 16),
              Text(
                t('reviews'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (state.reviews.isEmpty) const Text('No reviews yet.'),
              for (final review in state.reviews)
                ListTile(
                  title: Text('${review.rating}/5'),
                  subtitle: Text(review.comment),
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
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: SkillChip(label: skill.name, verified: skill.verified),
      subtitle: Text(skill.proficiency),
      trailing: mine
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () =>
                      context.push(AppRoutes.skillForm, extra: skill),
                  icon: const Icon(Icons.edit_outlined),
                ),
                IconButton(
                  onPressed: () =>
                      context.read<ProfileCubit>().deleteSkill(uid, skill.id),
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            )
          : TextButton(
              onPressed: () => _endorse(context),
              child: const Text('Endorse'),
            ),
    );
  }

  Future<void> _endorse(BuildContext context) async {
    final me = context.read<AuthCubit>().state.user;
    if (me == null) return;
    var relationship = 'mentor';
    final note = TextEditingController();
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Endorse ${skill.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: relationship,
                items: const [
                  DropdownMenuItem(value: 'mentor', child: Text('Mentor')),
                  DropdownMenuItem(value: 'lecturer', child: Text('Lecturer')),
                  DropdownMenuItem(value: 'client', child: Text('Past client')),
                ],
                onChanged: (value) {
                  if (value != null) relationship = value;
                },
              ),
              TextField(
                controller: note,
                decoration: const InputDecoration(labelText: 'Note'),
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
              child: const Text('Endorse'),
            ),
          ],
        );
      },
    );
    if (saved != true || !context.mounted) {
      note.dispose();
      return;
    }
    try {
      await context.read<ProfileCubit>().endorse(
        ownerId: uid,
        skillId: skill.id,
        endorserId: me.uid,
        endorserName: me.name.isEmpty ? me.email : me.name,
        relationship: relationship,
        note: note.text,
      );
      if (context.mounted) showAppMessage(context, 'Skill verified.');
    } catch (_) {
      if (context.mounted) {
        showAppMessage(context, 'Could not endorse this skill.');
      }
    }
    note.dispose();
  }
}
