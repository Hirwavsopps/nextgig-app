import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nextgig/features/profile/data/profile_repository.dart';
import 'package:nextgig/features/profile/domain/entities/skill.dart';
import 'package:nextgig/features/profile/domain/entities/user_profile.dart';
import 'package:nextgig/features/reviews/data/review_repository.dart';
import 'package:nextgig/features/reviews/domain/entities/review.dart';

class ProfileState extends Equatable {
  const ProfileState({
    this.profile,
    this.skills = const [],
    this.reviews = const [],
    this.error,
  });

  final UserProfile? profile;
  final List<Skill> skills;
  final List<Review> reviews;
  final String? error;

  ProfileState copyWith({
    UserProfile? profile,
    List<Skill>? skills,
    List<Review>? reviews,
    String? error,
  }) {
    return ProfileState(
      profile: profile ?? this.profile,
      skills: skills ?? this.skills,
      reviews: reviews ?? this.reviews,
      error: error,
    );
  }

  @override
  List<Object?> get props => [profile, skills, reviews, error];
}

class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit(this._profiles, this._reviews) : super(const ProfileState());

  final ProfileRepository _profiles;
  final ReviewRepository _reviews;
  StreamSubscription<UserProfile>? _profileSub;
  StreamSubscription<List<Skill>>? _skillSub;
  StreamSubscription<List<Review>>? _reviewSub;

  void watch(String uid) {
    _profileSub?.cancel();
    _skillSub?.cancel();
    _reviewSub?.cancel();
    _profileSub = _profiles
        .watchProfile(uid)
        .listen(
          (profile) => emit(state.copyWith(profile: profile)),
          onError: _fail,
        );
    _skillSub = _profiles
        .watchSkills(uid)
        .listen(
          (skills) => emit(state.copyWith(skills: skills)),
          onError: _fail,
        );
    _reviewSub = _reviews
        .watchForUser(uid)
        .listen(
          (reviews) => emit(state.copyWith(reviews: reviews)),
          onError: _fail,
        );
  }

  Future<void> saveProfile({
    required String uid,
    required String name,
    required String bio,
    required String photoUrl,
    String? location,
  }) async {
    try {
      await _profiles.updateProfile(
        uid: uid,
        name: name,
        bio: bio,
        photoUrl: photoUrl,
        location: location,
      );
    } catch (error) {
      _fail(error);
      rethrow;
    }
  }

  Future<String> saveSkill(String uid, Skill skill) async {
    try {
      return await _profiles.saveSkill(uid, skill);
    } catch (error) {
      _fail(error);
      rethrow;
    }
  }

  Future<void> deleteSkill(String uid, String skillId) async {
    try {
      await _profiles.deleteSkill(uid, skillId);
    } catch (error) {
      _fail(error);
      rethrow;
    }
  }

  Future<void> endorse({
    required String ownerId,
    required String skillId,
    required String endorserId,
    required String endorserName,
    required String relationship,
    required String note,
  }) async {
    try {
      await _profiles.endorse(
        ownerId: ownerId,
        skillId: skillId,
        endorserId: endorserId,
        endorserName: endorserName,
        relationship: relationship,
        note: note,
      );
    } on StateError {
      rethrow;
    } catch (error) {
      _fail(error);
      rethrow;
    }
  }

  void _fail(Object error) {
    emit(state.copyWith(error: 'Could not update the profile.'));
  }

  @override
  Future<void> close() async {
    await _profileSub?.cancel();
    await _skillSub?.cancel();
    await _reviewSub?.cancel();
    return super.close();
  }
}
