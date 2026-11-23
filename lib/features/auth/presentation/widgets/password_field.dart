import 'package:material_ui/material_ui.dart';
import 'package:nextgig/core/widgets/app_text_field.dart';

/// Password field with a show/hide eye (as in the Figma login and sign-up).
/// The visibility flag lives in a ValueNotifier, so no setState is needed.
class PasswordField extends StatefulWidget {
  const PasswordField({
    super.key,
    required this.controller,
    required this.label,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  final ValueNotifier<bool> _obscured = ValueNotifier<bool>(true);

  @override
  void dispose() {
    _obscured.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: _obscured,
      builder: (context, obscured, child) {
        return AppTextField(
          controller: widget.controller,
          label: widget.label,
          obscureText: obscured,
          validator: widget.validator,
          prefixIcon: const Icon(Icons.lock_outline),
          suffixIcon: IconButton(
            tooltip: obscured ? 'Show password' : 'Hide password',
            onPressed: () => _obscured.value = !obscured,
            icon: Icon(
              obscured
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
            ),
          ),
        );
      },
    );
  }
}
