import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/cached_image_widget.dart';
import '../../../core/widgets/error_view.dart';
import '../providers/news_provider.dart';
import '../models/news_model.dart';
import '../../../core/widgets/shimmer_widget.dart';

class NewsScreen extends ConsumerWidget {
  const NewsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final newsAsync = ref.watch(newsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Haberler', style: AppTextStyles.appBarTitle),
        backgroundColor: AppColors.white,
        elevation: 0,
      ),
      body: newsAsync.when(
        data: (newsList) {
          if (newsList.isEmpty) {
            return const Center(child: Text('Şu an haber bulunamadı.'));
          }
          return RefreshIndicator(
            onRefresh: () => ref.refresh(newsProvider.future),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: newsList.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final news = newsList[index];
                return _NewsCard(news: news);
              },
            ),
          );
        },
        loading: () => ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: 3,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (_, __) => NewsCardShimmer(),
        ),
        error: (e, stack) => ErrorView(
          message: 'Haberleri güncellemek için lütfen internet bağlantınızı kontrol edin ve tekrar deneyin.',
          onRetry: () => ref.refresh(newsProvider),
        ),
      ),
    );
  }
}

class _NewsCard extends StatelessWidget {
  final NewsModel news;

  const _NewsCard({required this.news});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: InkWell(
        onTap: () async {
          if (news.link.isEmpty) return;
          final url = Uri.parse(news.link);
          try {
            await launchUrl(url, mode: LaunchMode.platformDefault);
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Haber bağlantısı açılamadı.')),
              );
            }
          }
        },
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with Placeholder
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: news.imageUrl.isNotEmpty
                      ? CachedImageWidget(
                          imageUrl: news.imageUrl,
                          height: 200,
                          width: double.infinity,
                        )
                      : Container(
                          height: 200,
                          width: double.infinity,
                          color: AppColors.primarySurface,
                          child: const Icon(Icons.newspaper_rounded,
                              size: 50, color: AppColors.primary),
                        ),
                ),
                // "Haber" Label
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Haberler',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    news.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    news.description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textLight,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.access_time_rounded,
                              size: 14, color: AppColors.textLight),
                          const SizedBox(width: 4),
                          Text(
                            news.pubDate.split('+').first.trim(),
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.textLight),
                          ),
                        ],
                      ),
                      const Text(
                        'Haberin Devamı →',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

