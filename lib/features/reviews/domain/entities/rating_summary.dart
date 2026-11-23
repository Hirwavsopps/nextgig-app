import 'package:equatable/equatable.dart';
import 'package:nextgig/features/reviews/domain/entities/review.dart';

/// Average and star breakdown for a profile, computed from the live reviews
/// so it changes as soon as a new review arrives.
class RatingSummary extends Equatable {
  const RatingSummary._(this.count, this.average, this.starCounts);

  factory RatingSummary.fromReviews(Iterable<Review> reviews) {
    final counts = List<int>.filled(5, 0);
    var total = 0;
    var count = 0;
    for (final review in reviews) {
      // Ignore anything outside 1-5 rather than skew the average.
      if (review.rating < 1 || review.rating > 5) continue;
      counts[review.rating - 1]++;
      total += review.rating;
      count++;
    }
    return RatingSummary._(
      count,
      count == 0 ? 0 : total / count,
      List.unmodifiable(counts),
    );
  }

  final int count;

  /// 0 when there are no reviews.
  final double average;

  /// Index 0 is one star, index 4 is five stars.
  final List<int> starCounts;

  bool get isEmpty => count == 0;

  /// "4.5", one decimal place.
  String get averageLabel => average.toStringAsFixed(1);

  int countFor(int stars) => starCounts[stars - 1];

  /// Share of reviews with [stars], 0 to 1.
  double shareFor(int stars) => count == 0 ? 0 : countFor(stars) / count;

  @override
  List<Object?> get props => [count, average, starCounts];
}
