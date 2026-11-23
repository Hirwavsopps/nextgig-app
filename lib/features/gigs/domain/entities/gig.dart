import 'package:equatable/equatable.dart';

/// A paid gig posted by a user. Pure Dart: no Flutter or Firebase imports.
class Gig extends Equatable {
  const Gig({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.neighborhood,
    required this.pay,
    required this.requiredSkills,
    required this.posterName,
    required this.posterId,
    this.duration = '',
    this.level = '',
    this.applicantCount = 0,
    this.verifiedClient = false,
    this.escrowFunded = false,
    this.deliverables = const [],
    this.mentorName,
    this.mentorId,
    this.imageUrl,
    this.createdAt,
    this.deadline,
  });

  final String id;
  final String title;
  final String description;
  final String category;
  final String neighborhood;

  /// Pay in RWF.
  final int pay;
  final List<String> requiredSkills;
  final String posterName;

  /// Firebase Auth uid of the user who posted the gig.
  final String posterId;

  /// Free text such as "2 weeks". Empty means flexible.
  final String duration;

  /// Free text such as "Jr / Mid". Empty means open to all levels.
  final String level;

  /// Kept on the gig document for now; the applications feature may replace it.
  final int applicantCount;
  final bool verifiedClient;

  /// Recorded status only. Real mobile-money escrow is future work.
  final bool escrowFunded;
  final List<String> deliverables;
  final String? mentorName;

  /// Firebase Auth uid of the mentor on this gig, when one is attached.
  final String? mentorId;

  /// Cloudinary image URL.
  final String? imageUrl;
  final DateTime? createdAt;

  /// Optional date the work should be finished.
  final DateTime? deadline;

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    category,
    neighborhood,
    pay,
    requiredSkills,
    posterName,
    posterId,
    duration,
    level,
    applicantCount,
    verifiedClient,
    escrowFunded,
    deliverables,
    mentorName,
    mentorId,
    imageUrl,
    createdAt,
    deadline,
  ];
}
