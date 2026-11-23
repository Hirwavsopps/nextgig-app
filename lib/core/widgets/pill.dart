import 'package:material_ui/material_ui.dart';

/// Small uppercase label, e.g. "LIVE IN KIGALI", "OPEN GIG", "FIXED PRICE".
/// [filled] = black pill, [outlined] = transparent with a border,
/// default = light grey pill.
class Pill extends StatelessWidget {
  const Pill({
    super.key,
    required this.label,
    this.icon,
    this.dot = false,
    this.filled = false,
    this.outlined = false,
  });

  final String label;
  final IconData? icon;
  final bool dot;
  final bool filled;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final Color background = filled
        ? scheme.primary
        : (outlined ? Colors.transparent : scheme.surfaceContainerHighest);
    final Color foreground = filled ? scheme.onPrimary : scheme.onSurface;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
        border: outlined ? Border.all(color: scheme.outlineVariant) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: foreground,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
          ],
          if (icon != null) ...[
            Icon(icon, size: 12, color: foreground),
            const SizedBox(width: 4),
          ],
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }
}
