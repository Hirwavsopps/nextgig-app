class AppRoutes {
  const AppRoutes._();

  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String signup = '/signup';

  static const String home = '/home';
  static const String gigs = '/gigs';
  static const String mentors = '/mentors';
  static const String messages = '/messages';
  static String message(String id) => '/messages/$id';
  static const String profile = '/profile';
  static const String editProfile = '/profile/edit';
  static const String settings = '/profile/settings';
  static const String earnings = '/profile/earnings';
  static const String skillForm = '/profile/skill';
  static const String gigForm = '/gigs/edit';

  static const String gigDetailPattern = '/gig/:id';
  static String gigDetail(String id) => '/gig/$id';

  static const String saved = '/saved';
  static const String chatPattern = '/chat/:id';
  static String chat(String conversationId) => '/chat/$conversationId';

  static const notifications = '/notifications';
  static const String userPattern = '/user/:uid';
  static String user(String uid) => '/user/$uid';
}
