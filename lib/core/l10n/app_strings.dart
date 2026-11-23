/// Strings for the screens added with settings. Auth copy stays English.
class AppStrings {
  const AppStrings._();

  static const _en = {
    'nav_home': 'Home',
    'nav_gigs': 'Gigs',
    'nav_mentors': 'Mentors',
    'nav_messages': 'Messages',
    'nav_profile': 'Profile',
    'recommended': 'Recommended for you',
    'skills_match': 'skills',
    'settings': 'Settings',
    'theme': 'Theme',
    'language': 'Language',
    'preferred_category': 'Preferred gig category',
    'load_sample': 'Load sample data',
    'earnings': 'Earnings',
    'record_earnings': 'Record earnings',
    'apply': 'Apply now',
    'skills': 'Skills',
    'reviews': 'Reviews',
  };

  static const _rw = {
    'nav_home': 'Ahabanza',
    'nav_gigs': 'Akazi',
    'nav_mentors': 'Abajyanama',
    'nav_messages': 'Ubutumwa',
    'nav_profile': 'Umwirondoro',
    'recommended': 'Byagufitiye',
    'skills_match': 'ubumenyi',
    'settings': 'Igenamiterere',
    'theme': 'Insanganyamatsiko',
    'language': 'Ururimi',
    'preferred_category': 'Icyiciro ukunda',
    'load_sample': 'Shyiramo amakuru y\'igerageza',
    'earnings': 'Amafaranga winjiza',
    'record_earnings': 'Andika amafaranga',
    'apply': 'Saba akazi',
    'skills': 'Ubumenyi',
    'reviews': 'Ibitekerezo',
  };

  static String text(String language, String key) {
    final map = language == 'rw' ? _rw : _en;
    return map[key] ?? _en[key] ?? key;
  }
}
