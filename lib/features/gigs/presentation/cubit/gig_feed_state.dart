import 'package:equatable/equatable.dart';
import 'package:nextgig/features/gigs/domain/entities/gig.dart';
import 'package:nextgig/features/gigs/domain/entities/gig_filter.dart';

enum GigFeedStatus { initial, loading, loaded, failure }

class GigFeedState extends Equatable {
  const GigFeedState({
    this.status = GigFeedStatus.initial,
    this.allGigs = const [],
    this.filter = const GigFilter(),
    this.errorMessage,
  });

  final GigFeedStatus status;
  final List<Gig> allGigs;
  final GigFilter filter;
  final String? errorMessage;

  /// Gigs after search and filters are applied.
  List<Gig> get visibleGigs => filter.apply(allGigs);

  GigFeedState copyWith({
    GigFeedStatus? status,
    List<Gig>? allGigs,
    GigFilter? filter,
    String? errorMessage,
  }) {
    return GigFeedState(
      status: status ?? this.status,
      allGigs: allGigs ?? this.allGigs,
      filter: filter ?? this.filter,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, allGigs, filter, errorMessage];
}
