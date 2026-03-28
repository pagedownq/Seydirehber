import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/cached_image_widget.dart';
import '../../../core/widgets/map_button.dart';
import '../../../core/widgets/shimmer_widget.dart';
import '../../../core/services/local_cache_service.dart';
import '../../../core/widgets/shimmer_widget.dart';
import '../../home/providers/home_providers.dart';

class PazarlarScreen extends ConsumerWidget {
  const PazarlarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(pazarlarProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Halk Pazarları', style: AppTextStyles.appBarTitle),
        backgroundColor: AppColors.white,
      ),
      body: dataAsync.when(
        loading: () => ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: 3,
          itemBuilder: (_, __) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ShimmerWidget.rectangular(height: 120),
          ),
        ),
        error: (err, stack) {
          final cachedData = LocalCacheService.getList('pazarlar');
          if (cachedData != null && cachedData.isNotEmpty) {
            return _buildPazarList(cachedData, isFromManualCache: true);
          }
          return const Center(child: Text('Veriler yüklenemedi'));
        },
        data: (snapshot) {
          final docs = snapshot.docs;

          if (docs.isNotEmpty && !snapshot.metadata.isFromCache) {
            final dataList = docs.map((d) => d.data()).toList();
            LocalCacheService.saveList('pazarlar', dataList);
          }

          if (docs.isEmpty) {
             if (snapshot.metadata.isFromCache) {
                final manualCache = LocalCacheService.getList('pazarlar');
                if (manualCache != null && manualCache.isNotEmpty) {
                  return _buildPazarList(manualCache, isFromManualCache: true);
                }
             }
             return const Center(child: Text('Henüz pazar eklenmemiş'));
          }

          final items = docs.map((d) => d.data()).toList();
          return Column(
            children: [
              if (snapshot.metadata.isFromCache)
                _buildOfflineBanner(),
              Expanded(child: _buildPazarList(items)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOfflineBanner() {
    return Container(
      width: double.infinity,
      color: Colors.orange.shade50,
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_off, size: 14, color: Colors.orange),
          const SizedBox(width: 8),
          Text(
            'Çevrimdışı mod: Kayıtlı veriler gösteriliyor',
            style: AppTextStyles.bodySmall.copyWith(color: Colors.orange.shade900),
          ),
        ],
      ),
    );
  }

  Widget _buildPazarList(List<Map<String, dynamic>> items, {bool isFromManualCache = false}) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final data = items[index];
        final name = data['ad'] as String? ?? '';
        final imageUrl = data['image_url'] as String? ?? data['gorsel'] as String? ?? '';
        final gunler = data['gunler'] as String? ?? '';
        final konum = data['konum'] as String?;

        return Container(
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (imageUrl.isNotEmpty)
                CachedImageWidget(
                  imageUrl: imageUrl,
                  width: double.infinity,
                  height: 150,
                  borderRadius: 16,
                ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(name, style: AppTextStyles.heading3)),
                        if (isFromManualCache)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'KAYITLI',
                              style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary, fontSize: 8),
                            ),
                          ),
                      ],
                    ),
                    if (gunler.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.schedule, size: 16, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Text(gunler, style: AppTextStyles.bodySmall),
                        ],
                      ),
                    ],
                    if (konum != null && konum.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      MapButton(locationUrl: konum),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
