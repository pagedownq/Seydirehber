import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../home/screens/home_screen.dart';
import '../../news/screens/news_screen.dart';
import '../../settings/screens/settings_screen.dart';
import '../../../core/services/update_service.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    NewsScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Uygulama açılışında güncelleme kontrolü
    WidgetsBinding.instance.addPostFrameCallback((_) {
      UpdateService.checkForUpdate();
    });
  }

  @override
  Widget build(BuildContext context) {
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
          onDestinationSelected: (i) => setState(() => _currentIndex = i),
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
