import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nextgig/features/mentorship/data/mentor_repository.dart';
import 'package:nextgig/features/profile/domain/entities/user_profile.dart';

class MentorsState extends Equatable {
  const MentorsState({
    this.mentors = const [],
    this.loaded = false,
    this.error,
  });

  final List<UserProfile> mentors;
  final bool loaded;
  final String? error;

  @override
  List<Object?> get props => [mentors, loaded, error];
}

class MentorsCubit extends Cubit<MentorsState> {
  MentorsCubit(this._mentors) : super(const MentorsState());

  final MentorRepository _mentors;
  StreamSubscription<List<UserProfile>>? _sub;

  void watch() {
    _sub?.cancel();
    _sub = _mentors.watchMentors().listen(
      (mentors) => emit(MentorsState(mentors: mentors, loaded: true)),
      onError: (Object error) => emit(MentorsState(error: '$error')),
    );
  }

  @override
  Future<void> close() async {
    await _sub?.cancel();
    return super.close();
  }
}
