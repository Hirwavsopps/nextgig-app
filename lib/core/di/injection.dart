import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:nextgig/core/cloudinary/cloudinary_uploader.dart';
import 'package:nextgig/core/settings/settings_cubit.dart';
import 'package:nextgig/core/storage/cv_uploader.dart';
import 'package:nextgig/core/storage/proof_uploader.dart';
import 'package:nextgig/core/theme/theme_cubit.dart';
import 'package:nextgig/features/applications/data/application_repository.dart';
import 'package:nextgig/features/applications/presentation/cubit/gig_applications_cubit.dart';
import 'package:nextgig/features/earnings/data/earnings_repository.dart';
import 'package:nextgig/features/earnings/presentation/cubit/earnings_cubit.dart';
import 'package:nextgig/features/postings/presentation/cubit/postings_cubit.dart';
import 'package:nextgig/features/profile/data/profile_repository.dart';
import 'package:nextgig/features/profile/presentation/cubit/cv_cubit.dart';
import 'package:nextgig/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:nextgig/features/reviews/data/review_repository.dart';
import 'package:nextgig/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:nextgig/features/auth/domain/repositories/auth_repository.dart';
import 'package:nextgig/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:nextgig/features/gigs/data/datasources/gig_remote_data_source.dart';
import 'package:nextgig/features/gigs/data/repositories/bookmark_repository_impl.dart';
import 'package:nextgig/features/gigs/data/repositories/gig_repository_impl.dart';
import 'package:nextgig/features/gigs/domain/repositories/bookmark_repository.dart';
import 'package:nextgig/features/gigs/domain/repositories/gig_repository.dart';
import 'package:nextgig/features/gigs/domain/usecases/watch_gigs.dart';
import 'package:nextgig/features/gigs/presentation/cubit/bookmarks_cubit.dart';
import 'package:nextgig/features/gigs/presentation/cubit/gig_feed_cubit.dart';
import 'package:nextgig/features/mentorship/data/repositories/mentorship_repository_impl.dart';
import 'package:nextgig/features/mentorship/domain/repositories/mentorship_repository.dart';
import 'package:nextgig/features/mentorship/presentation/cubit/mentorship_cubit.dart';
import 'package:nextgig/features/messages/data/repositories/chat_repository_impl.dart';
import 'package:nextgig/features/messages/domain/repositories/chat_repository.dart';
import 'package:nextgig/features/messages/domain/usecases/chat_usecases.dart';
import 'package:nextgig/features/messages/presentation/cubit/chat_cubit.dart';
import 'package:nextgig/features/messages/presentation/cubit/conversations_cubit.dart';
import 'package:nextgig/features/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nextgig/features/notifications/data/datasources/notification_remote_data_source.dart';
import 'package:nextgig/features/notifications/data/repositories/notification_repository_impl.dart';
import 'package:nextgig/features/notifications/domain/repositories/notification_repository.dart';
import 'package:nextgig/features/notifications/domain/usecases/notification_usecases.dart';
import 'package:nextgig/features/notifications/presentation/cubit/notifications_cubit.dart';

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
  sl.registerLazySingleton<SettingsCubit>(() => SettingsCubit(sl()));
  sl.registerLazySingleton<OnboardingCubit>(() => OnboardingCubit(sl()));
  sl.registerLazySingleton<CloudinaryUploader>(() => CloudinaryUploader());
  sl.registerLazySingleton<FirebaseStorage>(() => FirebaseStorage.instance);
  sl.registerLazySingleton<ProofUploader>(() => ProofUploader(sl()));
  sl.registerLazySingleton<CvUploader>(() => CvUploader(sl()));
  sl.registerLazySingleton<BookmarkRepository>(
    () => BookmarkRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<BookmarksCubit>(
    () => BookmarksCubit(
      store: sl(),
      userIds: sl<FirebaseAuth>().authStateChanges().map((user) => user?.uid),
    ),
  );

  // Feature: auth
  sl.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(sl(), sl()),
  );
  sl.registerLazySingleton<AuthCubit>(() => AuthCubit(sl()));

  // Feature: gigs
  sl.registerLazySingleton<GigRemoteDataSource>(
    () => GigRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<GigRepository>(() => GigRepositoryImpl(sl()));
  sl.registerLazySingleton<WatchGigs>(() => WatchGigs(sl()));
  sl.registerFactory<GigFeedCubit>(() => GigFeedCubit(sl()));

  // Feature: notifications
  sl.registerLazySingleton<NotificationRemoteDataSource>(
    () => NotificationRemoteDataSource(sl()),
  );
  sl.registerLazySingleton<NotificationRepository>(
    () => NotificationRepositoryImpl(sl(), sl()), // (remote, FirebaseAuth)
  );
  sl.registerLazySingleton<WatchNotifications>(() => WatchNotifications(sl()));
  sl.registerLazySingleton<MarkNotificationRead>(
    () => MarkNotificationRead(sl()),
  );
  sl.registerLazySingleton<MarkAllNotificationsRead>(
    () => MarkAllNotificationsRead(sl()),
  );
  sl.registerLazySingleton<DeleteNotification>(() => DeleteNotification(sl()));
  sl.registerLazySingleton<SendNotification>(() => SendNotification(sl()));

  sl.registerLazySingleton<NotificationsCubit>(
    () => NotificationsCubit(
      watch: sl(),
      markRead: sl(),
      markAllRead: sl(),
      delete: sl(),
    ),
  );
  sl.registerLazySingleton<ProfileRepository>(
    () => ProfileRepository(sl(), sl()),
  );
  sl.registerLazySingleton<ReviewRepository>(() => ReviewRepository(sl()));
  sl.registerLazySingleton<ApplicationRepository>(
    () => ApplicationRepository(sl()),
  );
  sl.registerLazySingleton<EarningsRepository>(() => EarningsRepository(sl()));
  sl.registerFactory<ProfileCubit>(() => ProfileCubit(sl(), sl()));
  sl.registerFactory<CvCubit>(() => CvCubit(sl(), sl()));
  sl.registerFactory<PostingsCubit>(() => PostingsCubit(sl(), sl()));
  sl.registerFactory<GigApplicationsCubit>(
    () => GigApplicationsCubit(sl(), sl()),
  );
  sl.registerFactory<EarningsCubit>(() => EarningsCubit(sl()));

  // Feature: messages
  sl.registerLazySingleton<ChatRepository>(() => ChatRepositoryImpl(sl()));
  sl.registerLazySingleton<WatchConversations>(() => WatchConversations(sl()));
  sl.registerLazySingleton<WatchMessages>(() => WatchMessages(sl()));
  sl.registerLazySingleton<OpenConversation>(() => OpenConversation(sl()));
  sl.registerLazySingleton<SendMessage>(() => SendMessage(sl()));
  sl.registerFactory<ConversationsCubit>(() => ConversationsCubit(sl()));
  sl.registerFactory<ChatCubit>(() => ChatCubit(sl(), sl()));

  // Feature: mentorship
  sl.registerLazySingleton<MentorshipRepository>(
    () => MentorshipRepositoryImpl(sl()),
  );
  sl.registerFactory<MentorshipCubit>(() => MentorshipCubit(sl(), sl()));
}
