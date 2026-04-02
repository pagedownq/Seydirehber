import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/cached_image_widget.dart';
import '../providers/favorites_provider.dart';
import '../../../core/widgets/favorite_button.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Favorilerim', style: AppTextStyles.appBarTitle),
        backgroundColor: AppColors.white,
      ),
      body: favorites.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.favorite_border,
                      size: 64, color: AppColors.textLight),
                  const SizedBox(height: 16),
                  Text('Henüz favori eklemediniz',
                      style: AppTextStyles.bodyMedium),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: favorites.length,
              itemBuilder: (context, index) {
                final item = favorites[index];
                return _FavoriteItemCard(item: item);
              },
            ),
    );
  }
}

class _FavoriteItemCard extends StatelessWidget {
  final FavoriteItem item;

  const _FavoriteItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final collection =
        item.type == 'company' ? 'firmalar' : 'gezilecek_yerler';
    final routePrefix = item.type == 'company' ? 'companies' : 'places';

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection(collection)
          .doc(item.id)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const SizedBox.shrink();
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final id = snapshot.data!.id;
        final name = data['ad'] as String? ?? data['name'] as String? ?? '';
        final imageUrl =
            data['image_url'] as String? ?? data['gorsel'] as String? ?? '';
        final viewCount = data['goruntulenme'] as int? ?? 0;
        final category = data['kategori'] as String? ?? '';
                final rawAddress = (data['konum'] ?? data['adres'] ?? '').toString();
        final address = rawAddress.startsWith('http') ? '' : rawAddress;

        return GestureDetector(
          onTap: () => context.push('/$routePrefix/$id'),
          child: Container(
            height: 220,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CachedImageWidget(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      isCompany: item.type == 'company',
                    ),
                  ),
                  // Category Tag
                  if (category.isNotEmpty)
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          category,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  // Favorite Icon (always on here)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: FavoriteButton(
                        id: item.id,
                        type: item.type,
                        size: 20,
                        showBackground: true,
                      ),
                    ),
                  // Bottom Content
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.0),
                            Colors.black.withOpacity(0.8),
                          ],
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Expanded(
                                child: address.isNotEmpty ? Row(
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
                                ) : const SizedBox.shrink(),
                              ),
                              if (item.type == 'company') ...[
                                const SizedBox(width: 8),
                                const Icon(Icons.remove_red_eye_outlined,
                                    size: 14, color: Colors.white70),
                                const SizedBox(width: 4),
                                Text(
                                  '$viewCount',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
