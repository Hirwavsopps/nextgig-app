import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nextgig/features/profile/data/profile_repository.dart';
import 'package:nextgig/features/profile/domain/entities/skill.dart';
import 'package:nextgig/features/verification/domain/entities/verification_request.dart';
import 'package:nextgig/features/verification/domain/repositories/verification_repository.dart';

class SkillVerificationState extends Equatable {
  const SkillVerificationState({
    this.loading = true,
    this.skill,
    this.requests = const [],
    this.error,
  });

  final bool loading;

  /// Null once loaded means the skill was deleted.
  final Skill? skill;

  /// Submissions for this skill, newest first.
  final List<VerificationRequest> requests;
  final String? error;

  VerificationRequest? get latest => requests.isEmpty ? null : requests.first;

  SkillVerificationState copyWith({
    bool? loading,
    Skill? skill,
    bool clearSkill = false,
    List<VerificationRequest>? requests,
    String? error,
  }) => SkillVerificationState(
    loading: loading ?? this.loading,
    skill: clearSkill ? null : skill ?? this.skill,
    requests: requests ?? this.requests,
    error: error,
  );

  @override
  List<Object?> get props => [loading, skill, requests, error];
}

/// The owner's live view of one skill and its submission history.
class SkillVerificationCubit extends Cubit<SkillVerificationState> {
  SkillVerificationCubit(this._profiles, this._verifications)
    : super(const SkillVerificationState());

  final ProfileRepository _profiles;
  final VerificationRepository _verifications;
  StreamSubscription<List<Skill>>? _skillSub;
  StreamSubscription<List<VerificationRequest>>? _requestSub;

  void watch(String uid, String skillId) {
    _skillSub?.cancel();
    _requestSub?.cancel();
    emit(const SkillVerificationState());
    _skillSub = _profiles.watchSkills(uid).listen((skills) {
      final matches = skills.where((skill) => skill.id == skillId);
      emit(
        matches.isEmpty
            ? state.copyWith(loading: false, clearSkill: true)
            : state.copyWith(loading: false, skill: matches.first),
      );
    }, onError: (_) => _fail('Could not load this skill.'));
    _requestSub = _verifications
        .watchForSkill(uid, skillId)
        .listen(
          (requests) => emit(state.copyWith(requests: requests)),
          onError: (_) => _fail('Could not load your submissions.'),
        );
  }

  void _fail(String message) =>
      emit(state.copyWith(loading: false, error: message));

  @override
  Future<void> close() async {
    await _skillSub?.cancel();
    await _requestSub?.cancel();
    return super.close();
  }
}
