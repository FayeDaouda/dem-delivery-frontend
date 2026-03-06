import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

/// Réponse lors de l'activation d'un pass
class PassActivationResponse {
  final DateTime? validUntil;
  final bool isPending;
  final String? transactionReference;
  final int? amount;

  PassActivationResponse({
    this.validUntil,
    this.isPending = false,
    this.transactionReference,
    this.amount,
  });
}

/// Repository pour gérer les passes
abstract class IPassRepository {
  /// Activer un pass (journalier, hebdomadaire, etc.)
  Future<PassActivationResponse> activatePass({
    required String passType,
    required String paymentMethod,
    String? phoneNumber,
    String? promoCode,
    int? price,
    String? transactionId,
    bool autoRenew = false,
    String? clientRequestId,
  });

  /// Récupérer l'état du pass actuel
  Future<DateTime?> getPassState();

  /// Vérifier si un pass est valide
  Future<bool> isPassValid();
}

/// Implémentation du PassRepository
class PassRepository implements IPassRepository {
  final Dio _dio;

  PassRepository({required Dio dio}) : _dio = dio;

  @override
  Future<PassActivationResponse> activatePass({
    required String passType,
    required String paymentMethod,
    String? phoneNumber,
    String? promoCode,
    int? price,
    String? transactionId,
    bool autoRenew = false,
    String? clientRequestId,
  }) async {
    try {
      final normalizedMethod = _normalizePaymentMethod(paymentMethod);

      if ((normalizedMethod == 'wave' || normalizedMethod == 'orange_money') &&
          (phoneNumber == null || phoneNumber.trim().isEmpty)) {
        throw DioException(
          requestOptions: RequestOptions(path: '/passes/purchase'),
          error: 'Le numéro de téléphone est requis pour Wave et Orange Money.',
        );
      }

      final payload = <String, dynamic>{
        'type': passType.toLowerCase(),
        'paymentMethod': normalizedMethod,
        'autoRenew': autoRenew,
        'clientRequestId': clientRequestId ?? _generateClientRequestId(),
      };

      if (phoneNumber != null && phoneNumber.trim().isNotEmpty) {
        payload['phoneNumber'] = phoneNumber.trim();
      }
      if (promoCode != null && promoCode.trim().isNotEmpty) {
        payload['promoCode'] = promoCode.trim();
      }
      // NOTE: 'price' ne doit JAMAIS être envoyé, il est calculé par le backend
      if (transactionId != null && transactionId.trim().isNotEmpty) {
        payload['transactionId'] = transactionId.trim();
      }

      final response = await _dio.post(
        '/passes/purchase',
        data: payload,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;

        // Vérifier le statut du paiement
        final transaction = data['transaction'];
        if (transaction is Map<String, dynamic>) {
          final transactionStatus =
              transaction['status']?.toString().toLowerCase();

          // Si paiement en attente
          if (transactionStatus == 'pending') {
            return PassActivationResponse(
              isPending: true,
              transactionReference: transaction['reference']?.toString(),
              amount: (transaction['amount'] as num?)?.toInt(),
            );
          }
        }

        // Extraire validUntil depuis pass object (succès immédiat)
        final validUntil = _extractValidUntil(data);
        return PassActivationResponse(
          validUntil:
              validUntil ?? DateTime.now().add(const Duration(hours: 24)),
          isPending: false,
        );
      }

      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
      );
    } on DioException {
      rethrow;
    }
  }

  @override
  Future<DateTime?> getPassState() async {
    try {
      final response = await _dio.get('/passes/current');

      if (response.statusCode == 200) {
        final data = response.data;

        if (data is Map<String, dynamic>) {
          final hasValidPass = data['hasValidPass'] == true;
          if (!hasValidPass) return null;

          final remainingSeconds = data['remainingSeconds'];
          if (remainingSeconds is num && remainingSeconds <= 0) {
            return null;
          }

          if (remainingSeconds is num && remainingSeconds > 0) {
            return DateTime.now()
                .add(Duration(seconds: remainingSeconds.toInt()));
          }

          final pass = data['pass'];
          if (pass is Map<String, dynamic>) {
            final status = pass['status']?.toString().toUpperCase();
            if (status != null && status != 'ACTIVE') {
              return null;
            }

            final validUntil = pass['validUntil'];
            if (validUntil != null) {
              return DateTime.tryParse(validUntil.toString());
            }
          }
        }
      }

      return null;
    } on DioException catch (e) {
      // En cas de 5xx, considérer temporairement le pass comme inactif
      // pour garder l'application stable.
      if (e.response?.statusCode != null && e.response!.statusCode! >= 500) {
        return null;
      }

      rethrow;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<bool> isPassValid() async {
    try {
      final validUntil = await getPassState();
      return validUntil != null && validUntil.isAfter(DateTime.now());
    } catch (e) {
      return false;
    }
  }

  String _normalizePaymentMethod(String rawMethod) {
    final method = rawMethod.trim().toLowerCase();
    switch (method) {
      case 'wave':
        return 'wave';
      case 'orange':
      case 'orange_money':
      case 'orangemoney':
        return 'orange_money';
      case 'yas':
      case 'free_money':
      case 'freemoney':
        return 'free_money';
      case 'cash':
        return 'cash';
      default:
        return method;
    }
  }

  DateTime? _extractValidUntil(dynamic responseData) {
    if (responseData is! Map<String, dynamic>) return null;

    // Chercher dans la structure: { pass: { validUntil: ... } }
    final pass = responseData['pass'];
    if (pass is Map<String, dynamic>) {
      final validUntilRaw = pass['validUntil'];
      if (validUntilRaw != null) {
        return DateTime.tryParse(validUntilRaw.toString());
      }
    }

    return null;
  }

  String _generateClientRequestId() {
    return const Uuid().v4();
  }
}
