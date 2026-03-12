import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:delivery_express_mobility_frontend/features/driver_shared/widgets/floating_header_widget.dart';

void main() {
  testWidgets('FloatingHeaderWidget renders without error', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              FloatingHeaderWidget(
                driverName: 'Test',
                isOnline: true,
                gpsActive: true,
                batteryLevel: 50,
                dailyEarnings: 1000,
                onToggleOnline: () {},
                onNotificationTap: () {},
              ),
            ],
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Bonjour Test'), findsOneWidget);
    expect(find.text('En ligne'), findsOneWidget);
  });
}
