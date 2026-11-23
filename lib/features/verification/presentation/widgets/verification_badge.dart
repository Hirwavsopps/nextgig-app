import 'package:material_ui/material_ui.dart';
import 'package:nextgig/core/theme/app_colors.dart';
import 'package:nextgig/features/verification/domain/entities/verification_status.dart';

/// Colors and icon for each status, tuned for the light and dark themes.
class VerificationStyle {
  const VerificationStyle._(this.foreground, this.icon);

  final Color foreground;
  final IconData icon;

  Color background(BuildContext context) => foreground.withValues(
    alpha: Theme.of(context).brightness == Brightness.dark ? 0.22 : 0.12,
  );

  static VerificationStyle of(BuildContext context, VerificationStatus status) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return switch (status) {
      VerificationStatus.unverified => VerificationStyle._(
        dark ? AppColors.darkMuted : AppColors.muted,
        Icons.shield_outlined,
      ),
      VerificationStatus.pending => VerificationStyle._(
        dark ? const Color(0xFFFFC857) : const Color(0xFFA15C00),
        Icons.hourglass_top_rounded,
      ),
      VerificationStatus.verified => VerificationStyle._(
        dark ? const Color(0xFF7BD389) : AppColors.success,
        Icons.verified_rounded,
      ),
      VerificationStatus.rejected => VerificationStyle._(
        dark ? const Color(0xFFFF8A80) : AppColors.danger,
        Icons.cancel_outlined,
      ),
    };
  }
}

/// Small rounded status label: grey, amber, green with a check, or red.
class VerificationBadge extends StatelessWidget {
  const VerificationBadge({super.key, required this.status});

  final VerificationStatus status;

  @override
  Widget build(BuildContext context) {
    final style = VerificationStyle.of(context, status);
    return Semantics(
      label: 'Verification status: ${status.label}',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: style.background(context),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(style.icon, size: 14, color: style.foreground),
            const SizedBox(width: 4),
            Text(
              status.label.toUpperCase(),
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                color: style.foreground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
