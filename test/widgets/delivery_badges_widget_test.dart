import 'package:delivery_express_mobility_frontend/features/driver_shared/widgets/delivery_badges_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeDelivery {
  final String id;
  final double distance;
  final int price;
  final String pickupAddress;
  final String dropoffAddress;

  _FakeDelivery(this.id, this.distance, this.price, this.pickupAddress,
      this.dropoffAddress);
}

void main() {
  testWidgets('DeliveryBadgesWidget shows nothing when empty', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
          home: Scaffold(
              body: Stack(children: [
        DeliveryBadgesWidget(deliveries: [], isPassActive: false)
      ]))),
    );

    await tester.pumpAndSettle();
    expect(find.byType(DeliveryBadgesWidget), findsOneWidget);
  });
}
