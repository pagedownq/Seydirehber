import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/cached_image_widget.dart';
import '../../../core/widgets/map_button.dart';
import '../../../core/widgets/interactive_map_widget.dart';
import '../../../core/utils/map_helper.dart';
import '../../home/providers/home_providers.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/widgets/shimmer_widget.dart';

class EventDetailScreen extends ConsumerWidget {
  final String eventId;

  const EventDetailScreen({super.key, required this.eventId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('etkinlikler')
            .doc(eventId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const DetailShimmer();
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Etkinlik bulunamadı'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final name = data['ad'] as String? ?? '';
          final imageUrl = data['image_url'] as String? ?? data['gorsel'] as String? ?? '';
          final hakkinda = data['hakkinda'] as String? ?? '';
          final konum = data['konum'] as String?;
          final adres = data['adres'] as String? ?? data['konum'] as String? ?? '';
          final startDate = data['baslangic_tarihi'] ?? data['baslangic_tarihi_str'];
          final endDate = data['bitis_tarihi'] ?? data['bitis_tarihi_str'];
          final saat = data['saat'] as String?;

          return Stack(
            children: [
              CustomScrollView(
                physics: const ClampingScrollPhysics(),
                slivers: [
                  SliverAppBar(
                    expandedHeight: 450,
                    pinned: true,
                    elevation: 0,
                    backgroundColor: Colors.white,
                    scrolledUnderElevation: 0,
                    shadowColor: Colors.transparent,
                    surfaceTintColor: Colors.transparent,
                    foregroundColor: AppColors.primaryDark,
                    leading: Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, size: 20, color: Colors.white),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                    ),
                    flexibleSpace: FlexibleSpaceBar(
                      background: Stack(
                        fit: StackFit.expand,
                        children: [
                          Hero(
                            tag: 'event-$eventId',
                            child: CachedImageWidget(
                              imageUrl: imageUrl,
                              fit: BoxFit.cover,
                            ),
                          ),
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
                            Share.share('$name etkinliğini Seydi Rehber\'de keşfet!');
                          },
                        ),
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

                  SliverToBoxAdapter(
                    child: Container(
                      color: Colors.white,
                      padding: const EdgeInsets.fromLTRB(25, 0, 25, 120),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: Colors.black,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 10),
                            
                            const SizedBox(height: 32),

                            // Zaman Bilgisi Section
                            const Text(
                              'Zaman Bilgisi',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 20),
                            
                            _buildModernInfoRow(Icons.calendar_month, 'BAŞLANGIÇ', _formatDate(startDate)),
                            if (endDate != null)
                              _buildModernInfoRow(Icons.event_note, 'BİTİŞ TARİHİ', _formatDate(endDate)),
                            if (saat != null)
                              _buildModernInfoRow(Icons.access_time_filled, 'ETKİNLİK SAATİ', saat),

                            const SizedBox(height: 40),

                            if (hakkinda.isNotEmpty) ...[
                              const Text(
                                'Açıklama',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                hakkinda,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[800],
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 40),
                            ],

                            if (konum != null && konum.isNotEmpty) ...[
                              const SectionTitle(title: 'Konum'),
                              const SizedBox(height: 16),
                              if (adres.isNotEmpty) ...[
                                _buildModernInfoRow(Icons.location_on_outlined, 'ADRES', adres),
                              ],
                              FutureBuilder<LatLng?>(
                                future: MapHelper.getCoordinates(konum),
                                builder: (context, snapshot) {
                                  if (snapshot.hasData && snapshot.data != null) {
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 20),
                                      child: InteractiveMapWidget(
                                        position: snapshot.data!,
                                        title: name,
                                      ),
                                    );
                                  }
                                  return const SizedBox.shrink();
                                },
                              ),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    _launchMap(konum!);
                                  },
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
                            ],
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

  Widget _buildModernInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, size: 24, color: AppColors.primaryDark),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
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

  String _formatDate(dynamic date) {
    if (date == null) return '';
    if (date is Timestamp) {
      final dt = date.toDate();
      return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
    }
    return date.toString();
  }

  Future<void> _launchMap(String query) async {
    await MapHelper.openMapWithAddress(query);
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
