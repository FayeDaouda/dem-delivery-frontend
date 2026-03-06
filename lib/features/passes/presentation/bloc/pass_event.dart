part of 'pass_bloc.dart';

abstract class PassEvent extends Equatable {
  const PassEvent();

  @override
  List<Object?> get props => [];
}

/// Événement pour activer un pass avec une méthode de paiement
class ActivatePassEvent extends PassEvent {
  final String paymentMethod;
  final String passType;
  final String? phoneNumber;
  final String? promoCode;
  final int? price;
  final String? transactionId;
  final bool autoRenew;
  final String? clientRequestId;

  const ActivatePassEvent({
    required this.paymentMethod,
    this.passType = 'daily',
    this.phoneNumber,
    this.promoCode,
    this.price,
    this.transactionId,
    this.autoRenew = false,
    this.clientRequestId,
  });

  @override
  List<Object?> get props => [
        paymentMethod,
        passType,
        phoneNumber,
        promoCode,
        price,
        transactionId,
        autoRenew,
        clientRequestId,
      ];
}

/// Événement pour charger l'état du pass de l'utilisateur
class LoadPassStateEvent extends PassEvent {
  const LoadPassStateEvent();
}

/// Événement pour renouveler le pass
class RenewPassEvent extends PassEvent {
  final String paymentMethod;
  final String? phoneNumber;
  final String? promoCode;

  const RenewPassEvent({
    required this.paymentMethod,
    this.phoneNumber,
    this.promoCode,
  });

  @override
  List<Object?> get props => [paymentMethod, phoneNumber, promoCode];
}
