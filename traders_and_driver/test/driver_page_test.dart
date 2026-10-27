import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traders_and_drivers/screens/driver_page.dart';

void main() {
  group('AvailableLoadsPage tests', () {
    testWidgets('shows an empty state when no loads are available', (
      WidgetTester tester,
    ) async {
      final store = DriverLoadStore.instance;
      store.loads.clear();
      store.isLoading = false;
      store.error = null;

      await tester.pumpWidget(const MaterialApp(home: AvailableLoadsPage()));

      expect(find.text('There are no available loads right now.'), findsOneWidget);
    });
  });
}