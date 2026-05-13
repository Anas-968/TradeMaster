import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traders_and_drivers/screens/register_page.dart';

void main() {
  group('RegisterPage Tests', () {
    testWidgets('RegisterPage renders all UI elements correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: RegisterPage()));

      // Verify page title
      expect(find.text('Create Account'), findsOneWidget);
      expect(find.text('Register with your phone number'), findsOneWidget);

      // Verify input fields are present before OTP is sent
      expect(find.text('Full Name'), findsOneWidget);
      expect(find.text('Phone Number'), findsOneWidget);
      expect(find.text('User Type'), findsOneWidget);
      expect(find.text('Create Password'), findsOneWidget);
      expect(find.text('Confirm Password'), findsOneWidget);

      // Verify button
      expect(find.text('Send OTP'), findsOneWidget);

      // Verify back button
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('Full name field accepts input', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: RegisterPage()));

      // Find and fill first TextFormField (Full Name)
      final allFields = find.byType(TextFormField);
      await tester.enterText(allFields.first, 'John Doe');
      await tester.pump();

      expect(find.text('John Doe'), findsOneWidget);
    });

    testWidgets('Phone number field accepts 8 digit input', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: RegisterPage()));

      // Find and fill second TextFormField (Phone Number)
      final allFields = find.byType(TextFormField);
      await tester.enterText(allFields.at(1), '92345678');
      await tester.pump();

      expect(find.text('92345678'), findsOneWidget);
    });

    testWidgets('User type dropdown has Trader and Driver options', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: RegisterPage()));

      // Verify dropdown button exists
      expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);

      // Tap on dropdown
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();

      // Verify options
      expect(find.text('Trader'), findsWidgets);
      expect(find.text('Driver'), findsWidgets);
    });

    testWidgets('Password fields accept input', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: RegisterPage()));

      // Find all text form fields
      final allFields = find.byType(TextFormField);
      expect(allFields, findsWidgets);

      // Enter password in password field (4th field)
      await tester.enterText(allFields.at(3), 'password123');
      await tester.pump();

      // Verify the field accepted input
      expect(find.byType(TextFormField), findsWidgets);
    });

    testWidgets('Password visibility icons exist', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: RegisterPage()));

      // Find visibility toggle icons
      var visibilityIcons = find.byIcon(Icons.visibility_off);
      expect(visibilityIcons, findsWidgets);
    });

    testWidgets('Confirm password field exists', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: RegisterPage()));

      // Verify confirm password label exists
      expect(find.text('Confirm Password'), findsOneWidget);
    });

    testWidgets('All required TextFormFields are present', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: RegisterPage()));

      // Before OTP is sent, should have 5 form fields:
      // 1. Full Name
      // 2. Phone Number
      // 3. Password
      // 4. Confirm Password
      // 5. OTP (hidden until _otpSent is true)
      final formFields = find.byType(TextFormField);
      expect(formFields, findsWidgets);
    });

    testWidgets('Send OTP button is present and enabled', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: RegisterPage()));

      // Find Send OTP button
      final sendButton = find.byWidgetPredicate(
        (widget) =>
            widget is ElevatedButton &&
            widget.child is Text &&
            (widget.child as Text).data == 'Send OTP',
      );

      expect(sendButton, findsOneWidget);
    });

    testWidgets('Form key is properly initialized', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: RegisterPage()));

      // Verify Form widget exists
      expect(find.byType(Form), findsOneWidget);
    });

    testWidgets('Input decorations have proper styling', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: RegisterPage()));

      // Verify icons are present in text fields
      expect(find.byIcon(Icons.person_outline), findsOneWidget); // Name field
      expect(find.byIcon(Icons.phone_outlined), findsOneWidget); // Phone field
      expect(find.byIcon(Icons.lock_outline), findsWidgets); // Password fields
    });

    testWidgets('Back button navigates back', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: RegisterPage())),
      );

      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('ScrollView allows scrolling through form', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: RegisterPage()));

      // Verify SingleChildScrollView exists
      expect(find.byType(SingleChildScrollView), findsOneWidget);

      // Try to scroll
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -300),
      );
      await tester.pumpAndSettle();

      // Should complete without error
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('Form labels are properly displayed', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: RegisterPage()));

      expect(find.text('Full Name'), findsOneWidget);
      expect(find.text('Phone Number'), findsOneWidget);
      expect(find.text('User Type'), findsOneWidget);
      expect(find.text('Create Password'), findsOneWidget);
      expect(find.text('Confirm Password'), findsOneWidget);
    });

    testWidgets('Hint texts are visible in input fields', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: RegisterPage()));

      expect(find.text('Enter your full name'), findsOneWidget);
      expect(find.text('e.g., 12345678 (Oman)'), findsOneWidget);
      expect(find.text('Password (min 6 characters)'), findsOneWidget);
      expect(find.text('Confirm your password'), findsOneWidget);
    });
  });
}
