import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/pass.dart';
import '../../domain/usecases/passes_usecases.dart';

part 'passes_state.dart';

class PassesCubit extends Cubit<PassesState> {
  final FetchAvailablePassesUseCase fetchAvailablePassesUseCase;
  final FetchUserPassesUseCase fetchUserPassesUseCase;
  final ActivatePassUseCase activatePassUseCase;
  final DeactivatePassUseCase deactivatePassUseCase;
  final GetPassDetailsUseCase getPassDetailsUseCase;

  PassesCubit({
    required this.fetchAvailablePassesUseCase,
    required this.fetchUserPassesUseCase,
    required this.activatePassUseCase,
    required this.deactivatePassUseCase,
    required this.getPassDetailsUseCase,
  }) : super(const PassesInitial());

  Future<void> fetchAvailablePasses() async {
    if (state is! AvailablePassesLoaded) {
      emit(const PassesLoading());
    }
    try {
      final passes = await fetchAvailablePassesUseCase();
      emit(AvailablePassesLoaded(passes: passes));
    } catch (e) {
      emit(PassesFailure(message: e.toString()));
    }
  }

  Future<void> fetchUserPasses() async {
    if (state is! UserPassesLoaded) {
      emit(const PassesLoading());
    }
    try {
      final passes = await fetchUserPassesUseCase();
      emit(UserPassesLoaded(passes: passes));
    } catch (e) {
      emit(PassesFailure(message: e.toString()));
    }
  }

  Future<void> activatePass(String passId) async {
    // Pas de loading plein écran pour garder une UX instantanée
    try {
      final pass = await activatePassUseCase(passId);
      emit(PassActivated(pass: pass));
    } catch (e) {
      emit(PassesFailure(message: e.toString()));
    }
  }

  Future<void> deactivatePass(String passId) async {
    try {
      await deactivatePassUseCase(passId);
      await fetchUserPasses();
    } catch (e) {
      emit(PassesFailure(message: e.toString()));
    }
  }

  Future<void> getPassDetails(String passId) async {
    if (state is! PassDetailsLoaded) {
      emit(const PassesLoading());
    }
    try {
      final pass = await getPassDetailsUseCase(passId);
      emit(PassDetailsLoaded(pass: pass));
    } catch (e) {
      emit(PassesFailure(message: e.toString()));
    }
  }
}
