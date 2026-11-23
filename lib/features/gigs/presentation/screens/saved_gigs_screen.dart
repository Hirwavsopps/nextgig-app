import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:nextgig/core/di/injection.dart';
import 'package:nextgig/core/router/app_routes.dart';
import 'package:nextgig/core/widgets/empty_view.dart';
import 'package:nextgig/core/widgets/error_view.dart';
import 'package:nextgig/core/widgets/gig_card.dart';
import 'package:nextgig/core/widgets/loading_view.dart';
import 'package:nextgig/features/gigs/presentation/cubit/bookmarks_cubit.dart';
import 'package:nextgig/features/gigs/presentation/cubit/gig_feed_cubit.dart';
import 'package:nextgig/features/gigs/presentation/cubit/gig_feed_state.dart';

/// The gigs the user bookmarked. Combines two cubits: the live gig list
/// (GigFeedCubit) and the saved ids (BookmarksCubit).
class SavedGigsScreen extends StatelessWidget {
  const SavedGigsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<GigFeedCubit>(
      create: (_) => sl<GigFeedCubit>()..start(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Saved gigs')),
        body: BlocBuilder<GigFeedCubit, GigFeedState>(
          builder: (context, feed) {
            if (feed.status == GigFeedStatus.failure) {
              return ErrorView(
                message: feed.errorMessage ?? 'Could not load gigs.',
                onRetry: () => context.read<GigFeedCubit>().start(),
              );
            }
            if (feed.status != GigFeedStatus.loaded) {
              return const LoadingView();
            }
            return BlocBuilder<BookmarksCubit, Set<String>>(
              builder: (context, saved) {
                final gigs = feed.allGigs
                    .where((g) => saved.contains(g.id))
                    .toList();
                if (gigs.isEmpty) {
                  return const EmptyView(
                    message:
                        'No saved gigs yet.\n'
                        'Tap the bookmark on any gig to keep it here.',
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: gigs.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 14),
                  itemBuilder: (context, i) => GigCard(
                    gig: gigs[i],
                    isBookmarked: true,
                    onTap: () => context.push(
                      AppRoutes.gigDetail(gigs[i].id),
                      extra: gigs[i],
                    ),
                    onBookmarkTap: () =>
                        context.read<BookmarksCubit>().toggle(gigs[i].id),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
