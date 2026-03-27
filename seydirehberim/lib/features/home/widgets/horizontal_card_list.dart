import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/cached_image_widget.dart';
import '../../../core/widgets/shimmer_widget.dart';

enum CardType { event, place, company }

class HorizontalCardList extends ConsumerWidget {
  final StreamProvider<QuerySnapshot<Map<String, dynamic>>> provider;
  final CardType type;
  final Function(String id) onTap;

  const HorizontalCardList({
    super.key,
    required this.provider,
    required this.type,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(provider);

    return dataAsync.when(
      loading: () => const ShimmerListWidget(),
      error: (_, __) => const SizedBox(
        height: 100,
        child: Center(child: Text('Veriler yüklenemedi')),
      ),
      data: (snapshot) {
        final docs = snapshot.docs;
        if (docs.isEmpty) {
          return SizedBox(
            height: 100,
            child: Center(
              child: Text(
                'Henüz veri bulunmuyor',
                style: AppTextStyles.bodySmall,
              ),
            ),
          );
        }

        return SizedBox(
          height: type == CardType.company ? 200 : 180,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final data = docs[index].data();
              final id = docs[index].id;
              return _buildCard(data, id);
            },
          ),
        );
      },
    );
  }

  Widget _buildCard(Map<String, dynamic> data, String id) {
    final name = data['ad'] as String? ?? data['name'] as String? ?? '';
    final imageUrl = data['image_url'] as String? ?? data['gorsel'] as String? ?? '';
    final viewCount = data['goruntulenme'] as int? ?? 0;

    return GestureDetector(
      onTap: () => onTap(id),
      child: Container(
        width: 200,
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            if (imageUrl.isNotEmpty)
              CachedImageWidget(
                imageUrl: imageUrl,
                width: 200,
                height: 110,
                borderRadius: 16,
              )
            else
              Container(
                width: 200,
                height: 110,
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: const Icon(Icons.image, color: AppColors.textLight, size: 40),
              ),

            // Content
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (type == CardType.event) ...[
                    const SizedBox(height: 2),
                    _buildEventDate(data),
                  ],
                  if (type == CardType.company) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.visibility_outlined,
                            size: 14, color: AppColors.textLight),
                        const SizedBox(width: 4),
                        Text(
                          '$viewCount görüntülenme',
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventDate(Map<String, dynamic> data) {
    final startDate = data['baslangic_tarihi'] ?? data['baslangic_tarihi_str'];
    if (startDate == null) return const SizedBox.shrink();

    String dateStr = '';
    if (startDate is Timestamp) {
      final dt = startDate.toDate();
      dateStr =
          '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
    } else {
      dateStr = startDate.toString();
    }

    return Row(
      children: [
        const Icon(Icons.calendar_today, size: 12, color: AppColors.primary),
        const SizedBox(width: 4),
        Text(
          dateStr,
          style: AppTextStyles.caption.copyWith(color: AppColors.primary),
        ),
      ],
    );
  }
}
