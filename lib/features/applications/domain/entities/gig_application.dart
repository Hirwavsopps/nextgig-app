import 'package:equatable/equatable.dart';

enum ApplicationStatus { applied, shortlisted, hired, completed, declined }

ApplicationStatus parseApplicationStatus(String? value) {
  return ApplicationStatus.values.firstWhere(
    (status) => status.name == value,
    orElse: () => ApplicationStatus.applied,
  );
}

class GigApplication extends Equatable {
  const GigApplication({
    required this.id,
    required this.gigId,
    required this.gigTitle,
    required this.applicantId,
    required this.applicantName,
    required this.posterId,
    required this.status,
    this.createdAt,
  });

  final String id;
  final String gigId;

  /// Copied from the gig so the applications list does not re-read every gig.
  final String gigTitle;
  final String applicantId;
  final String applicantName;
  final String posterId;
  final ApplicationStatus status;
  final DateTime? createdAt;

  @override
  List<Object?> get props => [
    id,
    gigId,
    gigTitle,
    applicantId,
    applicantName,
    posterId,
    status,
    createdAt,
  ];
}
