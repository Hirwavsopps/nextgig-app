import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:nextgig/core/utils/formatters.dart';
import 'package:nextgig/core/theme/app_theme.dart';
import 'package:nextgig/core/utils/messenger.dart';
import 'package:nextgig/features/profile/domain/entities/skill.dart';
import 'package:nextgig/features/verification/domain/entities/reviewer.dart';
import 'package:nextgig/features/verification/domain/entities/verification_request.dart';
import 'package:nextgig/features/verification/presentation/widgets/verification_badge.dart';

String relationshipLabel(String relationship) =>
    Reviewer(uid: '', name: '', relationship: relationship).relationshipLabel;

/// "Verified by David Mugisha · Mentor · 12 Nov 2026". Empty for skills that
/// are not verified.
class VerifiedByLine extends StatelessWidget {
  const VerifiedByLine({super.key, required this.skill});

  final Skill skill;

  @override
  Widget build(BuildContext context) {
    if (!skill.isVerified) return const SizedBox.shrink();
    final parts = [
      if (skill.verifiedByName.isNotEmpty)
        'Verified by ${skill.verifiedByName}',
      if (skill.verifiedByRelationship.isNotEmpty)
        relationshipLabel(skill.verifiedByRelationship),
      if (skill.verifiedAt != null) formatDate(skill.verifiedAt!),
    ];
    if (parts.isEmpty) return const SizedBox.shrink();
    final style = VerificationStyle.of(context, skill.status);
    return Row(
      children: [
        Icon(
          Icons.workspace_premium_outlined,
          size: 14,
          color: style.foreground,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            parts.join(' · '),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}

Future<void> openEvidence(BuildContext context, String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null ||
      !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    if (context.mounted) showAppMessage(context, 'Could not open the file.');
  }
}

/// The uploaded file: images inline, PDFs as a card that opens the file.
class EvidencePreview extends StatelessWidget {
  const EvidencePreview({super.key, required this.request});

  final VerificationRequest request;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final open = OutlinedButton.icon(
      onPressed: request.evidenceUrl.isEmpty
          ? null
          : () => openEvidence(context, request.evidenceUrl),
      icon: const Icon(Icons.open_in_new, size: 18),
      label: const Text('Open full file'),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (request.isImage && request.evidenceUrl.isNotEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              request.evidenceUrl,
              height: 220,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) => progress == null
                  ? child
                  : const SizedBox(
                      height: 220,
                      child: Center(child: CircularProgressIndicator()),
                    ),
              errorBuilder: (context, error, stackTrace) => const SizedBox(
                height: 80,
                child: Center(child: Text('Could not load this image.')),
              ),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.picture_as_pdf_outlined, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    request.evidenceFileName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 8),
        open,
      ],
    );
  }
}

/// One submission in a list: skill, who sent it, when, and its status.
class VerificationRequestCard extends StatelessWidget {
  const VerificationRequestCard({
    super.key,
    required this.request,
    this.showOwner = false,
    this.onTap,
  });

  final VerificationRequest request;
  final bool showOwner;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final submitted = request.submittedAt;
    final subtitle = [
      if (showOwner)
        request.userName.isEmpty ? 'NextGig user' : request.userName,
      request.evidenceType.label,
      if (submitted != null) 'Sent ${timeAgo(submitted)}',
    ].join(' · ');
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.card),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      showOwner ? request.skillName : request.evidenceFileName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall,
                    ),
                  ),
                  const SizedBox(width: 8),
                  VerificationBadge(status: request.status),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall,
              ),
              if (request.reviewerComment.isNotEmpty) ...[
                const SizedBox(height: 8),
                ReviewerComment(request: request),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// The reviewer's note, attributed and dated.
class ReviewerComment extends StatelessWidget {
  const ReviewerComment({super.key, required this.request});

  final VerificationRequest request;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = VerificationStyle.of(context, request.status);
    final reviewed = request.reviewedAt;
    final by = [
      if (request.reviewerName.isNotEmpty) request.reviewerName,
      if (request.reviewerRelationship.isNotEmpty)
        relationshipLabel(request.reviewerRelationship),
      if (reviewed != null) formatDate(reviewed),
    ].join(' · ');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: style.background(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '"${request.reviewerComment}"',
            style: theme.textTheme.bodyMedium,
          ),
          if (by.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              '— $by',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
