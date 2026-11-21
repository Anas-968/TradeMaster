import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/admin_page.dart';
import 'screens/driver_page.dart';
import 'screens/forgot_password_flow.dart';
import 'screens/home_page.dart';
import 'screens/change_password_page.dart';
import 'screens/assistant_chat_page.dart';
import 'screens/support_chat_page.dart';
import 'screens/login_page.dart';
import 'screens/register_page.dart';
import 'screens/reset_password_page.dart';
import 'screens/trader_page.dart';
import 'theme_controller.dart';
import 'language_controller.dart';
import 'package:firebase_core/firebase_core.dart';
import 'fcm_notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('🔥 Initializing Firebase...');
  await Firebase.initializeApp();
  debugPrint('✅ Firebase initialized');
  await Supabase.initialize(
    url: 'https://bqerwxkixqgiofndeocy.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJxZXJ3eGtpeHFnaW9mbmRlb2N5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzcxOTYxNzIsImV4cCI6MjA5Mjc3MjE3Mn0.LZ0qKNlj9JBwlV1n3kJ33gvqzQ0ihQ1fjQltPLT8NLE',
  );
  await FcmNotificationService.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        AppThemeController.instance,
        AppLanguageController.instance,
      ]),
      builder: (context, _) => MaterialApp(
        title: 'TradeMaster',
        locale: AppLanguageController.instance.locale,
        supportedLocales: const [Locale('en'), Locale('ar')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        debugShowCheckedModeBanner: false,
        themeMode: AppThemeController.instance.isDarkMode
            ? ThemeMode.dark
            : ThemeMode.light,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1A237E)),
          fontFamily: 'Poppins',
          useMaterial3: true,
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF7986CB),
            brightness: Brightness.dark,
          ),
          fontFamily: 'Poppins',
          useMaterial3: true,
        ),
        builder: (context, child) => Directionality(
          textDirection: AppLanguageController.instance.textDirection,
          child: child ?? const SizedBox.shrink(),
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const HomePage(),
          '/home': (context) => const HomePage(),
          '/login': (context) => const LoginPage(),
          '/register': (context) => const RegisterPage(),
          '/forgot-password': (context) => const ForgotPasswordFlowPage(),
          '/reset-password': (context) =>
              const ResetPasswordPage(returnToLoginOnBack: false),
          '/trader': (context) => const TraderPage(),
          '/driver': (context) => const DriverPage(),
          '/admin': (context) => const AdminPage(),
          '/change-password': (context) => const ChangePasswordPage(),
          '/assistant': (context) => const AssistantChatPage(),
          '/support': (context) => const SupportChatPage(),
        },
      ),
    );
  }
}
