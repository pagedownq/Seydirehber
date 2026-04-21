import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lottie/lottie.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/services/haptic_service.dart';
import '../providers/auth_provider.dart';
import '../../../core/services/notification_service.dart';
import '../../settings/screens/policies_screen.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _privacyAccepted = false;

  final List<_OnboardingPageData> _pages = [
    _OnboardingPageData(
      icon: Icons.location_city_rounded,
      lottiePath: 'assets/animations/merhaba.json',
      title: 'Seydi Rehber\'e Hoş Geldin',
      description:
          'Şehrindeki her şeyi keşfetmek için en doğru yerdesin. Modern ve hızlı rehberinle tanış!',
      color: AppColors.primary,
    ),
    _OnboardingPageData(
      icon: Icons.map_rounded,
      lottiePath: 'assets/animations/location.json',
      title: 'Seydi Harita',
      description:
          'Tamamen yenilenen haritamızla şehri keşfet. Önemli konumlar ve ulaşım her an parmaklarının ucunda!',
      color: AppColors.primary,
    ),
    _OnboardingPageData(
      icon: Icons.grid_view_rounded,
      title: 'Hızlı Hizmetler',
      description:
          'Nöbetçi eczaneler, otobüs saatleri ve pazar yerleri gibi ihtiyacın olan her şey elinin altında.',
      color: AppColors.primary,
      mockupType: _MockupType.services,
    ),
    _OnboardingPageData(
      icon: Icons.explore_rounded,
      title: 'Şehri Keşfet',
      description:
          'Hava durumunu takip et, en güncel haberleri oku ve sana özel fırsat kuponlarını kaçırma!',
      color: AppColors.primary,
      mockupType: _MockupType.daily,
    ),
    _OnboardingPageData(
      icon: Icons.security_rounded,
      title: 'Gizlilik ve Güvenlik',
      description:
          'Verileriniz bizimle güvende. Devam etmeden önce lütfen kullanım koşullarımızı onaylayın.',
      color: AppColors.primary,
      hasPrivacyCheckbox: true,
    ),
    _OnboardingPageData(
      icon: Icons.notifications_active_rounded,
      title: 'Bildirimleri Aç',
      description:
          'En güncel duyurular, etkinlikler ve hizmetlerden anında haberdar olmak için bildirimleri aktif edin.',
      color: AppColors.primary,
      hasNotificationButton: true,
    ),
    _OnboardingPageData(
      icon: Icons.rocket_launch_rounded,
      title: 'Keşfetmeye Hazırsın!',
      description:
          'Google hesabınla giriş yaparak profilini oluşturabilir veya misafir olarak devam edebilirsin.',
      color: AppColors.primary,
      hasAuthButtons: true,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    HapticService.vibrate(); // Daha güçlü ve standart titreşim
    if (_currentPage == 4 && !_privacyAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Devam etmek için gizlilik politikasını onaylayın'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 600),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.white,
              AppColors.primary.withOpacity(0.01),
              AppColors.primary.withOpacity(0.05),
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: _pages.length,
                      onPageChanged: (index) {
                        setState(() => _currentPage = index);
                      },
                      physics: _currentPage == 4 && !_privacyAccepted
                          ? const NeverScrollableScrollPhysics()
                          : null,
                      itemBuilder: (context, index) {
                        final page = _pages[index];
                        return _buildPage(page);
                      },
                    ),
                  ),

                  // Indicator and Button
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SmoothPageIndicator(
                          controller: _pageController,
                          count: _pages.length,
                          effect: ExpandingDotsEffect(
                            dotHeight: 8,
                            dotWidth: 8,
                            expansionFactor: 4,
                            spacing: 8,
                            activeDotColor: AppColors.primary,
                            dotColor: AppColors.primary.withOpacity(0.2),
                          ),
                        ),
                        const SizedBox(height: 24),
                        if (_currentPage < _pages.length - 1)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Container(
                                width: double.infinity,
                                height: 56,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  color: AppColors.primary.withOpacity(0.2),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.2),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withOpacity(0.1),
                                      blurRadius: 15,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: () async {
                                    HapticService.vibrate();
                                    _nextPage();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    foregroundColor: AppColors.primary,
                                    elevation: 0,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                  child: Text(
                                    'Devam Et',
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          )
                        else
                          const SizedBox(height: 8), // Minimal spacing instead of 56px placeholder
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPage(_OnboardingPageData page) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 2),
          // Icon container or Mockup with premium styling
          if (page.mockupType != null)
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 800),
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, 10 * (1 - value)),
                  child: Opacity(
                    opacity: value,
                    child: child,
                  ),
                );
              },
              child: _buildMockup(page.mockupType!),
            )
          else if (page.lottiePath != null)
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 1000),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Opacity(
                    opacity: value,
                    child: child,
                  ),
                );
              },
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (page.imagePath != null)
                    Transform.rotate(
                      angle: -0.05,
                      child: Container(
                        width: 240,
                        height: 240,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(32),
                          child: Image.asset(
                            page.imagePath!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              color: AppColors.primary.withOpacity(0.1),
                              child: const Icon(Icons.image, color: Colors.grey),
                            ),
                          ),
                        ),
                      ),
                    ),
                  Container(
                    width: page.imagePath != null ? 180 : 260,
                    height: page.imagePath != null ? 180 : 260,
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(page.imagePath != null ? 32 : 48),
                      boxShadow: [
                        BoxShadow(
                          color: page.color.withOpacity(0.12),
                          blurRadius: 40,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    padding: EdgeInsets.all(page.imagePath != null ? 16 : 24),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(page.imagePath != null ? 24 : 32),
                      child: Lottie.asset(
                        page.lottiePath!,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(40),
                boxShadow: [
                  BoxShadow(
                    color: page.color.withOpacity(0.15),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          page.color.withOpacity(0.2),
                          page.color.withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(32),
                    ),
                  ),
                  Icon(page.icon, size: 70, color: page.color),
                ],
              ),
            ),
          const SizedBox(height: 48),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 600),
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: Opacity(opacity: value, child: child),
              );
            },
            child: Text(
              page.title,
              style: AppTextStyles.heading1.copyWith(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 800),
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: Opacity(opacity: value, child: child),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                page.description,
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const Spacer(flex: 3),
          
          // Additional components (Privacy / Auth / Notifications)
          if (page.hasPrivacyCheckbox || page.hasAuthButtons || page.hasNotificationButton)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (page.hasNotificationButton) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        width: double.infinity,
                        height: 52,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: page.color.withOpacity(0.2),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                            width: 1.5,
                          ),
                        ),
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            HapticFeedback.vibrate(); 
                            final granted = await NotificationService().requestPermission();
                            if (granted) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Bildirimler başarıyla açıldı!'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                                _nextPage();
                              }
                            } else {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Bildirim izni verilmedi.'),
                                    backgroundColor: AppColors.error,
                                  ),
                                );
                              }
                            }
                          },
                          icon: Icon(Icons.notifications_active_outlined, color: page.color),
                          label: Text('Bildirimleri Etkinleştir', style: AppTextStyles.button.copyWith(color: page.color)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            elevation: 0,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _nextPage,
                    child: Text(
                      'Daha Sonra',
                      style: TextStyle(color: page.color.withOpacity(0.7)),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                if (page.hasPrivacyCheckbox) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.2),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: CheckboxListTile(
                          value: _privacyAccepted,
                          onChanged: (v) => setState(() => _privacyAccepted = v ?? false),
                          title: Text.rich(
                            TextSpan(
                              children: [
                                WidgetSpan(
                                  alignment: PlaceholderAlignment.middle,
                                  child: GestureDetector(
                                    onTap: () => _showPolicyDetail(
                                      context,
                                      'Gizlilik Politikası',
                                      PoliciesScreen.privacyPolicyContent,
                                    ),
                                    child: Text(
                                      'Gizlilik Politikası',
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                        decoration: TextDecoration.underline,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ),
                                const TextSpan(text: ', '),
                                WidgetSpan(
                                  alignment: PlaceholderAlignment.middle,
                                  child: GestureDetector(
                                    onTap: () => _showPolicyDetail(
                                      context,
                                      'Kullanım Koşulları',
                                      PoliciesScreen.termsOfServiceContent,
                                    ),
                                    child: Text(
                                      'Kullanım Koşulları',
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                        decoration: TextDecoration.underline,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ),
                                const TextSpan(text: ' ve '),
                                WidgetSpan(
                                  alignment: PlaceholderAlignment.middle,
                                  child: GestureDetector(
                                    onTap: () => _showPolicyDetail(
                                      context,
                                      'KVKK Aydınlatma Metni',
                                      PoliciesScreen.kvkkContent,
                                    ),
                                    child: Text(
                                      'KVKK Metni',
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                        decoration: TextDecoration.underline,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ),
                                TextSpan(
                                  text: '\'ni okudum ve kabul ediyorum',
                                  style: AppTextStyles.bodySmall.copyWith(fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          activeColor: AppColors.primary,
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                if (page.hasAuthButtons) ...[
                  _buildAuthButtons(),
                  const SizedBox(height: 24),
                ],
              ],
            )
          else
            const SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget _buildAuthButtons() {
    final authNotifier = ref.read(authNotifierProvider.notifier);
    final authState = ref.watch(authNotifierProvider);

    return Column(
      children: [
        // Apple Sign In
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              width: double.infinity,
              height: 54,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: AppColors.white.withOpacity(0.9),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.15),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: authState.isLoading
                    ? null
                    : () async {
                        HapticService.vibrate(); 
                        await authNotifier.signInWithApple();
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setBool('onboarding_completed', true);
                        if (mounted) context.go('/');
                      },
                icon: const Icon(
                  Icons.apple,
                  size: 26,
                  color: Colors.black,
                ),
                label: Text(
                  authState.isLoading ? 'Giriş yapılıyor...' : 'Apple ile Giriş Yap',
                  style: AppTextStyles.button.copyWith(
                    color: Colors.black.withOpacity(0.85),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Google Sign In
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              width: double.infinity,
              height: 54,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: AppColors.primary.withOpacity(0.1),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.2),
                  width: 1.5,
                ),
              ),
              child: ElevatedButton.icon(
                onPressed: authState.isLoading
                    ? null
                    : () async {
                        HapticService.vibrate(); 
                        await authNotifier.signInWithGoogle();
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setBool('onboarding_completed', true);
                        if (mounted) context.go('/');
                      },
                icon: Image.network(
                  'https://www.google.com/favicon.ico',
                  width: 22,
                  height: 22,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.login, color: AppColors.primary),
                ),
                label: Text(
                  authState.isLoading ? 'Giriş yapılıyor...' : 'Google ile Giriş Yap',
                  style: AppTextStyles.button.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Guest button
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(
              width: double.infinity,
              height: 54,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: AppColors.primary.withOpacity(0.05),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.1),
                  width: 1.5,
                ),
              ),
              child: OutlinedButton(
                onPressed: authState.isLoading
                    ? null
                    : () async {
                        HapticService.selection();
                        await authNotifier.continueAsGuest();
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setBool('onboarding_completed', true);
                        if (mounted) context.go('/');
                      },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(
                  'Misafir Olarak Devam Et',
                  style: AppTextStyles.button.copyWith(
                    color: AppColors.primary.withOpacity(0.8),
                    fontWeight: FontWeight.bold
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMockup(_MockupType type) {
    if (type == _MockupType.services) {
      return Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _MockupServiceCard(
                title: 'Nöbetçi Eczane',
                icon: Icons.local_pharmacy_rounded,
                color: const Color(0xFFEF5350),
              ),
              const SizedBox(width: 12),
              _MockupServiceCard(
                title: 'Otobüs Saatleri',
                icon: Icons.directions_bus_rounded,
                color: const Color(0xFF26A69A),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _MockupServiceCard(
                title: 'Noterler',
                icon: Icons.gavel_rounded,
                color: const Color(0xFF455A64),
              ),
              const SizedBox(width: 12),
              _MockupServiceCard(
                title: 'Halk Pazarları',
                icon: Icons.storefront_rounded,
                color: const Color(0xFFFFB300),
              ),
            ],
          ),
        ],
      );
    } else {
      return Column(
        children: [
          // Weather Mockup
          Container(
            width: 200,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: AppColors.weatherGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.cloud_outlined, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Hava Durumu', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    Text('Seydişehir 18°C', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // News/Coupon combo
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                ),
                child: const Row(
                  children: [
                    Icon(Icons.newspaper_rounded, color: Color(0xFF2E7D32), size: 18),
                    SizedBox(width: 8),
                    Text('Güncel Haberler', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                ),
                child: const Row(
                  children: [
                    Icon(Icons.local_offer_rounded, color: Color(0xFFE53935), size: 18),
                    SizedBox(width: 8),
                    Text('Kuponlar', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
        ],
      );
    }
  }

  void _showPolicyDetail(BuildContext context, String title, String content) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(title, style: AppTextStyles.heading2)),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const Divider(height: 32),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  content,
                  style: AppTextStyles.bodyMedium.copyWith(height: 1.6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MockupServiceCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;

  const _MockupServiceCard({
    required this.title,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 70,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: Colors.white, size: 20),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

enum _MockupType { services, daily, map }

class _OnboardingPageData {
  final IconData icon;
  final String? lottiePath;
  final String? imagePath;
  final String title;
  final String description;
  final Color color;
  final bool hasPrivacyCheckbox;
  final bool hasAuthButtons;
  final bool hasNotificationButton;
  final _MockupType? mockupType;

  _OnboardingPageData({
    required this.icon,
    this.lottiePath,
    this.imagePath,
    required this.title,
    required this.description,
    required this.color,
    this.hasPrivacyCheckbox = false,
    this.hasAuthButtons = false,
    this.hasNotificationButton = false,
    this.mockupType,
  });
}
