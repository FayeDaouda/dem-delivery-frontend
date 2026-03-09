import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/pass_repository.dart';

part 'pass_event.dart';
part 'pass_state.dart';

class PassBloc extends Bloc<PassEvent, PassState> {
  final PassRepository _passRepository;

  PassBloc({required PassRepository passRepository})
      : _passRepository = passRepository,
        super(const PassInitial()) {
    on<ActivatePassEvent>(_onActivatePass);
    on<LoadPassStateEvent>(_onLoadPassState);
    on<RenewPassEvent>(_onRenewPass);
  }

  /// Activer un pass journalier
  Future<void> _onActivatePass(
    ActivatePassEvent event,
    Emitter<PassState> emit,
  ) async {
    // 🚀 Optimistic update: afficher le pass immédiatement (24h par défaut)
    final optimisticValidUntil = DateTime.now().add(const Duration(hours: 24));
    emit(PassActivationSuccess(validUntil: optimisticValidUntil));
    emit(PassActive(validUntil: optimisticValidUntil));

    try {
      final response = await _passRepository.activatePass(
        passType: event.passType,
        paymentMethod: event.paymentMethod,
        phoneNumber: event.phoneNumber,
        promoCode: event.promoCode,
        price: event.price,
        transactionId: event.transactionId,
        autoRenew: event.autoRenew,
        clientRequestId: event.clientRequestId,
      );

      if (response.isPending) {
        // Paiement en attente - afficher un état pending
        emit(PassActivationPending(
          reference: response.transactionReference ?? 'UNKNOWN',
          amount: response.amount ?? 0,
        ));
      } else {
        // Paiement succès - mettre à jour avec la date réelle du backend
        final validUntil = response.validUntil ?? optimisticValidUntil;
        emit(PassActivationSuccess(validUntil: validUntil));
        emit(PassActive(validUntil: validUntil));
      }
    } on DioException catch (e) {
      final message = e.response?.data?['message'] ??
          e.response?.data?['error'] ??
          e.message ??
          'Impossible d\'activer le pass';

      emit(PassError(message: message.toString()));
    } catch (e) {
      emit(PassError(message: e.toString()));
    }
  }

  /// Charger l'état actuel du pass
  Future<void> _onLoadPassState(
    LoadPassStateEvent event,
    Emitter<PassState> emit,
  ) async {
    // Ne pas émettre de Loading si on est en polling (pour éviter UI flicker)
    if (state is! PassActive && state is! PassInactive) {
      emit(const PassLoading());
    }

    try {
      final result = await _passRepository.getPassState();

      if (result != null) {
        emit(PassActive(validUntil: result));
      } else {
        emit(const PassInactive());
      }
    } on DioException {
      // En polling : silencieusement ignorer les erreurs 500 pour ne pas blocker l'app
      // Le state précédent reste valid jusqu'au prochain succès
      // Ne pas émettre PassError pour ne pas affecter l'UI
    } catch (_) {
      // Ignorer silencieusement les erreurs non bloquantes du polling
    }
  }

  /// Renouveler un pass expiré
  Future<void> _onRenewPass(
    RenewPassEvent event,
    Emitter<PassState> emit,
  ) async {
    final optimisticValidUntil = DateTime.now().add(const Duration(hours: 24));
    emit(PassActivationSuccess(validUntil: optimisticValidUntil));
    emit(PassActive(validUntil: optimisticValidUntil));

    try {
      final response = await _passRepository.activatePass(
        passType: 'daily',
        paymentMethod: event.paymentMethod,
        phoneNumber: event.phoneNumber,
        promoCode: event.promoCode,
      );

      if (response.isPending) {
        emit(PassActivationPending(
          reference: response.transactionReference ?? 'UNKNOWN',
          amount: response.amount ?? 0,
        ));
      } else {
        final validUntil = response.validUntil ?? optimisticValidUntil;
        emit(PassActivationSuccess(validUntil: validUntil));
        emit(PassActive(validUntil: validUntil));
      }
    } catch (e) {
      emit(PassError(message: e.toString()));
    }
  }
}
