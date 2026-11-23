import 'package:equatable/equatable.dart';
import 'package:nextgig/features/gigs/domain/entities/gig.dart';

/// A mentor, built from the `mentorName` on gigs, e.g.
/// "David Mugisha (Senior Creative Lead)" -> name + title.
class Mentor extends Equatable {
  const Mentor({required this.fullLabel, required this.gigs});

  /// Exactly as stored on the gig (used to match requests).
  final String fullLabel;

  /// The open gigs this mentor guides.
  final List<Gig> gigs;

  String get name {
    final i = fullLabel.indexOf('(');
    return (i > 0 ? fullLabel.substring(0, i) : fullLabel).trim();
  }

  String get title {
    final open = fullLabel.indexOf('(');
    final close = fullLabel.lastIndexOf(')');
    if (open < 0 || close <= open) return 'Mentor';
    return fullLabel.substring(open + 1, close).trim();
  }

  /// Groups gigs by mentor, most gigs first. Gigs without a mentor are skipped.
  static List<Mentor> fromGigs(List<Gig> gigs) {
    final byMentor = <String, List<Gig>>{};
    for (final gig in gigs) {
      final label = gig.mentorName?.trim() ?? '';
      if (label.isEmpty) continue;
      byMentor.putIfAbsent(label, () => []).add(gig);
    }
    final mentors = [
      for (final e in byMentor.entries) Mentor(fullLabel: e.key, gigs: e.value),
    ];
    mentors.sort((a, b) => b.gigs.length.compareTo(a.gigs.length));
    return mentors;
  }

  @override
  List<Object?> get props => [fullLabel, gigs];
}

class MentorshipStatus {
  const MentorshipStatus._();

  static const String pending = 'pending';
  static const String cancelled = 'cancelled';
}

/// `mentorshipRequests/{id}`: a talent asking a gig's mentor for guidance.
class MentorshipRequest extends Equatable {
  const MentorshipRequest({
    required this.id,
    required this.talentId,
    required this.mentorName,
    required this.gigId,
    required this.gigTitle,
    required this.message,
    this.status = MentorshipStatus.pending,
    this.createdAt,
  });

  final String id;
  final String talentId;
  final String mentorName;
  final String gigId;
  final String gigTitle;
  final String message;
  final String status;
  final DateTime? createdAt;

  bool get isPending => status == MentorshipStatus.pending;

  @override
  List<Object?> get props => [
    id,
    talentId,
    mentorName,
    gigId,
    gigTitle,
    message,
    status,
    createdAt,
  ];
}
