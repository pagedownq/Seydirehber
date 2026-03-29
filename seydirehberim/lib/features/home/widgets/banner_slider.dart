import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
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

  Future<void> _launchURL(String url) async {
    String finalUrl = url;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      finalUrl = 'https://$url';
    }

    final uri = Uri.parse(finalUrl);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bannersAsync = ref.watch(bannersProvider);

    return bannersAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: AspectRatio(
          aspectRatio: 1200 / 300,
          child: ShimmerWidget.rectangular(),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (banners) {
        if (banners.isEmpty) return const SizedBox.shrink();

        return Column(
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                // Calculate height to maintain EXACTly 4:1 ratio for the image area
                // Width is screen width minus the double padding (16+16=32)
                final imageWidth = constraints.maxWidth - 32;
                final imageHeight = imageWidth / 4;

                return SizedBox(
                  height: imageHeight,
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: banners.length,
                    itemBuilder: (context, index) {
                      final data = banners[index].data() as Map<String, dynamic>;
                      final imageUrl = data['image_url'] as String? ?? '';
                      final companyId = data['company_id'] as String? ?? '';
                      final targetUrl = data['url'] as String? ?? '';

                      return GestureDetector(
                        onTap: () {
                          if (companyId.isNotEmpty) {
                            context.push('/companies/$companyId');
                          } else if (targetUrl.isNotEmpty) {
                            _launchURL(targetUrl);
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: CachedImageWidget(
                                imageUrl: imageUrl,
                                width: imageWidth,
                                height: imageHeight,
                                fit: BoxFit.cover, // Better than fill to avoid stretching
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
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
