import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/cached_image_widget.dart';
import '../../../core/widgets/map_button.dart';
import '../../favorites/providers/favorites_provider.dart';

class PlaceDetailScreen extends ConsumerWidget {
  final String placeId;

  const PlaceDetailScreen({super.key, required this.placeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesProvider);
    final isFav = favorites.any((e) => e.id == placeId && e.type == 'place');
    return Scaffold(
      backgroundColor: AppColors.background,
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('gezilecek_yerler')
            .doc(placeId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Yer bulunamadı'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final name = data['ad'] as String? ?? '';
          final imageUrl = data['image_url'] as String? ?? data['gorsel'] as String? ?? '';
          final hakkinda = data['hakkinda'] as String? ?? '';
          final tarihce = data['tarihce'] as String?;
          final konum = data['konum'] as String?;

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 250,
                pinned: true,
                backgroundColor: AppColors.white,
                flexibleSpace: FlexibleSpaceBar(
                  background: imageUrl.isNotEmpty
                      ? CachedImageWidget(imageUrl: imageUrl, fit: BoxFit.cover)
                      : Container(color: AppColors.primarySurface),
                ),
                actions: [
                  IconButton(
                    icon: Icon(
                      isFav ? Icons.favorite : Icons.favorite_border,
                      color: isFav ? Colors.red : Colors.white,
                    ),
                    onPressed: () {
                      ref.read(favoritesProvider.notifier)
                          .toggleFavorite(placeId, 'place');
                    },
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: AppTextStyles.heading2),

                      if (hakkinda.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text('Hakkında', style: AppTextStyles.heading3),
                        const SizedBox(height: 8),
                        Text(hakkinda, style: AppTextStyles.bodyMedium),
                      ],

                      if (tarihce != null && tarihce.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text('Tarihçe', style: AppTextStyles.heading3),
                        const SizedBox(height: 8),
                        Text(tarihce, style: AppTextStyles.bodyMedium),
                      ],

                      if (konum != null && konum.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        MapButton(locationUrl: konum),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
