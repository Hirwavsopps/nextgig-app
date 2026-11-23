import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:nextgig/core/di/injection.dart';
import 'package:nextgig/core/router/app_routes.dart';
import 'package:nextgig/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:nextgig/features/messages/domain/usecases/chat_usecases.dart';

/// Opens (or creates) the chat with another user and shows it.
/// Used by the "Message client" button on a gig.
Future<void> startChat(
  BuildContext context, {
  required String otherUid,
  required String otherName,
  String? gigId,
  String? gigTitle,
}) async {
  final user = context.read<AuthCubit>().state.user;
  if (user == null) return;
  final myName = user.name.trim().isNotEmpty ? user.name.trim() : user.email;
  final messenger = ScaffoldMessenger.of(context);
  final router = GoRouter.of(context);

  try {
    final id = await sl<OpenConversation>()(
      myUid: user.uid,
      myName: myName,
      otherUid: otherUid,
      otherName: otherName,
      gigId: gigId,
      gigTitle: gigTitle,
    );
    router.push(AppRoutes.chat(id), extra: otherName);
  } catch (_) {
    messenger.showSnackBar(
      const SnackBar(content: Text('Could not open the chat. Try again.')),
    );
  }
}
