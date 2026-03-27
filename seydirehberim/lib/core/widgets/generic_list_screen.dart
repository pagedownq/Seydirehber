import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/cached_image_widget.dart';
import '../../core/widgets/shimmer_widget.dart';

class GenericListScreen extends ConsumerWidget {
  final String title;
  final StreamProvider<QuerySnapshot<Map<String, dynamic>>> provider;
  final String routePrefix;
  final bool showViewCount;

  const GenericListScreen({
    super.key,
    required this.title,
    required this.provider,
    required this.routePrefix,
    this.showViewCount = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(provider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(title, style: AppTextStyles.appBarTitle.copyWith(color: AppColors.white)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: AppColors.white),
      ),
      body: dataAsync.when(
        loading: () => ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: 5,
          itemBuilder: (_, __) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ShimmerWidget.rectangular(height: 90),
          ),
        ),
        error: (_, __) => const Center(child: Text('Veriler yüklenemedi')),
        data: (snapshot) {
          final docs = snapshot.docs;
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.inbox_outlined, size: 48, color: AppColors.textLight),
                  const SizedBox(height: 12),
                  Text('Henüz veri bulunmuyor', style: AppTextStyles.bodyMedium),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data();
              final id = docs[index].id;
              final name = data['ad'] as String? ?? data['name'] as String? ?? '';
              final imageUrl =
                  data['image_url'] as String? ?? data['gorsel'] as String? ?? '';
              final viewCount = data['goruntulenme'] as int? ?? 0;
              final category = data['kategori'] as String? ?? '';
              final rawAddress = (data['konum'] ?? data['adres'] ?? '').toString();
              // If it's a map link, don't show it as a text address in the card
              final address = rawAddress.startsWith('http') ? '' : rawAddress;

              return GestureDetector(
                onTap: () => context.push('/$routePrefix/$id'),
                child: Container(
                  height: 240,
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
                        // Background Image
                        Positioned.fill(
                          child: CachedImageWidget(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                          ),
                        ),
                        // Top-Left Category Tag
                        if (category.isNotEmpty)
                          Positioned(
                            top: 12,
                            left: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E88E5).withOpacity(0.9),
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
                        // Bottom Gradient Overlay
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
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
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
                                    if (showViewCount) ...[
                                      const SizedBox(width: 8),
                                      const Icon(Icons.remove_red_eye_outlined,
                                          size: 14, color: Colors.white),
                                      const SizedBox(width: 4),
                                      Text(
                                        '$viewCount görüntüleme',
                                        style: const TextStyle(
                                          color: Colors.white,
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
        },
      ),
    );
  }
}
