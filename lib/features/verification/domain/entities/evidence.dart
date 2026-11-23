import 'package:equatable/equatable.dart';

/// What kind of proof the user is sending.
enum EvidenceType {
  professionalCertificate,
  academicCertificate,
  courseCertificate,
  portfolio,
  other;

  static EvidenceType parse(String? value) =>
      values.firstWhere((type) => type.name == value, orElse: () => other);

  String get label => switch (this) {
    professionalCertificate => 'Professional certificate',
    academicCertificate => 'Academic certificate',
    courseCertificate => 'Course completion certificate',
    portfolio => 'Portfolio screenshot or document',
    other => 'Other proof of experience',
  };
}

/// A file picked on the phone, before it is uploaded.
class EvidenceFile extends Equatable {
  const EvidenceFile({
    required this.name,
    required this.localPath,
    required this.sizeBytes,
  });

  final String name;
  final String localPath;
  final int sizeBytes;

  String get extension {
    final dot = name.lastIndexOf('.');
    return dot < 0 ? '' : name.substring(dot + 1).toLowerCase();
  }

  bool get isImage => EvidencePolicy.imageExtensions.contains(extension);

  @override
  List<Object?> get props => [name, localPath, sizeBytes];
}

/// Upload limits, checked in the app before anything is sent. The same size
/// and content types are enforced again by storage.rules.
class EvidencePolicy {
  const EvidencePolicy._();

  static const int maxBytes = 5 * 1024 * 1024;
  static const imageExtensions = {'jpg', 'jpeg', 'png'};
  static const allowedExtensions = ['pdf', 'jpg', 'jpeg', 'png'];
  static const int maxNoteLength = 500;

  /// Returns a message for the user, or null when the file can be uploaded.
  static String? validate(EvidenceFile file) {
    if (!allowedExtensions.contains(file.extension)) {
      return 'Use a PDF, JPG or PNG file.';
    }
    if (file.sizeBytes <= 0) return 'The selected file is empty.';
    if (file.sizeBytes > maxBytes) return 'The file must be smaller than 5 MB.';
    return null;
  }

  static String contentTypeFor(String extension) => switch (extension) {
    'pdf' => 'application/pdf',
    'png' => 'image/png',
    _ => 'image/jpeg',
  };

  /// Keeps letters, digits, dots, dashes and underscores so the name is a
  /// safe Storage path segment.
  static String safeFileName(String name) {
    final cleaned = name.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    if (cleaned.length <= 100) return cleaned;
    return cleaned.substring(cleaned.length - 100);
  }
}
