import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traders_and_drivers/screens/trader_page.dart';

void main() {
  group('AddProductPage tests', () {
    testWidgets('shows required field errors when posting an empty load', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: AddProductPage()));

      await tester.tap(find.text('Post Load'));
      await tester.pump();

      expect(find.text('Enter Product name'), findsOneWidget);
      expect(find.text('Enter Pickup location'), findsOneWidget);
      expect(find.text('Enter Delivery location'), findsOneWidget);
      expect(find.text('Enter Load weight'), findsOneWidget);
    });
  });
}