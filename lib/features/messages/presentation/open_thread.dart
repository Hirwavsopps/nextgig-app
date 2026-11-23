import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:nextgig/core/di/injection.dart';
import 'package:nextgig/core/router/app_routes.dart';
import 'package:nextgig/core/utils/messenger.dart';
import 'package:nextgig/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:nextgig/features/messages/data/message_repository.dart';

/// Opens the single thread between the signed-in user and [otherId].
Future<void> openThread(
  BuildContext context, {
  required String otherId,
  required String otherName,
  String? gigId,
}) async {
  final me = context.read<AuthCubit>().state.user;
  if (me == null || me.uid == otherId) return;
  try {
    final id = await sl<MessageRepository>().open(
      meId: me.uid,
      otherId: otherId,
      myName: me.name.isEmpty ? me.email : me.name,
      otherName: otherName,
      gigId: gigId,
    );
    if (context.mounted) context.push(AppRoutes.message(id));
  } catch (error) {
    if (context.mounted) showAppMessage(context, '$error');
  }
}
