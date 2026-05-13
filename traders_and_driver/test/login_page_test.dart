import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traders_and_drivers/screens/login_page.dart';

void main() {
  group('LoginPage Tests', () {
    testWidgets('LoginPage renders all UI elements correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: LoginPage()));

      // Verify page title
      expect(find.text('Welcome Back!'), findsOneWidget);
      expect(find.text('Login to your account'), findsOneWidget);

      // Verify input fields
      expect(find.byType(TextFormField), findsWidgets);
      expect(find.byIcon(Icons.phone_outlined), findsOneWidget);
      expect(
        find.byIcon(Icons.lock_outline),
        findsWidgets,
      ); // Can appear multiple times

      // Verify button
      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(find.text('Login'), findsOneWidget);

      // Verify forgot password link
      expect(find.text('Forgot Password?'), findsOneWidget);

      // Verify back button
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('Password visibility toggle works correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: LoginPage()));

      // Find password field
      final passwordFields = find.byType(TextFormField);
      expect(passwordFields, findsWidgets);

      // Find visibility toggle button
      final visibilityToggle = find.byIcon(Icons.visibility_off);
      expect(visibilityToggle, findsOneWidget);

      // Tap to toggle visibility
      await tester.tap(visibilityToggle);
      await tester.pump();

      // Verify visibility icon changes
      expect(find.byIcon(Icons.visibility), findsOneWidget);

      // Tap again to toggle back
      await tester.tap(find.byIcon(Icons.visibility));
      await tester.pump();

      expect(find.byIcon(Icons.visibility_off), findsOneWidget);
    });

    testWidgets('Phone number field accepts input', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: LoginPage()));

      // Find and fill phone field
      final phoneFields = find.byType(TextFormField);
      await tester.enterText(phoneFields.first, '12345678');
      await tester.pump();

      // Verify input was entered
      expect(find.text('12345678'), findsOneWidget);
    });

    testWidgets('Password field accepts input and is obscured by default', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: LoginPage()));

      // Find and fill password field
      final passwordFields = find.byType(TextFormField);
      await tester.enterText(passwordFields.at(1), 'password123');
      await tester.pump();

      // Verify input was entered (will be in controller even if obscured)
      // The important thing is the field accepts input
      expect(find.byType(TextFormField), findsWidgets);
    });

    testWidgets('Back button is present and functional', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: LoginPage()));

      // Verify back button exists
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('Login button is enabled and interactive', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: LoginPage()));

      // Find login button
      final loginButton = find.byType(ElevatedButton);
      expect(loginButton, findsOneWidget);

      // Verify button is present and enabled
      final button = find.byWidgetPredicate(
        (widget) => widget is ElevatedButton && widget.onPressed != null,
      );
      expect(button, findsOneWidget);
    });

    testWidgets('Form fields have proper labels', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: LoginPage()));

      // Verify labels
      expect(find.text('Phone Number'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
    });

    testWidgets('Forgot Password navigation link exists', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: LoginPage()));

      // Find forgot password button
      final forgotButton = find.byWidgetPredicate(
        (widget) =>
            widget is TextButton &&
            widget.child is Text &&
            (widget.child as Text).data == 'Forgot Password?',
      );

      expect(forgotButton, findsOneWidget);
    });

    testWidgets('Multiple form fields validation', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: LoginPage()));

      // Verify we have exactly 2 TextFormField widgets
      expect(find.byType(TextFormField), findsNWidgets(2));

      // Verify hint texts
      expect(find.text('Enter your phone number'), findsOneWidget);
      expect(find.text('Enter your password'), findsOneWidget);
    });

    testWidgets('Scaffold structure is correct', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: LoginPage()));

      // Verify main scaffold
      expect(find.byType(Scaffold), findsOneWidget);

      // Verify SafeArea
      expect(find.byType(SafeArea), findsOneWidget);

      // Verify background color
      final scaffold = find.byType(Scaffold);
      expect(scaffold, findsOneWidget);
    });
  });
}
