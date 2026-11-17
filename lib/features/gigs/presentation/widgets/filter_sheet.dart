import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nextgig/core/constants/app_constants.dart';
import 'package:nextgig/core/utils/formatters.dart';
import 'package:nextgig/core/widgets/app_button.dart';
import 'package:nextgig/features/gigs/presentation/cubit/gig_feed_cubit.dart';
import 'package:nextgig/features/gigs/presentation/cubit/gig_feed_state.dart';

/// Bottom sheet with category, neighborhood and pay-range filters.
/// Every change goes straight to [GigFeedCubit], so the list updates live.
class FilterSheet extends StatelessWidget {
  const FilterSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return BlocBuilder<GigFeedCubit, GigFeedState>(
      builder: (context, state) {
        final cubit = context.read<GigFeedCubit>();
        final filter = state.filter;
        final range = RangeValues(
          (filter.minPay ?? 0).toDouble(),
          (filter.maxPay ?? AppConstants.maxPayFilter.toInt()).toDouble(),
        );

        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text('Filters', style: textTheme.titleLarge),
                    ),
                    TextButton(
                      onPressed: cubit.clearFilters,
                      child: const Text('Clear all'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text('Category', style: textTheme.titleSmall),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final category in AppConstants.gigCategories)
                      ChoiceChip(
                        label: Text(category),
                        selected: filter.category == category,
                        onSelected: (selected) => cubit.updateFilter(
                          selected
                              ? filter.copyWith(category: category)
                              : filter.copyWith(clearCategory: true),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Text('Neighborhood', style: textTheme.titleSmall),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final area in AppConstants.neighborhoods)
                      ChoiceChip(
                        label: Text(area),
                        selected: filter.neighborhood == area,
                        onSelected: (selected) => cubit.updateFilter(
                          selected
                              ? filter.copyWith(neighborhood: area)
                              : filter.copyWith(clearNeighborhood: true),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Pay: ${formatRwf(range.start.round())} - ${formatRwf(range.end.round())}',
                  style: textTheme.titleSmall,
                ),
                RangeSlider(
                  values: range,
                  min: 0,
                  max: AppConstants.maxPayFilter,
                  divisions: 40,
                  labels: RangeLabels(
                    formatRwf(range.start.round()),
                    formatRwf(range.end.round()),
                  ),
                  onChanged: (values) {
                    final isFullRange =
                        values.start == 0 &&
                        values.end == AppConstants.maxPayFilter;
                    cubit.updateFilter(
                      isFullRange
                          ? filter.copyWith(clearPay: true)
                          : filter.copyWith(
                              minPay: values.start.round(),
                              maxPay: values.end.round(),
                            ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                AppButton(
                  label: 'Show results',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
