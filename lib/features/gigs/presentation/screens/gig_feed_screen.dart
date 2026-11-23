import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:nextgig/core/constants/app_constants.dart';
import 'package:nextgig/core/di/injection.dart';
import 'package:nextgig/core/router/app_routes.dart';
import 'package:nextgig/core/theme/app_theme.dart';
import 'package:nextgig/core/widgets/brand_logo.dart';
import 'package:nextgig/core/widgets/empty_view.dart';
import 'package:nextgig/core/widgets/error_view.dart';
import 'package:nextgig/core/widgets/gig_card.dart';
import 'package:nextgig/core/widgets/loading_view.dart';
import 'package:nextgig/core/widgets/pill.dart';
import 'package:nextgig/features/gigs/presentation/cubit/bookmarks_cubit.dart';
import 'package:nextgig/features/gigs/presentation/cubit/gig_feed_cubit.dart';
import 'package:nextgig/features/gigs/presentation/cubit/gig_feed_state.dart';
import 'package:nextgig/features/gigs/presentation/widgets/filter_sheet.dart';

/// Talent Home: the Figma "Talent Home" screen.
class GigFeedScreen extends StatelessWidget {
  const GigFeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<GigFeedCubit>(
      create: (_) => sl<GigFeedCubit>()..start(),
      child: const _GigFeedView(),
    );
  }
}

class _GigFeedView extends StatelessWidget {
  const _GigFeedView();

  void _openFilters(BuildContext context) {
    final cubit = context.read<GigFeedCubit>();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => BlocProvider<GigFeedCubit>.value(
        value: cubit,
        child: const FilterSheet(),
      ),
    );
  }

  List<Widget> _bodySlivers(BuildContext context, GigFeedState state) {
    if (state.status == GigFeedStatus.failure) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: ErrorView(
            message: state.errorMessage ?? 'Something went wrong.',
            onRetry: () => context.read<GigFeedCubit>().start(),
          ),
        ),
      ];
    }
    if (state.status != GigFeedStatus.loaded) {
      return const [
        SliverFillRemaining(hasScrollBody: false, child: LoadingView()),
      ];
    }
    final gigs = state.visibleGigs;
    if (gigs.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: EmptyView(
            message: state.filter.isActive
                ? 'No gigs match your search or filters.'
                : 'No gigs posted yet.',
          ),
        ),
      ];
    }
    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        sliver: SliverList.separated(
          itemCount: gigs.length,
          separatorBuilder: (context, index) => const SizedBox(height: 14),
          itemBuilder: (context, index) {
            final gig = gigs[index];
            return BlocBuilder<BookmarksCubit, Set<String>>(
              builder: (context, saved) {
                return GigCard(
                  gig: gig,
                  isBookmarked: saved.contains(gig.id),
                  onTap: () =>
                      context.push(AppRoutes.gigDetail(gig.id), extra: gig),
                  onBookmarkTap: () =>
                      context.read<BookmarksCubit>().toggle(gig.id),
                );
              },
            );
          },
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<GigFeedCubit, GigFeedState>(
          builder: (context, state) {
            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _FeedHeader(
                    state: state,
                    onOpenFilters: () => _openFilters(context),
                  ),
                ),
                ..._bodySlivers(context, state),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _FeedHeader extends StatelessWidget {
  const _FeedHeader({required this.state, required this.onOpenFilters});

  final GigFeedState state;
  final VoidCallback onOpenFilters;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final cubit = context.read<GigFeedCubit>();
    final filter = state.filter;
    final count = state.visibleGigs.length;

    OutlineInputBorder border(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadii.control),
      borderSide: BorderSide(color: color),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const BrandLogo(size: 36),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'NEXTGIG',
                      style: theme.textTheme.labelSmall?.copyWith(
                        letterSpacing: 1,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      'Talent Home',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              BlocBuilder<BookmarksCubit, Set<String>>(
                builder: (context, saved) {
                  return IconButton(
                    tooltip: 'Saved gigs',
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${saved.length} saved gigs')),
                      );
                    },
                    icon: Badge(
                      isLabelVisible: saved.isNotEmpty,
                      label: Text('${saved.length}'),
                      child: const Icon(Icons.bookmarks_outlined),
                    ),
                  );
                },
              ),
              CircleAvatar(
                radius: 18,
                backgroundColor: scheme.surfaceContainerHighest,
                child: Icon(
                  Icons.person_outline,
                  size: 20,
                  color: scheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Row(
            children: [
              Pill(label: 'Live in Kigali', dot: true),
              SizedBox(width: 8),
              Pill(label: 'Verified talent', icon: Icons.verified_outlined),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Muraho \u{1F44B}',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$count ${count == 1 ? 'gig' : 'gigs'} available in Kigali today',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: cubit.search,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: 'Search gigs, skills, companies...',
                    filled: true,
                    fillColor: scheme.surface,
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    border: border(scheme.outlineVariant),
                    enabledBorder: border(scheme.outlineVariant),
                    focusedBorder: border(scheme.primary),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filled(
                tooltip: 'Filters',
                onPressed: onOpenFilters,
                style: IconButton.styleFrom(
                  backgroundColor: scheme.primary,
                  foregroundColor: scheme.onPrimary,
                  minimumSize: const Size(54, 54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadii.control),
                  ),
                ),
                icon: Badge(
                  isLabelVisible: filter.isActive,
                  child: const Icon(Icons.tune),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _CategoryChip(
                  label: 'For You',
                  icon: Icons.star,
                  count: state.allGigs.length,
                  selected: filter.category == null,
                  onTap: () =>
                      cubit.updateFilter(filter.copyWith(clearCategory: true)),
                ),
                for (final category in AppConstants.gigCategories) ...[
                  const SizedBox(width: 8),
                  _CategoryChip(
                    label: category,
                    selected: filter.category == category,
                    onTap: () =>
                        cubit.updateFilter(filter.copyWith(category: category)),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(AppRadii.control),
              border: Border.all(color: scheme.outlineVariant),
            ),
            child: Row(
              children: [
                Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.bolt, color: scheme.onPrimary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Instant match active',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'Gigs ranked by your verified skills',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Pill(label: '$count ${count == 1 ? 'gig' : 'gigs'}'),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Curated Opportunities',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                'Sort: Newest',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.count,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final background = selected ? scheme.primary : scheme.surface;
    final foreground = selected ? scheme.onPrimary : scheme.onSurface;

    return Material(
      color: background,
      shape: StadiumBorder(
        side: BorderSide(
          color: selected ? scheme.primary : scheme.outlineVariant,
        ),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: foreground),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  color: foreground,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              if (count != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: foreground.withAlpha(51),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      color: foreground,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
