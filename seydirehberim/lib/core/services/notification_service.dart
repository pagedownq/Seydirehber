import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'daily_notification_service.dart';

import '../services/log_service.dart';

typedef NavigateToCallback = void Function(String route);

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  NavigateToCallback? _navigateTo;
  String? _pendingRoute;

  set navigateTo(NavigateToCallback? callback) {
    _navigateTo = callback;
    if (_navigateTo != null && _pendingRoute != null) {
      final route = _pendingRoute!;
      _pendingRoute = null;
      _navigateTo!(route);
    }
  }

  NavigateToCallback? get navigateTo => _navigateTo;
  FlutterLocalNotificationsPlugin get localNotificationsPlugin => _localNotificationsPlugin;

  static const String channelId = 'seydirehberim_notifications';

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    channelId,
    'Seydi Rehber Bildirimleri',
    description: 'Şehir duyuruları ve önemli bildirimler için kullanılır.',
    importance: Importance.max,
  );

  static const String _installationDateKey = 'installationDate';

  Future<void> initialize() async {
    // 1. Initialize First Use Date if not set
    await _initInstallationDate();

    // Request permissions for Android 13+
    if (Platform.isAndroid) {
      final androidPlugin = _localNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.createNotificationChannel(_channel);
    }

    // 2. Initialize local notifications
    const initializationSettingsAndroid =
        AndroidInitializationSettings('ic_stat_s');
    const initializationSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        if (details.payload != null) {
          if (navigateTo != null) {
            navigateTo!(details.payload!);
          } else {
            _pendingRoute = details.payload;
          }
        }
      },
    );

    // Set foreground presentation options (always do this on init, it doesn't prompt)
    if (Platform.isIOS) {
      await _firebaseMessaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    // 2. Handle deep link when app is terminated
    RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      LogService().notification('App opened from terminated state via message: ${initialMessage.notification?.title}');
      _handleMessage(initialMessage);
    }

    // 3. Handle deep link when app is in background/background
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      LogService().notification('App opened from background via message: ${message.notification?.title}');
      _handleMessage(message);
    });


    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Listen to foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      LogService().notification('Foreground message received: ${message.notification?.title}');
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null) {
        String? screen = message.data['screen'];
        
        _localNotificationsPlugin.show(
          id: notification.hashCode,
          title: notification.title,
          body: notification.body,
          notificationDetails: NotificationDetails(
            android: android != null ? AndroidNotificationDetails(
              _channel.id,
              _channel.name,
              channelDescription: _channel.description,
              icon: android.smallIcon,
            ) : null,
            iOS: const DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          payload: screen,
        );
      }
    });

    // Get FCM token
    if (Platform.isIOS) {
      // Give APNs time to register and produce a token for FCM to use
      // This is critical for iOS push notifications to work
      String? apnsToken;
      int retryCount = 0;
      while (apnsToken == null && retryCount < 3) {
        apnsToken = await _firebaseMessaging.getAPNSToken();
        if (apnsToken == null) {
          debugPrint('APNs token is not ready, waiting (Attempt ${retryCount + 1})...');
          await Future.delayed(const Duration(seconds: 2));
          retryCount++;
        }
      }
      
      if (apnsToken != null) {
        LogService().success('APNs Token acquired successfully: $apnsToken');
      } else {
        LogService().error('CRITICAL: APNs token could not be acquired after multiple attempts.');
      }
    }

    String? token = await _firebaseMessaging.getToken();
    if (token != null) {
      LogService().success('FCM Token acquired: $token');
      final isEnabled = await isNotificationsEnabled();
      await _saveTokenToFirestore(token, isEnabled: isEnabled);
      
      // Handle topic subscription based on user preference
      if (isEnabled) {
        await _firebaseMessaging.subscribeToTopic('all');
        debugPrint('Auto-subscribed to "all" topic on init');
      } else {
        await _firebaseMessaging.unsubscribeFromTopic('all');
        debugPrint('Auto-unsubscribed from "all" topic on init');
      }
    }

    // --- Reliability Boost: Listen to Auth Changes ---
    // This ensures that when a user logs in or out, the token is instantly updated in Firestore
    FirebaseAuth.instance.authStateChanges().listen((User? user) async {
      String? currentToken = await _firebaseMessaging.getToken();
      if (currentToken != null) {
        final enabled = await isNotificationsEnabled();
        await _saveTokenToFirestore(currentToken, isEnabled: enabled);
        debugPrint('FCM Token sync triggered by Auth Change for: ${user?.email ?? "Guest"}');
      }
    });

    // --- Reliability Boost: Listen to Token Refresh ---
    // In rare cases where Firebase refreshes the token while app is running
    _firebaseMessaging.onTokenRefresh.listen((newToken) async {
      final enabled = await isNotificationsEnabled();
      await _saveTokenToFirestore(newToken, isEnabled: enabled);
      debugPrint('FCM Token refreshed and synced in Firestore');
    });
  }

  Future<void> _initInstallationDate() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString('installationDate') == null) {
      // First time opening the app
      final now = DateTime.now().toIso8601String();
      await prefs.setString(_installationDateKey, now);
    }
  }

  Future<DateTime?> getInstallationDate() async {
    final prefs = await SharedPreferences.getInstance();
    final dateStr = prefs.getString(_installationDateKey);
    if (dateStr != null) {
      return DateTime.parse(dateStr);
    }
    return null;
  }

  // --- OOB Notification Toggle Logic ---
  static const String _notificationsEnabledKey = 'notifications_enabled';

  Future<bool> isNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    // Default to true if not set
    return prefs.getBool(_notificationsEnabledKey) ?? true;
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsEnabledKey, enabled);

    // Update Firestore status
    final token = await _firebaseMessaging.getToken();
    if (token != null) {
      await _saveTokenToFirestore(token, isEnabled: enabled);
    }

    if (enabled) {
      await _firebaseMessaging.subscribeToTopic('all');
      debugPrint('Subscribed to "all" topic');
      // Ana bildirimler açıldığında günlük bildirimleri de yeniden planla
      DailyNotificationService()
          .scheduleDailyNotifications()
          .catchError((e) => debugPrint('DailyNotif reschedule error: $e'));
    } else {
      await _firebaseMessaging.unsubscribeFromTopic('all');
      debugPrint('Unsubscribed from "all" topic');
      // Ana bildirimler kapatıldığında günlük bildirimleri de iptal et
      DailyNotificationService()
          .setDailyNotificationsEnabled(false)
          .catchError((e) => debugPrint('DailyNotif cancel error: $e'));
    }
  }

  void _handleMessage(RemoteMessage message) {
    final screen = message.data['screen'];
    if (screen != null) {
      if (navigateTo != null) {
        navigateTo!(screen);
      } else {
        _pendingRoute = screen;
      }
    }
  }

  Future<void> _saveTokenToFirestore(String token, {required bool isEnabled}) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final prefs = await SharedPreferences.getInstance();
      
      // Check if we have a different old token stored locally
      const String oldTokenKey = 'last_registered_fcm_token';
      final String? oldToken = prefs.getString(oldTokenKey);
      
      if (oldToken != null && oldToken != token) {
        // App probably reinstalled or token changed, delete the old document
        try {
          await FirebaseFirestore.instance.collection('user_tokens').doc(oldToken).delete();
          debugPrint('Stale FCM token deleted: $oldToken');
        } catch (e) {
          debugPrint('Error deleting stale token: $e');
        }
      }

      final docRef = FirebaseFirestore.instance.collection('user_tokens').doc(token);
      
      await docRef.set({
        'token': token,
        'userId': user?.uid,
        'platform': Platform.isAndroid ? 'android' : 'ios',
        'lastUpdated': FieldValue.serverTimestamp(),
        'isEnabled': isEnabled,
        'lastSeen': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      // Update local storage with the current latest token
      await prefs.setString(oldTokenKey, token);
      
      // Topic subscription is handled by the caller
    } catch (e) {
      debugPrint('Token registration error: $e');
    }
  }

  Future<void> showTestNotification({String? title, String? body, String? payload}) async {
    // Generate a strictly positive, unique small integer ID
    final id = (DateTime.now().millisecondsSinceEpoch % 100000) + (title?.length ?? 0);
    
    const androidDetails = AndroidNotificationDetails(
      channelId,
      'Seydi Rehber Bildirimleri',
      channelDescription: 'Şehir duyuruları ve önemli bildirimler için kullanılır.',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      icon: 'ic_stat_s',
    );
    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _localNotificationsPlugin.show(
      id: id,
      title: title ?? 'Test Bildirimi 🔔',
      body: body ?? 'Bildirim sistemi başarıyla çalışıyor!',
      notificationDetails: notificationDetails,
      payload: payload,
    );
  }

  /// Explicitly request permissions for iOS and Android 13+
  /// This should be called from UI (Onboarding, Settings, etc.)
  Future<bool> requestPermission() async {
    bool granted = false;

    if (Platform.isIOS) {
      // 1. Request FCM Permission (iOS native prompt)
      // On iOS, this handles the single system permission prompt for both FCM and Local Notifications
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      
      granted = settings.authorizationStatus == AuthorizationStatus.authorized || 
                settings.authorizationStatus == AuthorizationStatus.provisional;

      // 2. Ensure APNs token is fetched after permission is granted
      if (granted) {
        debugPrint('Notification permission granted on iOS. Fetching APNs token...');
        final apnsToken = await _firebaseMessaging.getAPNSToken();
        if (apnsToken != null) {
          debugPrint('APNs Token acquired after permission: $apnsToken');
        }
      }
    } else if (Platform.isAndroid) {
      // Android 13+ notification permission
      final status = await Permission.notification.request();
      granted = status.isGranted;
    }

    // If granted, ensure token is recorded/subscriptions are handled
    if (granted) {
      final token = await _firebaseMessaging.getToken();
      if (token != null) {
        final isEnabled = await isNotificationsEnabled();
        await _saveTokenToFirestore(token, isEnabled: isEnabled);
        if (isEnabled) {
          await _firebaseMessaging.subscribeToTopic('all');
        }
      }
    }

    return granted;
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Silence is golden
}
