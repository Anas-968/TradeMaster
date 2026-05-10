import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/admin_page.dart';
import 'screens/driver_page.dart';
import 'screens/forgot_password_page.dart';
import 'screens/home_page.dart';

import 'screens/login_page.dart';
import 'screens/register_page.dart';
import 'screens/trader_page.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://bqerwxkixqgiofndeocy.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJxZXJ3eGtpeHFnaW9mbmRlb2N5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzcxOTYxNzIsImV4cCI6MjA5Mjc3MjE3Mn0.LZ0qKNlj9JBwlV1n3kJ33gvqzQ0ihQ1fjQltPLT8NLE',
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TradeMaster',
      theme: ThemeData(primarySwatch: Colors.blue, fontFamily: 'Poppins'),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomePage(),
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/forgot-password': (context) => const ForgotPasswordPage(),
        '/trader': (context) => const TraderPage(),
        '/driver': (context) => const DriverPage(),
        '/admin': (context) => const AdminPage(),
      },
    );
  }
}