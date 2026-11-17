import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_it/get_it.dart';
import 'package:nextgig/core/theme/theme_cubit.dart';
import 'package:nextgig/features/gigs/data/datasources/gig_remote_data_source.dart';
import 'package:nextgig/features/gigs/data/repositories/gig_repository_impl.dart';
import 'package:nextgig/features/gigs/domain/repositories/gig_repository.dart';
import 'package:nextgig/features/gigs/domain/usecases/watch_gigs.dart';
import 'package:nextgig/features/gigs/presentation/cubit/bookmarks_cubit.dart';
import 'package:nextgig/features/gigs/presentation/cubit/gig_feed_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service locator. Every member registers their own feature's dependencies here
/// (or in a `registerXFeature()` function called from [configureDependencies]).
final GetIt sl = GetIt.instance;

Future<void> configureDependencies() async {
  // External
  final prefs = await SharedPreferences.getInstance();
  sl.registerSingleton<SharedPreferences>(prefs);
  sl.registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance);

  // Core / app-wide state
  sl.registerLazySingleton<ThemeCubit>(() => ThemeCubit(sl()));
  sl.registerLazySingleton<BookmarksCubit>(() => BookmarksCubit());

  // Feature: gigs
  sl.registerLazySingleton<GigRemoteDataSource>(
    () => GigRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<GigRepository>(() => GigRepositoryImpl(sl()));
  sl.registerLazySingleton<WatchGigs>(() => WatchGigs(sl()));
  sl.registerFactory<GigFeedCubit>(() => GigFeedCubit(sl()));
}
