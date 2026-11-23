/// Every photo bundled with the app, in one place.
///
/// All are free photos from Unsplash (Unsplash License: free for commercial
/// use, no attribution required). Credits: docs/IMAGE_CREDITS.md.
class AppImages {
  const AppImages._();

  static const String _dir = 'assets/images';

  // Kigali
  static const String kigaliSkyline = '$_dir/kigali_skyline.jpg';
  static const String kigaliStreet = '$_dir/kigali_street.jpg';
  static const String kigaliHills = '$_dir/kigali_hills.jpg';

  // Onboarding slides
  static const String onboardingMatch = '$_dir/onboarding_match.jpg';
  static const String onboardingConfidence = '$_dir/onboarding_confidence.jpg';
  static const String onboardingMentors = '$_dir/onboarding_mentors.jpg';

  // Client side
  static const String clientMeeting = '$_dir/client_meeting.jpg';

  /// A photo for each gig category (AppConstants.gigCategories). Gigs
  /// without their own image show the photo of their category.
  static String forCategory(String category) {
    switch (category) {
      case 'Tech':
        return '$_dir/categories/tech.jpg';
      case 'Design':
        return '$_dir/categories/design.jpg';
      case 'Tutoring':
        return '$_dir/categories/tutoring.jpg';
      case 'Photography':
        return '$_dir/categories/photography.jpg';
      case 'Repair':
        return '$_dir/categories/repair.jpg';
      case 'Writing':
        return '$_dir/categories/writing.jpg';
      case 'Delivery':
        return '$_dir/categories/delivery.jpg';
      default:
        return kigaliHills;
    }
  }
}
