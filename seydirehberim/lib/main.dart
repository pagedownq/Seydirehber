import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'core/services/local_cache_service.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/services/notification_service.dart';
import 'core/services/daily_notification_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';

void main() {
  // 1. Flutter'ı anında başlat
  WidgetsFlutterBinding.ensureInitialized();
  
  // 2. Uygulamayı saniyesinde ayağa kaldır (Beyaz ekran böylece anında kaybolur)
  runApp(const ProviderScope(child: StartupWrapper()));
}

class StartupWrapper extends StatefulWidget {
  const StartupWrapper({super.key});

  @override
  State<StartupWrapper> createState() => _StartupWrapperState();
}

class _StartupWrapperState extends State<StartupWrapper> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    try {
      await dotenv.load(fileName: ".env");
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
      
      await Future.wait([
        Supabase.initialize(
          url: 'https://ycqrgraqmafdtvaxwuml.supabase.co',
          anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InljcXJncmFxbWFmZHR2YXh3dW1sIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzM5MTI2MTgsImV4cCI6MjA4OTQ4ODYxOH0.riAGavZ3RZgUHwlxiQDp8PFmVju9qIUamOJBWS8kVWc',
        ),
        LocalCacheService.init(),
      ]);

      // Hazır olduğunda bildirimi arkadan başlat
      NotificationService().initialize().catchError((e) => debugPrint(e.toString()));

      // Günlük etkileşim bildirimlerini planla
      DailyNotificationService().initialize().catchError((e) => debugPrint('DailyNotif init error: $e'));

      if (mounted) {
        setState(() => _initialized = true);
      }
    } catch (e) {
      debugPrint("Kritik Hata: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // Servisler yüklenene kadar sistemin açılış rengi (beyaz) ile devam et
    // Böylece kullanıcı takılma veya logo atlaması görmez, "tek seferde" açılıyor gibi hisseder.
    if (!_initialized) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Colors.white,
          body: SizedBox.expand(),
        ),
      );
    }
    return const SeydiRehberApp();
  }
}

class SeydiRehberApp extends ConsumerWidget {
  const SeydiRehberApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Seydi Rehber',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('tr', 'TR'),
      ],
      locale: const Locale('tr', 'TR'),
    );
  }
}
