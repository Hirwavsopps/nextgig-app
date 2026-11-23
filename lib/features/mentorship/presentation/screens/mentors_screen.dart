import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:nextgig/core/constants/app_images.dart';
import 'package:nextgig/core/di/injection.dart';
import 'package:nextgig/core/router/app_routes.dart';
import 'package:nextgig/core/theme/app_theme.dart';
import 'package:nextgig/core/utils/formatters.dart';
import 'package:nextgig/core/widgets/app_button.dart';
import 'package:nextgig/core/widgets/brand_logo.dart';
import 'package:nextgig/core/widgets/error_view.dart';
import 'package:nextgig/core/widgets/loading_view.dart';
import 'package:nextgig/core/widgets/pill.dart';
import 'package:nextgig/core/widgets/user_avatar.dart';
import 'package:nextgig/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:nextgig/features/gigs/domain/entities/gig.dart';
import 'package:nextgig/features/mentorship/domain/entities/mentorship.dart';
import 'package:nextgig/features/mentorship/presentation/cubit/mentorship_cubit.dart';

/// Figma frame 8: Mentor Dashboard.
///
/// - Mentorship cycle: my request numbers at a glance
/// - Mentors in Kigali: everyone attached to an open gig (live from `gigs`)
/// - Mentored gigs: those gigs
/// - My requests: CRUD on `mentorshipRequests`
class MentorsScreen extends StatelessWidget {
  const MentorsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthCubit>().state.user;
    final name = (user?.name.trim().isNotEmpty ?? false)
        ? user!.name.trim()
        : 'NextGig talent';
    return BlocProvider<MentorshipCubit>(
      create: (_) =>
          sl<MentorshipCubit>()..start(uid: user?.uid ?? '', name: name),
      child: const _MentorsView(),
    );
  }
}

class _MentorsView extends StatelessWidget {
  const _MentorsView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<MentorshipCubit, MentorshipState>(
      listenWhen: (_, s) => s.message != null,
      listener: (context, s) => ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(s.message!))),
      builder: (context, state) {
        return Scaffold(
          body: SafeArea(
            child: switch (state.status) {
              MentorshipLoad.loading => const LoadingView(),
              MentorshipLoad.failure => const ErrorView(
                message: 'Could not load mentors.',
              ),
              MentorshipLoad.loaded => _Dashboard(state: state),
            },
          ),
        );
      },
    );
  }
}

class _Dashboard extends StatelessWidget {
  const _Dashboard({required this.state});

  final MentorshipState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            Row(
              children: [
                const BrandLogo(size: 36),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'NEXTGIG',
                      style: theme.textTheme.labelSmall?.copyWith(
                        letterSpacing: 1,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      'Mentor Dashboard',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            _CycleCard(state: state),
            const SizedBox(height: 24),
            _Heading('Mentors in Kigali', trailing: '${state.mentors.length}'),
            const SizedBox(height: 10),
            if (state.mentors.isEmpty)
              const _Hint('No gigs with a mentor right now. Check back soon.')
            else
              for (final m in state.mentors) ...[
                _MentorCard(mentor: m),
                const SizedBox(height: 10),
              ],
            const SizedBox(height: 14),
            const _Heading('Active gigs & mentors'),
            const SizedBox(height: 10),
            if (state.mentoredGigs.isEmpty)
              const _Hint('Mentored gigs will appear here.')
            else
              for (final g in state.mentoredGigs) _MentoredGigTile(gig: g),
            const SizedBox(height: 24),
            _Heading(
              'My mentorship requests',
              trailing: '${state.requests.length}',
            ),
            const SizedBox(height: 10),
            if (state.requests.isEmpty)
              const _Hint(
                'You have not asked a mentor yet. Pick a mentor above and '
                'tell them what you want to learn.',
              )
            else
              for (final r in state.requests) _RequestTile(request: r),
          ],
        ),
      ),
    );
  }
}

/// The dark "Mentorship cycle" summary card over a team photo.
class _CycleCard extends StatelessWidget {
  const _CycleCard({required this.state});

  final MentorshipState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const on = Colors.white;

    Widget stat(String value, String label) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: on,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: on.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(AppRadii.card),
        image: DecorationImage(
          image: const AssetImage(AppImages.onboardingMentors),
          fit: BoxFit.cover,
          // Darken the photo so the white text stays readable.
          colorFilter: ColorFilter.mode(
            Colors.black.withValues(alpha: 0.6),
            BlendMode.darken,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'YOUR MENTORSHIP CYCLE',
            style: theme.textTheme.labelSmall?.copyWith(
              color: on.withValues(alpha: 0.7),
              letterSpacing: 1,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Learn on real gigs with an experienced guide.',
            style: theme.textTheme.titleMedium?.copyWith(
              color: on,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              stat('${state.mentors.length}', 'Mentors available'),
              stat('${state.pendingCount}', 'Pending requests'),
              stat('${state.mentoredGigs.length}', 'Mentored gigs'),
            ],
          ),
        ],
      ),
    );
  }
}

class _MentorCard extends StatelessWidget {
  const _MentorCard({required this.mentor});

  final Mentor mentor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final gigCount = mentor.gigs.length;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadii.control),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          UserAvatar(name: mentor.name, radius: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mentor.name,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  mentor.title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                Pill(
                  label: 'Guides $gigCount ${gigCount == 1 ? 'gig' : 'gigs'}',
                  icon: Icons.school_outlined,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: () => _openRequestSheet(context, mentor),
            child: const Text('Request'),
          ),
        ],
      ),
    );
  }

  void _openRequestSheet(BuildContext context, Mentor mentor) {
    final cubit = context.read<MentorshipCubit>();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: _RequestSheet(mentor: mentor),
      ),
    );
  }
}

/// Bottom sheet: choose the gig and write what you want to learn (CREATE).
///
/// Stateful only to own the text controller and form key. The dropdown keeps
/// its own selected value, and sending state lives in [MentorshipCubit].
class _RequestSheet extends StatefulWidget {
  const _RequestSheet({required this.mentor});

  final Mentor mentor;

  @override
  State<_RequestSheet> createState() => _RequestSheetState();
}

class _RequestSheetState extends State<_RequestSheet> {
  late Gig _gig = widget.mentor.gigs.first;
  final _message = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await context.read<MentorshipCubit>().sendRequest(
      mentor: widget.mentor,
      gig: _gig,
      message: _message.text,
    );
    if (ok && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sending = context.select((MentorshipCubit c) => c.state.isSending);

    return Padding(
      // Lift the sheet above the keyboard.
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Ask ${widget.mentor.name}',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(widget.mentor.title, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 16),
              DropdownButtonFormField<Gig>(
                initialValue: _gig,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Gig',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                ),
                items: [
                  for (final g in widget.mentor.gigs)
                    DropdownMenuItem(
                      value: g,
                      child: Text(g.title, overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: (g) => _gig = g ?? _gig,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _message,
                minLines: 3,
                maxLines: 5,
                maxLength: 500,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'What would you like help with?',
                  hintText:
                      'e.g. I am a 2nd-year design student and want feedback '
                      'on my packaging concepts.',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                ),
                validator: (v) => (v?.trim().length ?? 0) < 10
                    ? 'Write at least 10 characters'
                    : null,
              ),
              const SizedBox(height: 8),
              AppButton(
                label: 'Send request',
                isLoading: sending,
                onPressed: _send,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MentoredGigTile extends StatelessWidget {
  const _MentoredGigTile({required this.gig});

  final Gig gig;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.work_outline),
      title: Text(
        gig.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        '${gig.posterName} · ${formatRwfCompact(gig.pay)}',
        style: theme.textTheme.bodySmall,
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => context.push(AppRoutes.gigDetail(gig.id), extra: gig),
    );
  }
}

class _RequestTile extends StatelessWidget {
  const _RequestTile({required this.request});

  final MentorshipRequest request;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final cubit = context.read<MentorshipCubit>();
    final mentor = Mentor(fullLabel: request.mentorName, gigs: const []);
    final when = request.createdAt;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadii.control),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  mentor.name,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Pill(
                label: request.isPending ? 'Pending' : 'Cancelled',
                filled: request.isPending,
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            request.gigTitle + (when == null ? '' : ' · ${timeAgo(when)}'),
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text('"${request.message}"', style: theme.textTheme.bodyMedium),
          Align(
            alignment: Alignment.centerRight,
            child: request.isPending
                ? TextButton(
                    onPressed: () => cubit.cancel(request),
                    child: const Text('Cancel request'),
                  )
                : TextButton(
                    style: TextButton.styleFrom(foregroundColor: scheme.error),
                    onPressed: () => cubit.remove(request),
                    child: const Text('Remove'),
                  ),
          ),
        ],
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text, {this.trailing});

  final String text;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        if (trailing != null) Pill(label: trailing!),
      ],
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodyMedium
          ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
    );
  }
}
