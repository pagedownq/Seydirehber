import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/cached_image_widget.dart';
import '../../../core/widgets/shimmer_widget.dart';
import '../providers/home_providers.dart';

class BannerSlider extends ConsumerStatefulWidget {
  const BannerSlider({super.key});

  @override
  ConsumerState<BannerSlider> createState() => _BannerSliderState();
}

class _BannerSliderState extends ConsumerState<BannerSlider> {
  final PageController _controller = PageController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bannersAsync = ref.watch(bannersProvider);

    return bannersAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: ShimmerWidget.rectangular(height: 160),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (snapshot) {
        final banners = snapshot.docs;
        if (banners.isEmpty) return const SizedBox.shrink();

        return Column(
          children: [
            SizedBox(
              height: 160,
              child: PageView.builder(
                controller: _controller,
                itemCount: banners.length,
                itemBuilder: (context, index) {
                  final data = banners[index].data();
                  final imageUrl = data['image_url'] as String? ?? '';

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: CachedImageWidget(
                        imageUrl: imageUrl,
                        borderRadius: 16,
                        width: double.infinity,
                        height: 160,
                      ),
                    ),
                  );
                },
              ),
            ),
            if (banners.length > 1) ...[
              const SizedBox(height: 10),
              SmoothPageIndicator(
                controller: _controller,
                count: banners.length,
                effect: WormEffect(
                  dotHeight: 8,
                  dotWidth: 8,
                  activeDotColor: AppColors.primary,
                  dotColor: AppColors.border,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
