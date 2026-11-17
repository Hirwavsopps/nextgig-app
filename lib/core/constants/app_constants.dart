/// App-wide constants. Keep category / neighborhood names identical to the
/// values stored in Firestore (see docs/ERD.md).
class AppConstants {
  const AppConstants._();

  static const List<String> gigCategories = [
    'Tech',
    'Design',
    'Tutoring',
    'Photography',
    'Repair',
    'Writing',
    'Delivery',
  ];

  static const List<String> neighborhoods = [
    'Kimironko',
    'Remera',
    'Nyamirambo',
    'Kicukiro',
    'Gikondo',
    'Kacyiru',
    'Nyarutarama',
  ];

  /// Upper bound of the pay filter slider, in RWF.
  static const double maxPayFilter = 200000;
}
