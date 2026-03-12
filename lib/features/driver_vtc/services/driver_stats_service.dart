import 'package:dio/dio.dart';

class DriverStatsService {
  final Dio _dio;

  DriverStatsService({required Dio dio}) : _dio = dio;

  /// Charger le profil du driver
  Future<Map<String, dynamic>?> loadDriverProfile() async {
    try {
      final response = await _dio.get('/users/me');
      final data = response.data;
      if (data is Map) {
        final profileData = (data['data'] as Map?) ?? data;
        return Map<String, dynamic>.from(profileData);
      }
      return data as Map<String, dynamic>?;
    } catch (e) {
      return null;
    }
  }

  /// Basculer le statut online/offline
  Future<bool> toggleOnlineStatus(bool newStatus) async {
    try {
      await _dio.patch('/users/me', data: {'isOnline': newStatus});
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Calculer les revenus du jour
  int calculateTodayEarnings(List<Map<String, dynamic>> deliveries) {
    final now = DateTime.now();
    final today = deliveries.where((e) {
      final created = DateTime.tryParse(e['createdAt']?.toString() ?? '');
      if (created == null) return false;
      return created.year == now.year &&
          created.month == now.month &&
          created.day == now.day;
    }).toList();

    return today.fold<int>(
      0,
      (sum, e) => sum + _toInt(e['gain'] ?? e['amount'] ?? e['price']),
    );
  }

  /// Convertir en int
  int _toInt(dynamic v) {
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  /// Convertir en bool
  // ignore: unused_element
  bool _toBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final v = value.toLowerCase();
      return v == 'true' || v == '1' || v == 'yes';
    }
    return false;
  }

  /// Convertir en DateTime
  // ignore: unused_element
  DateTime? _asDateTime(dynamic value) {
    if (value is DateTime) return value;
    if (value is String && value.trim().isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  /// Vérifier si le pass est encore valide
  bool isPassValid(bool hasPass, DateTime? expiresAt) {
    if (!hasPass) return false;
    if (expiresAt == null) return true;
    return expiresAt.isAfter(DateTime.now());
  }
}
