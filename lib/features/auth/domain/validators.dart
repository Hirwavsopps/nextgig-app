/// Form validators for the auth screens. Pure Dart, so they are unit tested.
final RegExp _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
final RegExp _phoneRegex = RegExp(r'^\+?[0-9 ]{9,15}$');

const int minPasswordLength = 8;

bool isValidEmail(String value) => _emailRegex.hasMatch(value.trim());

String? validateEmail(String? value) {
  final email = value?.trim() ?? '';
  if (email.isEmpty) return 'Email is required';
  if (!isValidEmail(email)) return 'Enter a valid email address';
  return null;
}

String? validatePassword(String? value) {
  if (value == null || value.isEmpty) return 'Password is required';
  if (value.length < minPasswordLength) {
    return 'Password must be at least $minPasswordLength characters';
  }
  return null;
}

String? validateName(String? value) {
  if (value == null || value.trim().length < 2) return 'Enter your full name';
  return null;
}

/// Phone is optional: an empty value is valid.
String? validatePhone(String? value) {
  final phone = value?.trim() ?? '';
  if (phone.isEmpty) return null;
  if (!_phoneRegex.hasMatch(phone)) return 'Enter a valid phone number';
  return null;
}
