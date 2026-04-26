import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/cached_image_widget.dart';
import '../../../core/widgets/interactive_map_widget.dart';
import '../../../core/widgets/favorite_button.dart';
import '../../../core/utils/map_helper.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/widgets/review_section.dart';
import '../../../core/services/haptic_service.dart';
import '../../../core/widgets/shimmer_widget.dart';

class PlaceDetailScreen extends ConsumerWidget {
  final String placeId;

  const PlaceDetailScreen({super.key, required this.placeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('gezilecek_yerler')
            .doc(placeId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const DetailShimmer();
          }

          if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Bir hata oluştu veya veri bulunamadı.'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final name = data['ad']?.toString() ?? data['name']?.toString() ?? '';
          final imageUrl = data['image_url']?.toString() ?? data['gorsel']?.toString() ?? '';
          
          // Robust field extraction with prioritized fallbacks
          String getField(List<String> keys) {
            for (var key in keys) {
              final val = data[key]?.toString().trim();
              if (val != null && val.isNotEmpty) return val;
            }
            return '';
          }

          final hakkinda = getField(['hakkinda', 'aciklama', 'description', 'info']);
          final tarihce = getField(['tarihce', 'history']);
          final konum = getField(['konum', 'location', 'address']);

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                expandedHeight: 350,
                pinned: true,
                backgroundColor: AppColors.primary,
                leading: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () {
                      HapticService.selection();
                      Navigator.pop(context);
                    },
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Hero(
                        tag: 'place-$placeId',
                        child: CachedImageWidget(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.4),
                              Colors.transparent,
                              Colors.black.withOpacity(0.4),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.share_outlined, color: Colors.white, size: 20),
                      onPressed: () {
                        HapticService.selection();
                        Share.share('$name yerini Seydi Rehber\'de keşfet!');
                      },
                    ),
                  ),
                  FavoriteButton(id: placeId, type: 'place'),
                ],
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(20),
                  child: Container(
                    height: 20,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(38)),
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1E293B),
                          letterSpacing: -0.5,
                        ),
                      ),
                      if (hakkinda.isNotEmpty) ...[
                        Text(
                          'Hakkında',
                          style: AppTextStyles.heading3,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          hakkinda,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: Colors.grey[800],
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                      if (tarihce.isNotEmpty) ...[
                        Text(
                          'Tarihçe',
                          style: AppTextStyles.heading3,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          tarihce,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: Colors.grey[800],
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                      
                      const Text(
                        'Konum',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (konum.isNotEmpty) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Container(
                            height: 200,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              border: Border.all(color: Colors.grey[200]!),
                            ),
                            child: FutureBuilder<LatLng?>(
                              future: MapHelper.getCoordinates(konum),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return const Center(child: CircularProgressIndicator());
                                }
                                
                                final coords = snapshot.data;
                                if (coords != null) {
                                  return InteractiveMapWidget(
                                    position: coords,
                                    title: name,
                                  );
                                }
                                
                                return Center(
                                  child: Text(
                                    'Harita görüntülenemiyor',
                                    style: TextStyle(color: Colors.grey[500]),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              HapticService.selection();
                              _launchURL(konum, context);
                            },
                            icon: const Icon(Icons.directions_rounded),
                            label: const Text('Yol Tarifi Al'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ],
                      
                      const SizedBox(height: 40),
                      ReviewSection(targetId: placeId, targetType: 'place'),
                      const SizedBox(height: 100),
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

  Future<void> _launchURL(String url, BuildContext context) async {
    await MapHelper.openMapWithAddress(url);
  }
}
