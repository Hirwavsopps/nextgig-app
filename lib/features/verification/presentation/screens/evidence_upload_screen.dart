import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:nextgig/core/utils/messenger.dart';
import 'package:nextgig/core/widgets/app_button.dart';
import 'package:nextgig/core/widgets/app_text_field.dart';
import 'package:nextgig/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:nextgig/features/profile/domain/entities/skill.dart';
import 'package:nextgig/features/verification/domain/entities/evidence.dart';
import 'package:nextgig/features/verification/presentation/cubit/evidence_upload_cubit.dart';

/// Pick a certificate or portfolio file for [skill] and send it for review.
/// Expects an [EvidenceUploadCubit].
class EvidenceUploadScreen extends StatefulWidget {
  const EvidenceUploadScreen({super.key, required this.skill});

  final Skill skill;

  @override
  State<EvidenceUploadScreen> createState() => _EvidenceUploadScreenState();
}

class _EvidenceUploadScreenState extends State<EvidenceUploadScreen> {
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocConsumer<EvidenceUploadCubit, EvidenceUploadState>(
      listenWhen: (previous, current) =>
          previous.phase != current.phase || previous.error != current.error,
      listener: (context, state) {
        if (state.error != null) showAppMessage(context, state.error!);
        if (state.phase == UploadPhase.success) {
          showAppMessage(
            context,
            'Evidence sent. ${widget.skill.name} is now pending review.',
          );
          context.pop();
        }
      },
      builder: (context, state) {
        final cubit = context.read<EvidenceUploadCubit>();
        return PopScope(
          canPop: !state.busy,
          child: Scaffold(
            appBar: AppBar(title: Text('Verify ${widget.skill.name}')),
            body: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Show a reviewer that your ${widget.skill.name} skill is '
                  'real. They will see the file, the type and your note.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<EvidenceType>(
                  initialValue: state.evidenceType,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Type of evidence',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                  ),
                  items: [
                    for (final type in EvidenceType.values)
                      DropdownMenuItem(value: type, child: Text(type.label)),
                  ],
                  onChanged: state.busy
                      ? null
                      : (type) {
                          if (type != null) cubit.setType(type);
                        },
                ),
                const SizedBox(height: 16),
                _FilePickerCard(
                  file: state.file,
                  error: state.fileError,
                  enabled: !state.busy,
                  onPick: cubit.pickFile,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _note,
                  label: 'Note for the reviewer (optional)',
                  hint: 'e.g. Completed at Andela, March 2026',
                  maxLines: 3,
                ),
                const SizedBox(height: 24),
                if (state.busy) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: state.progress,
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Uploading… ${(state.progress * 100).round()}%',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                ],
                AppButton(
                  label: 'Submit for verification',
                  isLoading: state.busy,
                  onPressed: state.canSubmit ? () => _submit(context) : null,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _submit(BuildContext context) async {
    final user = context.read<AuthCubit>().state.user;
    if (user == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Send for review?'),
        content: Text(
          'Your file will be shared with NextGig reviewers so they can verify '
          '${widget.skill.name}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Send'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await context.read<EvidenceUploadCubit>().submit(
      userId: user.uid,
      userName: user.name.isEmpty ? user.email : user.name,
      skill: widget.skill,
      note: _note.text,
    );
  }
}

class _FilePickerCard extends StatelessWidget {
  const _FilePickerCard({
    required this.file,
    required this.error,
    required this.enabled,
    required this.onPick,
  });

  final EvidenceFile? file;
  final String? error;
  final bool enabled;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final picked = file;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: enabled ? onPick : null,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: error != null ? scheme.error : scheme.outlineVariant,
              ),
            ),
            child: picked == null
                ? Column(
                    children: [
                      const Icon(Icons.upload_file_outlined, size: 36),
                      const SizedBox(height: 8),
                      Text('Choose a file', style: theme.textTheme.titleSmall),
                      const SizedBox(height: 4),
                      Text(
                        'PDF, JPG or PNG, up to 5 MB',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  )
                : Row(
                    children: [
                      if (picked.isImage)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(picked.localPath),
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.image_outlined, size: 40),
                          ),
                        )
                      else
                        const Icon(Icons.picture_as_pdf_outlined, size: 40),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              picked.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleSmall,
                            ),
                            Text(
                              _size(picked.sizeBytes),
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: enabled ? onPick : null,
                        child: const Text('Change'),
                      ),
                    ],
                  ),
          ),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(
              error!,
              style: theme.textTheme.bodySmall?.copyWith(color: scheme.error),
            ),
          ),
      ],
    );
  }

  static String _size(int bytes) {
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / 1024).ceil()} KB';
  }
}
