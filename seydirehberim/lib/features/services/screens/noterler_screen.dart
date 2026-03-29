import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/cached_image_widget.dart';
import '../../../core/widgets/map_button.dart';
import '../../../core/widgets/shimmer_widget.dart';
import '../../home/providers/home_providers.dart';

class NoterlerScreen extends ConsumerWidget {
  const NoterlerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(noterlerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Noterler', style: AppTextStyles.appBarTitle),
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
        error: (err, stack) => const Center(child: Text('Veriler yüklenemedi.')),
        data: (docs) {
          if (docs.isEmpty) return const Center(child: Text('Henüz noter eklenmemiş'));
          final items = docs.map((d) => d.data()).toList();
          return _buildNoterList(items);
        },
      ),
    );
  }

  Widget _buildNoterList(List<Map<String, dynamic>> items) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _NoterCard(data: items[index]),
    );
  }
}

class _NoterCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _NoterCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final name = data['ad'] as String? ?? '';
    final imageUrl = data['image_url'] as String? ?? data['gorsel'] as String? ?? '';
    final gunler = data['gunler'] as String? ?? '';
    final telefon = data['telefon'] as String? ?? '';
    final rawAdres = data['adres'] as String? ?? '';
    final rawKonum = data['konum'] as String? ?? '';
    final adres = rawAdres.isNotEmpty ? rawAdres : (rawKonum.startsWith('http') ? '' : rawKonum);
    final konum = rawKonum;

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
                Text(name, style: AppTextStyles.heading3),
                if (gunler.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.schedule, size: 16, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(child: Text(gunler, style: AppTextStyles.bodySmall)),
                    ],
                  ),
                ],
                if (telefon.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.phone, size: 16, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(telefon, style: AppTextStyles.bodySmall),
                    ],
                  ),
                ],
                if (adres.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 16, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          adres,
                          style: AppTextStyles.bodySmall,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                if (konum.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  MapButton(locationUrl: konum),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
