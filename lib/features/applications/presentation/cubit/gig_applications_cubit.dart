import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nextgig/features/applications/data/application_repository.dart';
import 'package:nextgig/features/applications/domain/entities/gig_application.dart';
import 'package:nextgig/features/reviews/data/review_repository.dart';

class GigApplicationsState extends Equatable {
  const GigApplicationsState({this.applications = const [], this.error});

  final List<GigApplication> applications;
  final String? error;

  @override
  List<Object?> get props => [applications, error];
}

class GigApplicationsCubit extends Cubit<GigApplicationsState> {
  GigApplicationsCubit(this._applications, this._reviews)
    : super(const GigApplicationsState());

  final ApplicationRepository _applications;
  final ReviewRepository _reviews;
  StreamSubscription<List<GigApplication>>? _sub;

  void watch(String gigId) {
    _sub?.cancel();
    _sub = _applications
        .watchByGig(gigId)
        .listen(
          (applications) =>
              emit(GigApplicationsState(applications: applications)),
          onError: (_) => emit(
            const GigApplicationsState(error: 'Could not load applications.'),
          ),
        );
  }

  Future<void> apply({
    required String gigId,
    required String gigTitle,
    required String applicantId,
    required String applicantName,
    required String posterId,
  }) async {
    try {
      await _applications.apply(
        gigId: gigId,
        gigTitle: gigTitle,
        applicantId: applicantId,
        applicantName: applicantName,
        posterId: posterId,
      );
    } on StateError catch (error) {
      emit(
        GigApplicationsState(
          applications: state.applications,
          error: error.message,
        ),
      );
      rethrow;
    } catch (_) {
      emit(
        GigApplicationsState(
          applications: state.applications,
          error: 'Could not apply.',
        ),
      );
      rethrow;
    }
  }

  Future<void> setStatus(String applicationId, ApplicationStatus status) async {
    try {
      await _applications.setStatus(applicationId, status);
    } catch (_) {
      emit(
        GigApplicationsState(
          applications: state.applications,
          error: 'Could not update the application.',
        ),
      );
      rethrow;
    }
  }

  Future<void> review({
    required String applicationId,
    required String gigId,
    required String reviewerId,
    required String revieweeId,
    required int rating,
    required String comment,
  }) async {
    try {
      await _reviews.add(
        applicationId: applicationId,
        gigId: gigId,
        reviewerId: reviewerId,
        revieweeId: revieweeId,
        rating: rating,
        comment: comment,
      );
    } catch (_) {
      emit(
        GigApplicationsState(
          applications: state.applications,
          error: 'Could not save the review.',
        ),
      );
      rethrow;
    }
  }

  @override
  Future<void> close() async {
    await _sub?.cancel();
    return super.close();
  }
}
