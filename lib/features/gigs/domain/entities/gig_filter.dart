import 'package:equatable/equatable.dart';
import 'package:nextgig/features/gigs/domain/entities/gig.dart';

/// Search + filter options for the gig feed. [apply] is pure and unit tested.
class GigFilter extends Equatable {
  const GigFilter({
    this.query = '',
    this.category,
    this.neighborhood,
    this.minPay,
    this.maxPay,
  });

  final String query;
  final String? category;
  final String? neighborhood;
  final int? minPay;
  final int? maxPay;

  bool get isActive =>
      query.isNotEmpty ||
      category != null ||
      neighborhood != null ||
      minPay != null ||
      maxPay != null;

  GigFilter copyWith({
    String? query,
    String? category,
    String? neighborhood,
    int? minPay,
    int? maxPay,
    bool clearCategory = false,
    bool clearNeighborhood = false,
    bool clearPay = false,
  }) {
    return GigFilter(
      query: query ?? this.query,
      category: clearCategory ? null : (category ?? this.category),
      neighborhood: clearNeighborhood
          ? null
          : (neighborhood ?? this.neighborhood),
      minPay: clearPay ? null : (minPay ?? this.minPay),
      maxPay: clearPay ? null : (maxPay ?? this.maxPay),
    );
  }

  /// Returns the gigs that match every active option.
  /// Filtering happens in memory, so no composite Firestore index is needed.
  List<Gig> apply(List<Gig> gigs) {
    final text = query.trim().toLowerCase();
    final selectedCategory = category;
    final selectedNeighborhood = neighborhood;
    final lowest = minPay;
    final highest = maxPay;

    return gigs.where((gig) {
      if (selectedCategory != null && gig.category != selectedCategory) {
        return false;
      }
      if (selectedNeighborhood != null &&
          gig.neighborhood != selectedNeighborhood) {
        return false;
      }
      if (lowest != null && gig.pay < lowest) {
        return false;
      }
      if (highest != null && gig.pay > highest) {
        return false;
      }
      if (text.isEmpty) {
        return true;
      }
      final haystack =
          '${gig.title} ${gig.description} ${gig.requiredSkills.join(' ')}'
              .toLowerCase();
      return haystack.contains(text);
    }).toList();
  }

  @override
  List<Object?> get props => [query, category, neighborhood, minPay, maxPay];
}
