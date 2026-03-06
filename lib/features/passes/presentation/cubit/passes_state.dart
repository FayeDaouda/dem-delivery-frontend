part of 'passes_cubit.dart';

abstract class PassesState extends Equatable {
  const PassesState();

  @override
  List<Object?> get props => [];
}

class PassesInitial extends PassesState {
  const PassesInitial();
}

class PassesLoading extends PassesState {
  const PassesLoading();
}

class AvailablePassesLoaded extends PassesState {
  final List<Pass> passes;

  const AvailablePassesLoaded({required this.passes});

  @override
  List<Object?> get props => [passes];
}

class UserPassesLoaded extends PassesState {
  final List<Pass> passes;

  const UserPassesLoaded({required this.passes});

  @override
  List<Object?> get props => [passes];
}

class PassDetailsLoaded extends PassesState {
  final Pass pass;

  const PassDetailsLoaded({required this.pass});

  @override
  List<Object?> get props => [pass];
}

class PassActivated extends PassesState {
  final Pass pass;

  const PassActivated({required this.pass});

  @override
  List<Object?> get props => [pass];
}

class PassesFailure extends PassesState {
  final String message;

  const PassesFailure({required this.message});

  @override
  List<Object?> get props => [message];
}
