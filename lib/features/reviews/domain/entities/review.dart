import 'package:equatable/equatable.dart';

class Review extends Equatable {
  const Review({
    required this.id,
    required this.gigId,
    required this.applicationId,
    required this.reviewerId,
    required this.revieweeId,
    required this.rating,
    required this.comment,
    this.createdAt,
  });

  final String id;
  final String gigId;
  final String applicationId;
  final String reviewerId;
  final String revieweeId;
  final int rating;
  final String comment;
  final DateTime? createdAt;

  @override
  List<Object?> get props => [
    id,
    gigId,
    applicationId,
    reviewerId,
    revieweeId,
    rating,
    comment,
    createdAt,
  ];
}
