import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/cached_image_widget.dart';
import '../../../core/widgets/map_button.dart';
import '../../home/providers/home_providers.dart';

class EventDetailScreen extends ConsumerWidget {
  final String eventId;

  const EventDetailScreen({super.key, required this.eventId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('etkinlikler')
            .doc(eventId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Etkinlik bulunamadı'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final name = data['ad'] as String? ?? '';
          final imageUrl = data['image_url'] as String? ?? data['gorsel'] as String? ?? '';
          final hakkinda = data['hakkinda'] as String? ?? '';
          final konum = data['konum'] as String?;
          final startDate = data['baslangic_tarihi'] ?? data['baslangic_tarihi_str'];
          final endDate = data['bitis_tarihi'] ?? data['bitis_tarihi_str'];
          final saat = data['saat'] as String?;

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 250,
                pinned: true,
                backgroundColor: AppColors.white,
                flexibleSpace: FlexibleSpaceBar(
                  background: imageUrl.isNotEmpty
                      ? CachedImageWidget(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                        )
                      : Container(color: AppColors.primarySurface),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.share, color: Colors.white),
                    onPressed: () {
                      Share.share(
                        '$name etkinliğini Seydi Rehber\'de keşfet!',
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
                      const SizedBox(height: 12),

                      // Dates
                      _buildInfoRow(
                        Icons.calendar_today,
                        'Başlangıç',
                        _formatDate(startDate),
                      ),
                      if (endDate != null) ...[
                        const SizedBox(height: 8),
                        _buildInfoRow(
                          Icons.event,
                          'Bitiş',
                          _formatDate(endDate),
                        ),
                      ],
                      if (saat != null) ...[
                        const SizedBox(height: 8),
                        _buildInfoRow(Icons.access_time, 'Saat', saat),
                      ],

                      if (hakkinda.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        Text('Hakkında', style: AppTextStyles.heading3),
                        const SizedBox(height: 8),
                        Text(hakkinda, style: AppTextStyles.bodyMedium),
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

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Text('$label: ', style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600)),
        Expanded(child: Text(value, style: AppTextStyles.bodySmall)),
      ],
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
}
