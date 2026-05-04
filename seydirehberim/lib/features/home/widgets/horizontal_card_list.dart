import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/services/haptic_service.dart';
import '../../../core/widgets/cached_image_widget.dart';
import '../../../core/widgets/shimmer_widget.dart';

enum CardType { event, place, company }

class HorizontalCardList extends ConsumerWidget {
  final StreamProvider<List<QueryDocumentSnapshot<Map<String, dynamic>>>> provider;
  final CardType type;
  final Function(String id) onTap;

  const HorizontalCardList({
    super.key,
    required this.provider,
    required this.type,
    required this.onTap,
    this.heroTagPrefix,
  });

  final String? heroTagPrefix;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(provider);

    return dataAsync.when(
      loading: () => SizedBox(
        height: type == CardType.company ? 220 : 340,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: 3,
          itemBuilder: (_, __) => const HorizontalCardShimmer(),
        ),
      ),
      error: (_, __) => const SizedBox(
        height: 100,
        child: Center(child: Text('Veriler yüklenemedi')),
      ),
      data: (docs) {
        final now = DateTime.now();
        final filteredDocs = docs.where((d) {
          final data = d.data();
          if (data.containsKey('expiry_date') && data['expiry_date'] != null) {
            try {
              final expiry = (data['expiry_date'] as Timestamp).toDate();
              return expiry.isAfter(now);
            } catch (e) {
              return true; // If format is weird, show it
            }
          }
          return true; // No expiry means forever
        }).toList();

        if (filteredDocs.isEmpty) {
          final String emptyTitle = type == CardType.event
              ? 'Etkinlik'
              : (type == CardType.place ? 'Yer' : 'Firma');

          return Container(
            height: 100,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Center(
              child: Text(
                'Henüz $emptyTitle eklenmedi',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textLight),
              ),
            ),
          );
        }

        // Horizontal for companies, Vertical for events/places
        final double listHeight = type == CardType.company ? 220 : 340;

        return SizedBox(
          height: listHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: filteredDocs.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final data = filteredDocs[index].data();
              final id = filteredDocs[index].id;
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
    final rawAdres = data['adres'] as String? ?? '';
    final rawKonum = data['konum'] as String? ?? '';
    final address = rawAdres.isNotEmpty ? rawAdres : (rawKonum.startsWith('http') ? '' : rawKonum);

    // Dimensions for Vertical (Event/Place)
    const double cardWidth = 220;
    const double imageHeight = 240;

    return RepaintBoundary(
      child: GestureDetector(
        onTap: () {
          HapticService.selection();
          onTap(id);
        },
        child: SizedBox(
          width: cardWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Hero(
                tag: '${heroTagPrefix ?? type.name}-$id',
                child: CachedImageWidget(
                  imageUrl: imageUrl,
                  height: imageHeight,
                  width: cardWidth,
                  fit: BoxFit.cover,
                  borderRadius: 16,
                  isEvent: type == CardType.event,
                ),
              ),

              const SizedBox(height: 8),

              // Title below image
              Text(
                name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  letterSpacing: -0.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              if (type == CardType.event) ...[
                const SizedBox(height: 4),
                _buildEventDate(data),
              ],
              if (address.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 12, color: AppColors.textLight),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        address,
                        style: AppTextStyles.caption.copyWith(color: AppColors.textLight),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
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
    final category = data['kategori'] as String? ?? '';
    final rawAdres = data['adres'] as String? ?? '';
    final rawKonum = data['konum'] as String? ?? '';
    final address = rawAdres.isNotEmpty ? rawAdres : (rawKonum.startsWith('http') ? '' : rawKonum);
    final createdAt = data['created_at'] as Timestamp?;
    final isNew = createdAt != null &&
        DateTime.now().difference(createdAt.toDate()).inDays < 30;

    return RepaintBoundary(
      child: GestureDetector(
        onTap: () {
          HapticService.selection();
          onTap(id);
        },
        child: Container(
          width: 250,
          margin: const EdgeInsets.only(bottom: 2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
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
                  child: Hero(
                    tag: '${heroTagPrefix ?? 'company'}-$id',
                    child: CachedImageWidget(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      memCacheWidth: 500,
                      isCompany: true,
                    ),
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
                          Colors.black.withOpacity(0.2),
                          Colors.transparent,
                          Colors.black.withOpacity(0.8),
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
                          AppColors.primaryDark.withOpacity(0.0),
                          AppColors.primaryDark.withOpacity(0.8),
                        ],
                      ),
                    ),
                  ),
                ),
                if (category.isNotEmpty)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 0.5,
                        ),
                      ),
                      child: Text(
                        category.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                          shadows: [
                            Shadow(
                              color: Colors.black26,
                              offset: Offset(0, 1),
                              blurRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                if (isNew)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFFF5252),
                            Color(0xFFFF1744),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Text(
                        'YENİ',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
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
                            child: address.isNotEmpty
                                ? Row(
                                    children: [
                                      const Icon(Icons.location_on_outlined,
                                          size: 14, color: Colors.white70),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          address,
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 12,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  )
                                : const SizedBox.shrink(),
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
        Expanded(
          child: Text(
            dateStr,
            style: AppTextStyles.caption.copyWith(color: AppColors.primary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
