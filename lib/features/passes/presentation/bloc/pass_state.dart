part of 'pass_bloc.dart';

abstract class PassState extends Equatable {
  const PassState();

  @override
  List<Object?> get props => [];
}

/// État initial
class PassInitial extends PassState {
  const PassInitial();
}

/// État de chargement
class PassLoading extends PassState {
  const PassLoading();
}

/// État quand le pass est inactif
class PassInactive extends PassState {
  const PassInactive();
}

/// État quand le pass est actif
class PassActive extends PassState {
  final DateTime validUntil;
  final String? passType;

  const PassActive({
    required this.validUntil,
    this.passType = 'DAILY',
  });

  @override
  List<Object?> get props => [validUntil, passType];
}

/// État d'erreur
class PassError extends PassState {
  final String message;

  const PassError({required this.message});

  @override
  List<Object?> get props => [message];
}

/// État de succès (après activation)
class PassActivationSuccess extends PassState {
  final DateTime validUntil;

  const PassActivationSuccess({required this.validUntil});

  @override
  List<Object?> get props => [validUntil];
}

/// État quand le paiement est en attente
class PassActivationPending extends PassState {
  final String reference;
  final int amount;

  const PassActivationPending({
    required this.reference,
    required this.amount,
  });

  @override
  List<Object?> get props => [reference, amount];
}
