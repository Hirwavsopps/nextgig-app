import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nextgig/features/gigs/domain/entities/gig.dart';

/// Firestore representation of a [Gig]. Field names must match docs/ERD.md.
class GigModel extends Gig {
  const GigModel({
    required super.id,
    required super.title,
    required super.description,
    required super.category,
    required super.neighborhood,
    required super.pay,
    required super.requiredSkills,
    required super.posterName,
    required super.posterId,
    required super.duration,
    required super.level,
    required super.applicantCount,
    required super.verifiedClient,
    required super.escrowFunded,
    required super.deliverables,
    super.mentorName,
    super.imageUrl,
    super.createdAt,
  });

  factory GigModel.fromMap(String id, Map<String, dynamic> map) {
    final created = map['createdAt'];
    return GigModel(
      id: id,
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      category: map['category'] as String? ?? 'Other',
      neighborhood: map['neighborhood'] as String? ?? '',
      pay: (map['pay'] as num?)?.toInt() ?? 0,
      requiredSkills: List<String>.from(
        map['requiredSkills'] as List<dynamic>? ?? const <String>[],
      ),
      posterName: map['posterName'] as String? ?? 'Anonymous',
      posterId: map['posterId'] as String? ?? '',
      duration: map['duration'] as String? ?? '',
      level: map['level'] as String? ?? '',
      applicantCount: (map['applicantCount'] as num?)?.toInt() ?? 0,
      verifiedClient: map['verifiedClient'] as bool? ?? false,
      escrowFunded: map['escrowFunded'] as bool? ?? false,
      deliverables: List<String>.from(
        map['deliverables'] as List<dynamic>? ?? const <String>[],
      ),
      mentorName: map['mentorName'] as String?,
      imageUrl: map['imageUrl'] as String?,
      createdAt: created is Timestamp ? created.toDate() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'neighborhood': neighborhood,
      'pay': pay,
      'requiredSkills': requiredSkills,
      'posterName': posterName,
      'posterId': posterId,
      'duration': duration,
      'level': level,
      'applicantCount': applicantCount,
      'verifiedClient': verifiedClient,
      'escrowFunded': escrowFunded,
      'deliverables': deliverables,
      if (mentorName != null) 'mentorName': mentorName,
      if (imageUrl != null) 'imageUrl': imageUrl,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
