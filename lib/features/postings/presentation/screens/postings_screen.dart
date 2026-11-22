import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:nextgig/core/di/injection.dart';
import 'package:nextgig/core/router/app_routes.dart';
import 'package:nextgig/core/utils/formatters.dart';
import 'package:nextgig/core/utils/messenger.dart';
import 'package:nextgig/features/applications/domain/entities/gig_application.dart';
import 'package:nextgig/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:nextgig/features/gigs/domain/entities/gig.dart';
import 'package:nextgig/features/postings/presentation/cubit/postings_cubit.dart';

class PostingsScreen extends StatelessWidget {
  const PostingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = context.read<AuthCubit>().state.user?.uid;
    if (uid == null) return const SizedBox.shrink();
    return BlocProvider(
      create: (_) => sl<PostingsCubit>()..watch(uid),
      child: const _PostingsView(),
    );
  }
}

class _PostingsView extends StatelessWidget {
  const _PostingsView();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: BlocConsumer<PostingsCubit, PostingsState>(
        listener: (context, state) {
          if (state.error != null) showAppMessage(context, state.error!);
        },
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Gigs'),
              bottom: const TabBar(
                tabs: [
                  Tab(text: 'My gigs'),
                  Tab(text: 'Applications'),
                ],
              ),
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () => context.push(AppRoutes.gigForm),
              child: const Icon(Icons.add),
            ),
            body: TabBarView(
              children: [
                _GigList(gigs: state.gigs),
                _ApplicationList(applications: state.applications),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _GigList extends StatelessWidget {
  const _GigList({required this.gigs});

  final List<Gig> gigs;

  @override
  Widget build(BuildContext context) {
    if (gigs.isEmpty) {
      return const Center(child: Text('You have not posted a gig yet.'));
    }
    return ListView.builder(
      itemCount: gigs.length,
      itemBuilder: (context, index) {
        final gig = gigs[index];
        return ListTile(
          title: Text(gig.title),
          subtitle: Text('${gig.neighborhood} · ${formatRwf(gig.pay)}'),
          onTap: () => context.push(AppRoutes.gigDetail(gig.id), extra: gig),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () => context.push(AppRoutes.gigForm, extra: gig),
                icon: const Icon(Icons.edit_outlined),
              ),
              IconButton(
                onPressed: () => _confirmDelete(context, gig),
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(BuildContext context, Gig gig) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete this gig?'),
        content: Text(gig.title),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await context.read<PostingsCubit>().deleteGig(gig.id);
      if (context.mounted) showAppMessage(context, 'Gig deleted.');
    } catch (_) {}
  }
}

class _ApplicationList extends StatelessWidget {
  const _ApplicationList({required this.applications});

  final List<GigApplication> applications;

  @override
  Widget build(BuildContext context) {
    if (applications.isEmpty) {
      return const Center(child: Text('You have not applied to a gig yet.'));
    }
    return ListView.builder(
      itemCount: applications.length,
      itemBuilder: (context, index) {
        final application = applications[index];
        return ListTile(
          title: Text(
            application.gigTitle.isEmpty ? 'Gig' : application.gigTitle,
          ),
          subtitle: Text(application.status.name),
          trailing: application.status == ApplicationStatus.completed
              ? TextButton(
                  onPressed: () => context.push(
                    '${AppRoutes.earnings}?gigTitle=${Uri.encodeComponent(application.gigTitle)}&gigId=${application.gigId}',
                  ),
                  child: const Text('Record'),
                )
              : null,
        );
      },
    );
  }
}
