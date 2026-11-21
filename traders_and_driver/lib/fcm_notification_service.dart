import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('FCM background message: ${message.messageId}');
  debugPrint('FCM background data: ${message.data}');
}

class FcmNotificationService {
  FcmNotificationService._();

  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static bool _initialized = false;
  static String? _currentToken;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings();
    await _localNotifications.initialize(
      const InitializationSettings(android: androidSettings, iOS: darwinSettings),
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(const AndroidNotificationChannel(
          'trademaster_events',
          'TradeMaster updates',
          description: 'Load and support chat updates',
          importance: Importance.high,
        ));

    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('FCM notification permission: ${settings.authorizationStatus}');

    _currentToken = await _messaging.getToken();
    await _saveToken(_currentToken);
    _messaging.onTokenRefresh.listen((token) {
      _currentToken = token;
      _saveToken(token);
    });
    Supabase.instance.client.auth.onAuthStateChange.listen((_) {
      _saveToken(_currentToken);
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('FCM foreground message: ${message.messageId}');
      debugPrint('FCM title: ${message.notification?.title}');
      debugPrint('FCM body: ${message.notification?.body}');
      debugPrint('FCM data: ${message.data}');
      final title = message.notification?.title;
      final body = message.notification?.body;
      if (title != null || body != null) {
        _localNotifications.show(
          message.hashCode,
          title ?? 'TradeMaster',
          body ?? '',
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'trademaster_events',
              'TradeMaster updates',
              channelDescription: 'Load and support chat updates',
              importance: Importance.high,
              priority: Priority.high,
            ),
            iOS: DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
        );
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('FCM notification tapped: ${message.data}');
    });

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('FCM app opened from notification: ${initialMessage.data}');
    }
  }

  static Future<void> _saveToken(String? token) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (token == null || user == null) return;
    try {
      if (Supabase.instance.client.auth.currentUser?.id != user.id) return;
      await Supabase.instance.client.rpc('register_device_token', params: {
        'p_token': token,
        'p_platform': defaultTargetPlatform.name,
      });
    } catch (error) {
      debugPrint('Could not save FCM token: $error');
    }
  }
}
