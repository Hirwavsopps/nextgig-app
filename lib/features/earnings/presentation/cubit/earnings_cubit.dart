import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nextgig/features/earnings/data/earnings_repository.dart';
import 'package:nextgig/features/earnings/domain/entities/earning.dart';

class EarningsState extends Equatable {
  const EarningsState({this.earnings = const [], this.error});

  final List<Earning> earnings;
  final String? error;

  int get total => earnings.fold(0, (sum, earning) => sum + earning.amount);

  @override
  List<Object?> get props => [earnings, error];
}

class EarningsCubit extends Cubit<EarningsState> {
  EarningsCubit(this._repository) : super(const EarningsState());

  final EarningsRepository _repository;
  StreamSubscription<List<Earning>>? _sub;

  void watch(String uid) {
    _sub?.cancel();
    _sub = _repository
        .watch(uid)
        .listen(
          (earnings) => emit(EarningsState(earnings: earnings)),
          onError: (_) =>
              emit(const EarningsState(error: 'Could not load earnings.')),
        );
  }

  Future<void> add({
    required String uid,
    required int amount,
    required String gigTitle,
    String gigId = '',
    String mobileMoneyRef = '',
  }) async {
    try {
      await _repository.add(
        uid: uid,
        amount: amount,
        gigTitle: gigTitle,
        gigId: gigId,
        mobileMoneyRef: mobileMoneyRef,
      );
    } catch (_) {
      emit(
        EarningsState(
          earnings: state.earnings,
          error: 'Could not save the earning.',
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
