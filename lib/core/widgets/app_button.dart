import 'package:flutter/material.dart';

/// Full-width button with a 52px height (above the 48px Material tap target).
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.outlined = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    );
    final VoidCallback? handler = isLoading ? null : onPressed;
    final Widget child = isLoading
        ? const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Text(label);

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: outlined
          ? OutlinedButton(
              onPressed: handler,
              style: OutlinedButton.styleFrom(shape: shape),
              child: child,
            )
          : FilledButton(
              onPressed: handler,
              style: FilledButton.styleFrom(shape: shape),
              child: child,
            ),
    );
  }
}
