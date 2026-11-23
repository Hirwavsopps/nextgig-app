import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nextgig/features/applications/domain/entities/gig_application.dart';
import 'package:nextgig/features/reviews/domain/entities/review.dart';
import 'package:nextgig/features/reviews/domain/repositories/review_repository.dart';
import 'package:nextgig/features/reviews/domain/usecases/review_usecases.dart';

class ReviewFormState extends Equatable {
  const ReviewFormState({
    this.loading = true,
    this.rating = 0,
    this.existing,
    this.eligibility = ReviewEligibility.notClient,
    this.submitting = false,
    this.submitted = false,
    this.error,
  });

  final bool loading;

  /// 0 until the client taps a star.
  final int rating;

  /// The review already saved for this gig, if any.
  final Review? existing;
  final ReviewEligibility eligibility;
  final bool submitting;
  final bool submitted;
  final String? error;

  bool get canEdit =>
      !loading && eligibility == ReviewEligibility.eligible && !submitting;

  ReviewFormState copyWith({
    bool? loading,
    int? rating,
    Review? existing,
    ReviewEligibility? eligibility,
    bool? submitting,
    bool? submitted,
    String? error,
  }) => ReviewFormState(
    loading: loading ?? this.loading,
    rating: rating ?? this.rating,
    existing: existing ?? this.existing,
    eligibility: eligibility ?? this.eligibility,
    submitting: submitting ?? this.submitting,
    submitted: submitted ?? this.submitted,
    error: error,
  );

  @override
  List<Object?> get props => [
    loading,
    rating,
    existing,
    eligibility,
    submitting,
    submitted,
    error,
  ];
}

class ReviewFormCubit extends Cubit<ReviewFormState> {
  ReviewFormCubit(this._repo, this._submit) : super(const ReviewFormState());

  final ReviewRepository _repo;
  final SubmitReview _submit;
  StreamSubscription<Review?>? _sub;
  late GigApplication _application;
  late String _viewerId;

  void load({required GigApplication application, required String viewerId}) {
    _application = application;
    _viewerId = viewerId;
    _sub?.cancel();
    _sub = _repo
        .watchForApplication(application.id)
        .listen(
          (review) => emit(
            ReviewFormState(
              loading: false,
              rating: state.rating,
              existing: review,
              submitting: state.submitting,
              submitted: state.submitted,
              eligibility: checkReviewEligibility(
                application: application,
                viewerId: viewerId,
                alreadyReviewed: review != null,
              ),
            ),
          ),
          onError: (_) => emit(
            state.copyWith(
              loading: false,
              error: 'Could not check this review.',
            ),
          ),
        );
  }

  void setRating(int rating) {
    if (!state.canEdit) return;
    emit(state.copyWith(rating: rating.clamp(1, 5)));
  }

  Future<void> submit(String comment) async {
    if (!state.canEdit) return;
    emit(state.copyWith(submitting: true));
    try {
      await _submit(
        application: _application,
        reviewerId: _viewerId,
        alreadyReviewed: state.existing != null,
        rating: state.rating,
        comment: comment,
      );
      emit(state.copyWith(submitting: false, submitted: true));
    } on ReviewException catch (error) {
      emit(state.copyWith(submitting: false, error: error.message));
    } catch (_) {
      emit(
        state.copyWith(
          submitting: false,
          error: 'Could not save the review. Try again.',
        ),
      );
    }
  }

  @override
  Future<void> close() async {
    await _sub?.cancel();
    return super.close();
  }
}
