import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nextgig/core/widgets/app_button.dart';
import 'package:nextgig/core/widgets/user_avatar.dart';
import 'package:nextgig/features/auth/presentation/cubit/auth_cubit.dart';

/// Shows the signed-in user, an email-verification banner and a logout button.
/// Embed it in the profile screen.
class AccountSection extends StatelessWidget {
  const AccountSection({super.key, this.photoUrl = '', this.displayName});

  final String photoUrl;
  final String? displayName;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listenWhen: (prev, curr) => curr.error != null || curr.info != null,
      listener: (context, state) {
        final message = state.error ?? state.info;
        if (message != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(message)));
        }
      },
      builder: (context, state) {
        final user = state.user;
        if (user == null) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              leading: UserAvatar(
                name: displayName ?? user.name,
                photoUrl: photoUrl,
              ),
              title: Text(
                (displayName ?? user.name).isEmpty
                    ? 'NextGig user'
                    : (displayName ?? user.name),
              ),
              subtitle: Text(user.email),
            ),
            if (!user.emailVerified)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Please verify your email address.'),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          TextButton(
                            onPressed: () =>
                                context.read<AuthCubit>().resendVerification(),
                            child: const Text('Resend email'),
                          ),
                          TextButton(
                            onPressed: () =>
                                context.read<AuthCubit>().refreshUser(),
                            child: const Text("I've verified"),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
            AppButton(
              label: 'Log out',
              outlined: true,
              onPressed: () => context.read<AuthCubit>().signOut(),
            ),
          ],
        );
      },
    );
  }
}
