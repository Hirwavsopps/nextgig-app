import 'package:flutter/material.dart';
import 'package:nextgig/core/theme/app_colors.dart';

/// Small pill showing a skill. [verified] adds a badge (used by skill verification).
class SkillChip extends StatelessWidget {
  const SkillChip({super.key, required this.label, this.verified = false});

  final String label;
  final bool verified;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (verified) ...const [
            Icon(Icons.verified, size: 14, color: AppColors.success),
            SizedBox(width: 4),
          ],
          Text(label, style: theme.textTheme.labelMedium),
        ],
      ),
    );
  }
}
