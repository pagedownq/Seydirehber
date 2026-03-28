import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/cached_image_widget.dart';
import '../../favorites/providers/favorites_provider.dart';

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
          final category = data['kategori'] as String? ?? '';

          return Stack(
            children: [
              CustomScrollView(
                slivers: [
                  // App Bar with Image
                  SliverAppBar(
                    expandedHeight: 280,
                    pinned: true,
                    elevation: 0,
                    backgroundColor: AppColors.primaryDark,
                    foregroundColor: Colors.white,
                    leading: Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    flexibleSpace: FlexibleSpaceBar(
                      background: Stack(
                        fit: StackFit.expand,
                        children: [
                          CachedImageWidget(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                          ),
                          // Dark overlay for readability
                          DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withOpacity(0.4),
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.2),
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
                          icon: const Icon(Icons.share_outlined, size: 20),
                          onPressed: () {
                            Share.share('$name yerini Seydi Rehber\'de keşfet!');
                          },
                        ),
                      ),
                      Consumer(
                        builder: (context, ref, child) {
                          final favorites = ref.watch(favoritesProvider);
                          final isFav = favorites.any((e) => e.id == placeId && e.type == 'place');
                          return Container(
                            margin: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.3),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: Icon(
                                isFav ? Icons.favorite : Icons.favorite_border,
                                color: isFav ? Colors.red : Colors.white,
                                size: 20,
                              ),
                              onPressed: () {
                                ref.read(favoritesProvider.notifier)
                                    .toggleFavorite(placeId, 'place');
                              },
                            ),
                          );
                        },
                      ),
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

                  // Content Card
                  SliverToBoxAdapter(
                    child: Container(
                      color: Colors.white,
                      padding: const EdgeInsets.fromLTRB(25, 0, 25, 120),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header Row: Title + Category
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (category.isNotEmpty) ...[
                                  Text(
                                    category.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.primaryDark,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                ],
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.black,
                                    height: 1.1,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // Description
                            if (hakkinda.isNotEmpty) ...[
                              const SectionTitle(title: 'Hakkında'),
                              const SizedBox(height: 12),
                              Text(
                                hakkinda,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[800],
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 32),
                            ],

                            // History Section
                            if (tarihce != null && tarihce.isNotEmpty) ...[
                              const SectionTitle(title: 'Tarihçe'),
                              const SizedBox(height: 12),
                              Text(
                                tarihce,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[800],
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 32),
                            ],

                            const SectionTitle(title: 'Harita'),
                            const SizedBox(height: 16),
                            if (konum != null && konum.isNotEmpty)
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () => _launchMap(konum!),
                                  icon: const Icon(Icons.near_me_rounded),
                                  label: const Text('HARİTA ÜZERİNDEN BAK', 
                                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primarySurface,
                                    foregroundColor: AppColors.primaryDark,
                                    padding: const EdgeInsets.symmetric(vertical: 18),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    elevation: 0,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 40),
                          ],
                        ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    String link = url;
    if (!link.startsWith('http')) link = 'https://$link';
    final uri = Uri.parse(link);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _launchMap(String query) async {
    String mapUrl = '';
    if (query.startsWith('http')) {
      mapUrl = query;
    } else {
      mapUrl = 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}';
    }
    final uri = Uri.parse(mapUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Widget _buildModernInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: AppColors.primaryDark),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String title;
  const SectionTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }
}
