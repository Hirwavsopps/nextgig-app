import 'package:material_ui/material_ui.dart';
import 'package:nextgig/core/theme/app_colors.dart';

/// Read-only stars. Half stars are shown for averages such as 4.5.
class StarRating extends StatelessWidget {
  const StarRating({super.key, required this.rating, this.size = 16});

  final double rating;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${rating.toStringAsFixed(1)} out of 5 stars',
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var star = 1; star <= 5; star++)
              Icon(
                rating >= star
                    ? Icons.star_rounded
                    : rating >= star - 0.5
                    ? Icons.star_half_rounded
                    : Icons.star_outline_rounded,
                size: size,
                color: AppColors.accent,
              ),
          ],
        ),
      ),
    );
  }
}

/// Five tappable stars for choosing a rating.
class StarRatingInput extends StatelessWidget {
  const StarRatingInput({
    super.key,
    required this.rating,
    required this.onChanged,
    this.size = 44,
  });

  final int rating;
  final ValueChanged<int>? onChanged;
  final double size;

  static const labels = ['Poor', 'Fair', 'Good', 'Very good', 'Excellent'];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FittedBox(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var star = 1; star <= 5; star++)
                IconButton(
                  key: ValueKey('star-$star'),
                  tooltip: '$star star${star == 1 ? '' : 's'}',
                  iconSize: size,
                  onPressed: onChanged == null ? null : () => onChanged!(star),
                  icon: Icon(
                    star <= rating
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: AppColors.accent,
                  ),
                ),
            ],
          ),
        ),
        Text(
          rating == 0 ? 'Tap a star to rate' : labels[rating - 1],
          style: Theme.of(context).textTheme.titleSmall,
        ),
      ],
    );
  }
}
