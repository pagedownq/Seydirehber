import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/cached_image_widget.dart';
import '../../../core/widgets/map_button.dart';

class PlaceDetailScreen extends StatelessWidget {
  final String placeId;

  const PlaceDetailScreen({super.key, required this.placeId});

  @override
  Widget build(BuildContext context) {
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
                    icon: const Icon(Icons.share, color: Colors.white),
                    onPressed: () {
                      Share.share(
                        '$name - Seydi Rehber ile keşfet!',
                      );
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
