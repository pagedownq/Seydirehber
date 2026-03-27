import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../providers/home_providers.dart';
import '../widgets/banner_slider.dart';
import '../widgets/horizontal_card_list.dart';
import '../widgets/service_grid.dart';
import '../../../core/widgets/see_all_button.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Basic AppBar
          SliverAppBar(
            backgroundColor: AppColors.white,
            surfaceTintColor: Colors.transparent,
            pinned: true,
            title: Row(
              children: [
                Icon(Icons.location_on, color: AppColors.primary, size: 22),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Seydi Rehber',
                    style: AppTextStyles.appBarTitle,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // Action Buttons
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: _buildTopActionButton(
                      title: 'Hava Durumu',
                      icon: Icons.cloud_outlined,
                      gradient: AppColors.weatherGradient,
                      onTap: () => context.push('/weather'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTopActionButton(
                      title: 'Arkadaşlarınla Paylaş',
                      icon: Icons.share_outlined,
                      isBlack: true,
                      onTap: () {
                        Share.share(
                          'Seydi Rehber uygulamasını indir ve Seydişehir hakkında her şeyi öğren! 📱 https://seydirehber.com',
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Search Bar (Isolated)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: _HomeSearchField(),
            ),
          ),

          // Banner Slider
          const SliverToBoxAdapter(
            child: BannerSlider(),
          ),

          // Etkinlikler Section
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SeeAllButton(
                    title: 'Etkinlikler',
                    onTap: () => context.push('/events'),
                  ),
                ),
                const SizedBox(height: 8),
                HorizontalCardList(
                  provider: latestEventsProvider,
                  type: CardType.event,
                  onTap: (id) => context.push('/events/$id'),
                ),
              ],
            ),
          ),

          // Hizmetler Section
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text('Hizmetler', style: AppTextStyles.heading3),
                ),
                const SizedBox(height: 12),
                const RepaintBoundary(child: ServiceGrid()),
              ],
            ),
          ),

          // Gezilecek Yerler Section
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SeeAllButton(
                    title: 'Gezilecek Yerler',
                    onTap: () => context.push('/places'),
                  ),
                ),
                const SizedBox(height: 8),
                HorizontalCardList(
                  provider: latestPlacesProvider,
                  type: CardType.place,
                  onTap: (id) => context.push('/places/$id'),
                ),
              ],
            ),
          ),

          // Tüm Firmalar Section
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SeeAllButton(
                    title: 'Tüm Firmalar',
                    onTap: () => context.push('/companies'),
                  ),
                ),
                const SizedBox(height: 8),
                HorizontalCardList(
                  provider: alphabeticalCompaniesProvider,
                  type: CardType.company,
                  onTap: (id) => context.push('/companies/$id'),
                ),
              ],
            ),
          ),

          // Yeni Eklenen Firmalar Section
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SeeAllButton(
                    title: 'Yeni Eklenen Firmalar',
                    onTap: () => context.push('/companies'),
                  ),
                ),
                const SizedBox(height: 8),
                HorizontalCardList(
                  provider: latestCompaniesProvider,
                  type: CardType.company,
                  onTap: (id) => context.push('/companies/$id'),
                ),
              ],
            ),
          ),

          // En Çok Ziyaret Edilen Firmalar Section
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text('En Çok Ziyaret Edilen Firmalar',
                      style: AppTextStyles.heading3),
                ),
                const SizedBox(height: 8),
                HorizontalCardList(
                  provider: popularCompaniesProvider,
                  type: CardType.company,
                  onTap: (id) => context.push('/companies/$id'),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopActionButton({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    Gradient? gradient,
    bool isBlack = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 100,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isBlack ? Colors.black : (gradient == null ? Colors.white : null),
          gradient: isBlack ? null : gradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: (isBlack ? Colors.black : (gradient?.colors.first ?? AppColors.primary))
                  .withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            Expanded(
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeSearchField extends StatefulWidget {
  const _HomeSearchField();

  @override
  State<_HomeSearchField> createState() => _HomeSearchFieldState();
}

class _HomeSearchFieldState extends State<_HomeSearchField> {
  final TextEditingController _controller = TextEditingController();
  bool _showClear = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      if (_controller.text.isNotEmpty != _showClear) {
        setState(() => _showClear = _controller.text.isNotEmpty);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      textInputAction: TextInputAction.search,
      onSubmitted: (value) {
        if (value.trim().isNotEmpty) {
          context.push('/search?q=${Uri.encodeComponent(value.trim())}');
        }
      },
      decoration: InputDecoration(
        hintText: 'Etkinlik, firma veya yer ara...',
        hintStyle: AppTextStyles.bodySmall,
        prefixIcon: const Icon(Icons.search, color: AppColors.textLight),
        suffixIcon: _showClear
            ? IconButton(
                icon: const Icon(Icons.clear, size: 18),
                onPressed: () {
                  _controller.clear();
                },
              )
            : null,
        filled: true,
        fillColor: AppColors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.border),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }
}
