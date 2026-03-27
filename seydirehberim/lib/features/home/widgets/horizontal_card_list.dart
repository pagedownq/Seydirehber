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

        // Horizontal for companies, Vertical for events/places
        final double listHeight = type == CardType.company ? 220 : 310;

        return SizedBox(
          height: listHeight,
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
    if (type == CardType.company) {
      return _buildCompanyCard(data, id);
    }

    final name = data['ad'] as String? ?? data['name'] as String? ?? '';
    final imageUrl =
        data['image_url'] as String? ?? data['gorsel'] as String? ?? '';

    // Dimensions for Vertical (Event/Place)
    const double cardWidth = 180;
    const double imageHeight = 230;

    return RepaintBoundary(
      child: GestureDetector(
        onTap: () => onTap(id),
        child: Container(
          width: cardWidth,
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
                SizedBox(
                  width: cardWidth,
                  height: imageHeight,
                  child: Stack(
                    children: [
                      // Blurred background
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(16)),
                          child: CachedImageWidget(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            memCacheWidth: 100,
                            memCacheHeight: 100,
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: Container(
                            color: Colors.black.withValues(alpha: 0.1)),
                      ),
                      // Actual image
                      Center(
                        child: CachedImageWidget(
                          imageUrl: imageUrl,
                          fit: BoxFit.contain,
                          borderRadius: 16,
                          memCacheWidth: (cardWidth * 2).toInt(),
                          memCacheHeight: (imageHeight * 2).toInt(),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  width: cardWidth,
                  height: imageHeight,
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: const Icon(Icons.image,
                      color: AppColors.textLight, size: 40),
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
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompanyCard(Map<String, dynamic> data, String id) {
    final name = data['ad'] as String? ?? data['name'] as String? ?? '';
    final imageUrl =
        data['image_url'] as String? ?? data['gorsel'] as String? ?? '';
    final viewCount = data['goruntulenme'] as int? ?? 0;
    final category = data['kategori'] as String? ?? 'Firma';
    final address = (data['konum'] ?? data['adres'] ?? '').toString();
    final createdAt = data['created_at'] as Timestamp?;
    final isNew = createdAt != null &&
        DateTime.now().difference(createdAt.toDate()).inDays < 30;

    return RepaintBoundary(
      child: GestureDetector(
        onTap: () => onTap(id),
        child: Container(
          width: 250,
          margin: const EdgeInsets.only(bottom: 2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Stack(
              children: [
                // Background Image
                Positioned.fill(
                  child: CachedImageWidget(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    memCacheWidth: 500,
                  ),
                ),
                // Dark overlay for overall contrast
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.2),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.8),
                        ],
                        stops: const [0, 0.4, 0.9],
                      ),
                    ),
                  ),
                ),
                // Blue overlay at the bottom like in the screenshot
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 70,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0xFF0056B3).withValues(alpha: 0.0),
                          const Color(0xFF0056B3).withValues(alpha: 0.8),
                        ],
                      ),
                    ),
                  ),
                ),
                // Category Tag
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0056B3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      category,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                // "YENİ" Badge (Top Right)
                if (isNew)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: const Text(
                        'YENİ',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                // Information at the bottom
                Positioned(
                  bottom: 12,
                  left: 12,
                  right: 12,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                const Icon(Icons.location_on,
                                    color: Colors.white, size: 14),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    address,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Row(
                            children: [
                              const Icon(Icons.visibility,
                                  color: Colors.white, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                '$viewCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
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
