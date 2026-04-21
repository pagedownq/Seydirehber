import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:go_router/go_router.dart';
import '../../../core/services/haptic_service.dart';
import '../../../core/constants/app_colors.dart';
import '../../home/screens/home_screen.dart';
import '../../news/screens/news_screen.dart';
import '../../settings/screens/settings_screen.dart';
import '../../../core/services/update_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/daily_notification_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/widgets/name_request_dialog.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> with WidgetsBindingObserver {
  int _currentIndex = 0;
  bool _isNameDialogShowing = false;

  final List<Widget> _screens = const [
    HomeScreen(),
    NewsScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Bind notification navigation
    NotificationService().navigateTo = (route) {
      if (!mounted) return;
      
      // Handle tab switches
      if (route == '/') {
        setState(() => _currentIndex = 0);
      } else if (route == '/news') {
        setState(() => _currentIndex = 1);
      } else if (route == '/settings') {
        setState(() => _currentIndex = 2);
      } else {
        // Handle deep links to other screens
        context.push(route);
      }
    };

    // Check for updates
    WidgetsBinding.instance.addPostFrameCallback((_) {
      UpdateService.checkForUpdate();
      _checkMissingName();
    });
  }

  void _checkMissingName() {
    final user = ref.read(authStateProvider).value;
    final isGuest = ref.read(isGuestProvider);

    if (user != null && !isGuest && !_isNameDialogShowing) {
      if (user.displayName == null || user.displayName!.isEmpty) {
        _isNameDialogShowing = true;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => NameRequestDialog(
            onSave: (fullName) async {
              await ref.read(authNotifierProvider.notifier).updateDisplayName(fullName);
              _isNameDialogShowing = false;
              if (mounted) Navigator.pop(context);
            },
          ),
        ).then((_) => _isNameDialogShowing = false);
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Uygulama ön plana geldiğinde bildirim planını güncelle (yeni gün için)
      DailyNotificationService()
          .scheduleDailyNotifications()
          .catchError((e) => debugPrint('DailyNotif reschedule error: $e'));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen for name changes (especially for Apple Sign In)
    ref.listen(authStateProvider, (previous, next) {
      if (next.value != null && (next.value?.displayName == null || next.value!.displayName!.isEmpty)) {
        // Debounce or check if already showing
        _checkMissingName();
      }
    });

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (i) {
            HapticService.selection();
            setState(() => _currentIndex = i);
          },
          backgroundColor: AppColors.white,
          indicatorColor: AppColors.primarySurface,
          surfaceTintColor: Colors.transparent,
          height: 65,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home, color: AppColors.primary),
              label: 'Ana Sayfa',
            ),
            NavigationDestination(
              icon: Icon(Icons.newspaper_outlined),
              selectedIcon: Icon(Icons.newspaper, color: AppColors.primary),
              label: 'Haberler',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings, color: AppColors.primary),
              label: 'Ayarlar',
            ),
          ],
        ),
      ),
    );
  }
}
