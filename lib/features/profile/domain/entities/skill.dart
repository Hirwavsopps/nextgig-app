import 'package:equatable/equatable.dart';
import 'package:nextgig/features/verification/domain/entities/verification_status.dart';

class PortfolioItem extends Equatable {
  const PortfolioItem({
    required this.title,
    this.imageUrl = '',
    this.link = '',
  });

  final String title;
  final String imageUrl;
  final String link;

  PortfolioItem copyWith({String? title, String? imageUrl, String? link}) {
    return PortfolioItem(
      title: title ?? this.title,
      imageUrl: imageUrl ?? this.imageUrl,
      link: link ?? this.link,
    );
  }

  @override
  List<Object?> get props => [title, imageUrl, link];
}

/// A skill on a user's profile. [verified] and the verification fields are
/// only written by an authorized reviewer (see firestore.rules).
class Skill extends Equatable {
  const Skill({
    required this.id,
    required this.name,
    required this.proficiency,
    this.portfolio = const [],
    this.proofUrl,
    this.proofStoragePath,
    this.verified = false,
    this.verificationStatus,
    this.verificationId,
    this.verifiedAt,
    this.verifiedById,
    this.verifiedByName = '',
    this.verifiedByRelationship = '',
  });

  final String id;
  final String name;

  /// `beginner`, `intermediate`, or `advanced`.
  final String proficiency;
  final List<PortfolioItem> portfolio;
  final String? proofUrl;
  final String? proofStoragePath;
  final bool verified;

  /// Raw `verificationStatus` value; read it through [status].
  final String? verificationStatus;

  /// The latest verificationRequests document for this skill.
  final String? verificationId;
  final DateTime? verifiedAt;
  final String? verifiedById;
  final String verifiedByName;
  final String verifiedByRelationship;

  VerificationStatus get status =>
      VerificationStatus.parse(verificationStatus, legacyVerified: verified);

  /// Only true once a reviewer has approved the evidence.
  bool get isVerified => status == VerificationStatus.verified;

  static const proficiencies = ['beginner', 'intermediate', 'advanced'];

  @override
  List<Object?> get props => [
    id,
    name,
    proficiency,
    portfolio,
    proofUrl,
    proofStoragePath,
    verified,
    verificationStatus,
    verificationId,
    verifiedAt,
    verifiedById,
    verifiedByName,
    verifiedByRelationship,
  ];
}
