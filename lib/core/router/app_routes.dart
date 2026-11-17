/// Route paths in one place, so nobody types string paths by hand.
class AppRoutes {
  const AppRoutes._();

  static const String login = '/login';
  static const String signup = '/signup';

  static const String home = '/home';
  static const String gigs = '/gigs';
  static const String mentors = '/mentors';
  static const String messages = '/messages';
  static const String profile = '/profile';

  static const String gigDetailPattern = '/gig/:id';
  static String gigDetail(String id) => '/gig/$id';
}
