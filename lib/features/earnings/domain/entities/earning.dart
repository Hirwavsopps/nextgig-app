import 'package:equatable/equatable.dart';

class Earning extends Equatable {
  const Earning({
    required this.id,
    required this.amount,
    required this.gigTitle,
    this.gigId = '',
    this.mobileMoneyRef = '',
    this.createdAt,
  });

  final String id;
  final int amount;
  final String gigTitle;
  final String gigId;
  final String mobileMoneyRef;
  final DateTime? createdAt;

  @override
  List<Object?> get props => [
    id,
    amount,
    gigTitle,
    gigId,
    mobileMoneyRef,
    createdAt,
  ];
}
