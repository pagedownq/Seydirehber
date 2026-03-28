import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/cached_image_widget.dart';
import '../../core/widgets/shimmer_widget.dart';
import '../services/local_cache_service.dart';
import 'error_view.dart';

class GenericListScreen extends ConsumerWidget {
  final String title;
  final StreamProvider<QuerySnapshot<Map<String, dynamic>>> provider;
  final String routePrefix;
  final bool showViewCount;
  final String? cacheKey;
  final bool useGrid;

  const GenericListScreen({
    super.key,
    required this.title,
    required this.provider,
    required this.routePrefix,
    this.showViewCount = false,
    this.cacheKey,
    this.useGrid = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(provider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded,
              color: Colors.white, size: 22),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded, color: Colors.white, size: 22),
            onPressed: () => Share.share(
                'Seydi Rehber - $title listesine göz at! https://seydirehber.com'),
          ),
        ],
      ),
      body: dataAsync.when(
        loading: () => useGrid
            ? GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.65,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: 6,
                itemBuilder: (_, __) => const ListCardShimmer(isGrid: true),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: 5,
                itemBuilder: (_, __) => const Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: ListCardShimmer(),
                ),
              ),
        error: (err, __) {
          if (cacheKey != null) {
            final cachedData = LocalCacheService.getList(cacheKey!);
            if (cachedData != null && cachedData.isNotEmpty) {
              return _buildList(context, cachedData, true);
            }
          }
          return ErrorView(
            message: 'Bilgileri güncellemek için lütfen internet bağlantınızı kontrol edin.',
            onRetry: () => ref.refresh(provider),
          );
        },
        data: (snapshot) {
          final docs = snapshot.docs;

          // Save to manual local cache for extra redundancy
          if (cacheKey != null && docs.isNotEmpty && !snapshot.metadata.isFromCache) {
            final dataList = docs.map((d) {
              final map = d.data();
              map['id'] = d.id; // Store ID as well for navigation
              return map;
            }).toList();
            LocalCacheService.saveList(cacheKey!, dataList);
          }

          if (docs.isEmpty) {
            if (cacheKey != null && snapshot.metadata.isFromCache) {
              final manualCache = LocalCacheService.getList(cacheKey!);
              if (manualCache != null && manualCache.isNotEmpty) {
                return _buildList(context, manualCache, true);
              }
            }
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_rounded, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text('Henüz $title eklenmedi', 
                    style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold)),
                ],
              ),
            );
          }

          final now = DateTime.now();
          final items = docs.where((d) {
            final data = d.data();
            if (data.containsKey('expiry_date') && data['expiry_date'] != null) {
              try {
                final expiry = (data['expiry_date'] as Timestamp).toDate();
                return expiry.isAfter(now);
              } catch (e) {
                return true;
              }
            }
            return true;
          }).map((d) {
            final map = d.data();
            map['id'] = d.id;
            return map;
          }).toList();

          return _buildList(context, items, false);
        },
      ),
    );
  }

  Widget _buildList(BuildContext context, List<Map<String, dynamic>> items,
      bool isFromManualCache) {
    if (useGrid) {
      return GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.65,
          crossAxisSpacing: 16,
          mainAxisSpacing: 24,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final data = items[index];
          final id = data['id']?.toString() ?? '';
          final name = data['ad'] as String? ?? data['name'] as String? ?? '';
          final imageUrl =
              data['image_url'] as String? ?? data['gorsel'] as String? ?? '';
          final category = data['kategori'] as String? ?? '';

          return _buildVerticalCard(context, id, name, imageUrl, category, isFromManualCache);
        },
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final data = items[index];
        final id = data['id']?.toString() ?? '';
        final name = data['ad'] as String? ?? data['name'] as String? ?? '';
        final imageUrl = data['image_url'] as String? ?? data['gorsel'] as String? ?? '';
        final viewCount = data['goruntulenme'] as int? ?? 0;
        final category = data['kategori'] as String? ?? '';
        final rawLocation = (data['konum'] ?? data['adres'] ?? '').toString();
        final locationText = rawLocation.startsWith('http') ? 'Seydişehir, Konya' : rawLocation;

        return Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: GestureDetector(
            onTap: () => context.push('/$routePrefix/$id'),
            child: Container(
              height: 220,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
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
                        isCompany: routePrefix == 'companies',
                      ),
                    ),
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.1),
                              Colors.transparent,
                              Colors.black.withOpacity(0.6),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (category.isNotEmpty)
                      Positioned(
                        top: 15,
                        left: 15,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.95),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            category,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    if (isFromManualCache)
                      Positioned(
                        top: 15,
                        right: 15,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.storage_rounded, size: 12, color: Colors.white),
                              SizedBox(width: 4),
                              Text(
                                'ÖNBELLEK',
                                style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.85),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 17,
                                      fontWeight: FontWeight.w900,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on_rounded, size: 14, color: Colors.white),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          locationText,
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(0.9),
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            if (showViewCount)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.remove_red_eye_rounded, size: 20, color: Colors.white),
                                  Text(
                                    '$viewCount',
                                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
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
          ),
        );
      },
    );
  }

  Widget _buildVerticalCard(
    BuildContext context,
    String id,
    String name,
    String imageUrl,
    String category,
    bool isFromManualCache,
  ) {
    return GestureDetector(
      onTap: () => context.push('/$routePrefix/$id'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 0.82, // Fixed portrait ratio for all cards
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: CachedImageWidget(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              name,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.black,
                letterSpacing: -0.3,
                height: 1.1,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
