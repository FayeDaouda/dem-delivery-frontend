import 'package:delivery_express_mobility_frontend/core/services/socket_service.dart';
import 'package:delivery_express_mobility_frontend/features/auth/presentation/pages/onboarding_page.dart';
import 'package:delivery_express_mobility_frontend/features/deliveries/data/datasources/deliveries_local_data_source.dart';
import 'package:delivery_express_mobility_frontend/features/deliveries/data/datasources/deliveries_remote_data_source.dart';
import 'package:delivery_express_mobility_frontend/features/deliveries/data/models/delivery_model.dart';
import 'package:delivery_express_mobility_frontend/features/deliveries/data/repositories/deliveries_repository_impl.dart';
import 'package:delivery_express_mobility_frontend/features/deliveries/domain/entities/delivery.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Integration - Offline / WebSocket / Onboarding', () {
    test('Offline fallback returns cached deliveries when API down', () async {
      final local = _FakeLocalDataSource(
        cached: [
          Delivery(
            id: 'd1',
            pickupAddress: 'A',
            deliveryAddress: 'B',
            status: 'PENDING',
            clientName: 'Client 1',
            clientPhone: '770000000',
            amount: 2500,
            createdAt: DateTime.now(),
          ),
        ],
      );
      final remote = _FailingRemoteDataSource();

      final repository = DeliveriesRepositoryImpl(
        remoteDataSource: remote,
        localDataSource: local,
      );

      final result = await repository.fetchDeliveries();
      expect(result, isNotEmpty);
      expect(result.first.id, 'd1');
    });

    test('WebSocketEvent parses backend event mapping', () {
      final event = WebSocketEvent.fromJson({
        'type': 'delivery_updated',
        'data': {'delivery_id': 'd55'},
      });

      expect(event.type, WebSocketEventType.deliveryStatusChanged);
      expect(event.name, 'delivery_updated');
      expect(event.data['delivery_id'], 'd55');
    });

    testWidgets('Onboarding persists completion flag', (tester) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(
        MaterialApp(
          home: const OnboardingPage(),
          routes: {
            '/login': (_) => const Scaffold(body: SizedBox.shrink()),
          },
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Bienvenue !'), findsOneWidget);
      await tester.tap(find.text('Commencer'));
      await tester.pump(const Duration(milliseconds: 300));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('hasSeenOnboarding'), true);
    });
  });
}

class _FailingRemoteDataSource implements DeliveriesRemoteDataSource {
  @override
  Future<List<DeliveryModel>> fetchDeliveries() async {
    throw Exception('Network down');
  }

  @override
  Future<DeliveryModel> getDeliveryDetails(String id) async {
    throw Exception('Network down');
  }

  @override
  Future<void> updateDeliveryStatus(String id, String status) async {
    throw Exception('Network down');
  }
}

class _FakeLocalDataSource implements DeliveriesLocalDataSource {
  List<Delivery> cached;

  _FakeLocalDataSource({required this.cached});

  @override
  Future<void> cacheDeliveries(List<Delivery> deliveries) async {
    cached = deliveries;
  }

  @override
  Future<void> clearCache() async {
    cached = [];
  }

  @override
  Future<Delivery?> getCachedDeliveryById(String id) async {
    for (final d in cached) {
      if (d.id == id) return d;
    }
    return null;
  }

  @override
  Future<List<Delivery>> getCachedDeliveries() async => cached;

  @override
  Future<void> updateCachedDeliveryStatus(String id, String newStatus) async {
    cached = cached
        .map(
          (d) => d.id == id
              ? Delivery(
                  id: d.id,
                  pickupAddress: d.pickupAddress,
                  deliveryAddress: d.deliveryAddress,
                  status: newStatus,
                  clientName: d.clientName,
                  clientPhone: d.clientPhone,
                  amount: d.amount,
                  createdAt: d.createdAt,
                  completedAt: d.completedAt,
                  distance: d.distance,
                  estimatedTime: d.estimatedTime,
                )
              : d,
        )
        .toList();
  }
}
