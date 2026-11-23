import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:nextgig/core/constants/app_images.dart';
import 'package:nextgig/core/router/app_routes.dart';
import 'package:nextgig/core/widgets/app_button.dart';
import 'package:nextgig/core/widgets/app_text_field.dart';
import 'package:nextgig/core/widgets/photo_banner.dart';
import 'package:nextgig/core/widgets/pill.dart';
import 'package:nextgig/features/auth/domain/entities/user_role.dart';
import 'package:nextgig/features/auth/domain/validators.dart';
import 'package:nextgig/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:nextgig/features/auth/presentation/widgets/or_divider.dart';
import 'package:nextgig/features/auth/presentation/widgets/password_field.dart';

/// Sign up: the Figma "Create Your Account" screen with the Talent / Mentor toggle.
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final ValueNotifier<UserRole> _role = ValueNotifier<UserRole>(
    UserRole.talent,
  );
  final ValueNotifier<bool> _acceptedTerms = ValueNotifier<bool>(false);

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _role.dispose();
    _acceptedTerms.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (!_acceptedTerms.value) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Please accept the community guidelines to continue.',
            ),
          ),
        );
      return;
    }
    final phone = _phoneController.text.trim();
    context.read<AuthCubit>().signUp(
      _nameController.text,
      _emailController.text,
      _passwordController.text,
      role: _role.value,
      phone: phone.isEmpty ? null : phone,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: BlocConsumer<AuthCubit, AuthState>(
          listenWhen: (prev, curr) => curr.error != null,
          listener: (context, state) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(state.error!)));
          },
          builder: (context, state) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        IconButton.filledTonal(
                          tooltip: 'Back to log in',
                          onPressed: () => context.go(AppRoutes.login),
                          icon: const Icon(Icons.arrow_back),
                        ),
                        const Spacer(),
                        const Pill(label: 'Rwanda tech & craft', dot: true),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const PhotoBanner(
                      asset: AppImages.onboardingMatch,
                      title: 'Turn your skills into paid work',
                      subtitle: 'Verified skills, real clients, real mentors',
                      height: 140,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Create your account',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Unlock curated gigs, verified skills and direct mentorship.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _RoleToggle(role: _role),
                    const SizedBox(height: 20),
                    AppTextField(
                      controller: _nameController,
                      label: 'Full name',
                      prefixIcon: const Icon(Icons.person_outline),
                      validator: validateName,
                    ),
                    const SizedBox(height: 14),
                    AppTextField(
                      controller: _phoneController,
                      label: 'Phone number (optional)',
                      keyboardType: TextInputType.phone,
                      prefixIcon: const Icon(Icons.phone_outlined),
                      validator: validatePhone,
                    ),
                    const SizedBox(height: 14),
                    AppTextField(
                      controller: _emailController,
                      label: 'Email',
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: const Icon(Icons.email_outlined),
                      validator: validateEmail,
                    ),
                    const SizedBox(height: 14),
                    PasswordField(
                      controller: _passwordController,
                      label: 'Create password',
                      validator: validatePassword,
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          'Minimum $minPasswordLength characters',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                    ValueListenableBuilder<bool>(
                      valueListenable: _acceptedTerms,
                      builder: (context, accepted, child) {
                        return CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                          value: accepted,
                          onChanged: (value) =>
                              _acceptedTerms.value = value ?? false,
                          title: Text(
                            'I agree to the Community Guidelines and Mentorship Code.',
                            style: theme.textTheme.bodySmall,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    ValueListenableBuilder<UserRole>(
                      valueListenable: _role,
                      builder: (context, role, child) {
                        return AppButton(
                          label: 'Sign up as ${role.label}',
                          isLoading: state.busy,
                          onPressed: _submit,
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    const OrDivider(),
                    const SizedBox(height: 16),
                    AppButton(
                      label: 'Continue with Google',
                      outlined: true,
                      onPressed: state.busy
                          ? null
                          : () => context.read<AuthCubit>().signInWithGoogle(),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => context.go(AppRoutes.login),
                      child: const Text('Already have an account? Log in'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _RoleToggle extends StatelessWidget {
  const _RoleToggle({required this.role});

  final ValueNotifier<UserRole> role;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(28),
      ),
      child: ValueListenableBuilder<UserRole>(
        valueListenable: role,
        builder: (context, selected, child) {
          return Row(
            children: [
              for (final option in UserRole.values)
                Expanded(
                  child: Material(
                    color: selected == option
                        ? scheme.primary
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(24),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: () => role.value = option,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Center(
                          child: Text(
                            option.label,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: selected == option
                                  ? scheme.onPrimary
                                  : scheme.onSurface,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
