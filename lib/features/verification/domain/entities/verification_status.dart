/// Where a skill is in the verification workflow.
///
/// unverified → pending (evidence submitted) → verified | rejected.
/// A rejected skill can go back to pending with new evidence.
/// Stored as `verificationStatus` on users/{uid}/skills/{skillId} and as
/// `status` on verificationRequests/{id}.
enum VerificationStatus {
  unverified,
  pending,
  verified,
  rejected;

  /// Reads the stored value. Skills written before this field existed only
  /// have the `verified` flag, so [legacyVerified] keeps them verified.
  static VerificationStatus parse(
    String? value, {
    bool legacyVerified = false,
  }) {
    for (final status in values) {
      if (status.name == value) return status;
    }
    return legacyVerified ? verified : unverified;
  }

  String get label => switch (this) {
    unverified => 'Unverified',
    pending => 'Pending',
    verified => 'Verified',
    rejected => 'Rejected',
  };

  /// The owner can send evidence when nothing is under review and the skill
  /// is not already verified.
  bool get canSubmitEvidence => this == unverified || this == rejected;

  /// A reviewer can only decide on a request that is still waiting.
  bool get awaitingReview => this == pending;

  bool canTransitionTo(VerificationStatus next) => switch ((this, next)) {
    (unverified, pending) ||
    (rejected, pending) ||
    (pending, verified) ||
    (pending, rejected) => true,
    _ => false,
  };
}
