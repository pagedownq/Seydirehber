import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../providers/auth_provider.dart';

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
      title: 'Seydişehir Rehberin',
      description:
          'Şehrindeki etkinlikler, firmalar, gezilecek yerler ve daha fazlasını tek bir uygulamada keşfet!',
      color: AppColors.primary,
    ),
    _OnboardingPageData(
      icon: Icons.security_rounded,
      title: 'Gizliliğin Bizim İçin Önemli',
      description:
          'Verileriniz güvende. Devam etmek için gizlilik politikamızı onaylamanız gerekmektedir.',
      color: AppColors.primaryDark,
      hasPrivacyCheckbox: true,
    ),
    _OnboardingPageData(
      icon: Icons.rocket_launch_rounded,
      title: 'Hazırsın!',
      description:
          'Google hesabınla giriş yap veya misafir olarak devam et.',
      color: AppColors.accent,
      hasAuthButtons: true,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage == 1 && !_privacyAccepted) {
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
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                physics: _currentPage == 1 && !_privacyAccepted
                    ? const NeverScrollableScrollPhysics()
                    : null,
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return _buildPage(page);
                },
              ),
            ),

            // Indicator
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: SmoothPageIndicator(
                controller: _pageController,
                count: _pages.length,
                effect: WormEffect(
                  dotHeight: 10,
                  dotWidth: 10,
                  activeDotColor: AppColors.primary,
                  dotColor: AppColors.border,
                ),
              ),
            ),

            // Navigation button (hide on last page)
            if (_currentPage < _pages.length - 1)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _nextPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text('Devam', style: AppTextStyles.button),
                  ),
                ),
              ),

            const SizedBox(height: 16),
          ],
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
          // Icon container with gradient
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  page.color.withValues(alpha: 0.15),
                  page.color.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(32),
            ),
            child: Icon(page.icon, size: 60, color: page.color),
          ),
          const SizedBox(height: 40),
          Text(
            page.title,
            style: AppTextStyles.heading1.copyWith(fontSize: 26),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            page.description,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Privacy checkbox on page 2
          if (page.hasPrivacyCheckbox) ...[
            CheckboxListTile(
              value: _privacyAccepted,
              onChanged: (v) => setState(() => _privacyAccepted = v ?? false),
              title: Text(
                'Gizlilik Politikasını okudum ve kabul ediyorum',
                style: AppTextStyles.bodySmall,
              ),
              activeColor: AppColors.primary,
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ],

          // Auth buttons on page 3
          if (page.hasAuthButtons) ...[
            _buildAuthButtons(),
          ],
        ],
      ),
    );
  }

  Widget _buildAuthButtons() {
    final authNotifier = ref.read(authNotifierProvider.notifier);
    final authState = ref.watch(authNotifierProvider);

    return Column(
      children: [
        // Google Sign In
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: authState.isLoading
                ? null
                : () async {
                    await authNotifier.signInWithGoogle();
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('onboarding_completed', true);
                    if (mounted) context.go('/');
                  },
            icon: Image.network(
              'https://www.google.com/favicon.ico',
              width: 24,
              height: 24,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.login, color: Colors.white),
            ),
            label: Text(
              authState.isLoading ? 'Giriş yapılıyor...' : 'Google ile Giriş Yap',
              style: AppTextStyles.button,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Guest button
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton(
            onPressed: authState.isLoading
                ? null
                : () async {
                    await authNotifier.continueAsGuest();
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('onboarding_completed', true);
                    if (mounted) context.go('/');
                  },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              'Misafir Olarak Devam Et',
              style: AppTextStyles.button.copyWith(color: AppColors.primary),
            ),
          ),
        ),
      ],
    );
  }
}

class _OnboardingPageData {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final bool hasPrivacyCheckbox;
  final bool hasAuthButtons;

  _OnboardingPageData({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    this.hasPrivacyCheckbox = false,
    this.hasAuthButtons = false,
  });
}
