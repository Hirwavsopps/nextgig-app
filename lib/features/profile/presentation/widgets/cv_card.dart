import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nextgig/core/di/injection.dart';
import 'package:nextgig/core/theme/app_theme.dart';
import 'package:nextgig/core/utils/messenger.dart';
import 'package:nextgig/features/profile/domain/entities/user_profile.dart';
import 'package:nextgig/features/profile/presentation/cubit/cv_cubit.dart';
import 'package:url_launcher/url_launcher.dart';

/// "My CV" on a profile. The owner can upload, replace or remove a PDF;
/// anyone viewing the profile can open it.
class CvCard extends StatelessWidget {
  const CvCard({super.key, required this.profile, required this.mine});

  final UserProfile profile;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    // Visitors only see the card when there is a CV to open.
    if (!mine && !profile.hasCv) return const SizedBox.shrink();
    return BlocProvider(
      create: (_) => sl<CvCubit>(),
      child: _CvCardView(profile: profile, mine: mine),
    );
  }
}

class _CvCardView extends StatelessWidget {
  const _CvCardView({required this.profile, required this.mine});

  final UserProfile profile;
  final bool mine;

  Future<void> _open(BuildContext context) async {
    final opened = await launchUrl(
      Uri.parse(profile.cvUrl),
      mode: LaunchMode.externalApplication,
    );
    if (!opened && context.mounted) {
      showAppMessage(context, 'Could not open the CV.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return BlocConsumer<CvCubit, CvState>(
      listenWhen: (_, s) => s.message != null,
      listener: (context, s) => showAppMessage(context, s.message!),
      builder: (context, state) {
        final cubit = context.read<CvCubit>();
        return Container(
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
                  Icon(Icons.description_outlined, color: scheme.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mine ? 'My CV' : 'CV',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          profile.hasCv
                              ? (profile.cvName.isEmpty
                                    ? 'cv.pdf'
                                    : profile.cvName)
                              : 'Add a PDF so clients can see your experience.',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (state.isBusy)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  if (profile.hasCv)
                    OutlinedButton.icon(
                      onPressed: () => _open(context),
                      icon: const Icon(Icons.open_in_new, size: 18),
                      label: const Text('Open'),
                    ),
                  if (mine)
                    FilledButton.icon(
                      onPressed: state.isBusy
                          ? null
                          : () => cubit.upload(profile.uid),
                      icon: const Icon(Icons.upload_file, size: 18),
                      label: Text(profile.hasCv ? 'Replace' : 'Upload PDF'),
                    ),
                  if (mine && profile.hasCv)
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: scheme.error,
                      ),
                      onPressed: state.isBusy
                          ? null
                          : () => cubit.remove(profile.uid),
                      child: const Text('Remove'),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
