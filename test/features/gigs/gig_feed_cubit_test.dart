import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nextgig/features/gigs/domain/entities/gig.dart';
import 'package:nextgig/features/gigs/domain/entities/gig_filter.dart';
import 'package:nextgig/features/gigs/domain/repositories/gig_repository.dart';
import 'package:nextgig/features/gigs/domain/usecases/watch_gigs.dart';
import 'package:nextgig/features/gigs/presentation/cubit/gig_feed_cubit.dart';
import 'package:nextgig/features/gigs/presentation/cubit/gig_feed_state.dart';

class MockGigRepository extends Mock implements GigRepository {}

void main() {
  late MockGigRepository repository;

  const gigs = [
    Gig(
      id: '1',
      title: 'Landing page',
      description: 'Build a page',
      category: 'Tech',
      neighborhood: 'Kimironko',
      pay: 60000,
      requiredSkills: ['HTML'],
      posterName: 'Aline',
      posterId: 'user-1',
    ),
  ];

  setUp(() {
    repository = MockGigRepository();
  });

  blocTest<GigFeedCubit, GigFeedState>(
    'emits loading then loaded when the gig stream emits',
    setUp: () {
      when(() => repository.watchGigs()).thenAnswer((_) => Stream.value(gigs));
    },
    build: () => GigFeedCubit(WatchGigs(repository)),
    act: (cubit) => cubit.start(),
    wait: const Duration(milliseconds: 10),
    expect: () => [
      const GigFeedState(status: GigFeedStatus.loading),
      const GigFeedState(status: GigFeedStatus.loaded, allGigs: gigs),
    ],
  );

  blocTest<GigFeedCubit, GigFeedState>(
    'emits failure when the gig stream errors',
    setUp: () {
      when(() => repository.watchGigs())
          .thenAnswer((_) => Stream<List<Gig>>.error(Exception('offline')));
    },
    build: () => GigFeedCubit(WatchGigs(repository)),
    act: (cubit) => cubit.start(),
    wait: const Duration(milliseconds: 10),
    expect: () => [
      const GigFeedState(status: GigFeedStatus.loading),
      const GigFeedState(
        status: GigFeedStatus.failure,
        errorMessage: 'Could not load gigs. Please try again.',
      ),
    ],
  );

  blocTest<GigFeedCubit, GigFeedState>(
    'search updates the filter query',
    build: () => GigFeedCubit(WatchGigs(repository)),
    act: (cubit) => cubit.search('flutter'),
    expect: () => [const GigFeedState(filter: GigFilter(query: 'flutter'))],
  );
}
