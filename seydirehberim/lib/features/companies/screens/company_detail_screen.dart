import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/cached_image_widget.dart';
import '../../../core/widgets/map_button.dart';
import '../../favorites/providers/favorites_provider.dart';

class CompanyDetailScreen extends ConsumerStatefulWidget {
  final String companyId;

  const CompanyDetailScreen({super.key, required this.companyId});

  @override
  ConsumerState<CompanyDetailScreen> createState() => _CompanyDetailScreenState();
}

class _CompanyDetailScreenState extends ConsumerState<CompanyDetailScreen> {
  @override
  void initState() {
    super.initState();
    _incrementViewCount();
  }

  // Daily single increment view counter using shared_preferences
  Future<void> _incrementViewCount() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final key = 'view_${widget.companyId}_$today';

    if (prefs.getBool(key) != true) {
      await prefs.setBool(key, true);
      await FirebaseFirestore.instance
          .collection('firmalar')
          .doc(widget.companyId)
          .update({'goruntulenme': FieldValue.increment(1)});
    }
  }

  @override
  Widget build(BuildContext context) {
    final favorites = ref.watch(favoritesProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('firmalar')
            .doc(widget.companyId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Firma bulunamadı'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final name = data['ad'] as String? ?? '';
          final imageUrl = data['image_url'] as String? ?? data['gorsel'] as String? ?? '';
          final hakkinda = data['hakkinda'] as String? ?? '';
          final iletisim = data['iletisim'] as String? ?? '';
          final yetkiliKisi = data['yetkili_kisi'] as String? ?? '';
          final konum = data['konum'] as String?;
          final website = data['website'] as String?;
          final instagram = data['instagram'] as String?;
          final viewCount = data['goruntulenme'] as int? ?? 0;

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
                  Builder(
                    builder: (context) {
                      final isFav = favorites.any((e) => 
                        e.id == widget.companyId && e.type == 'company');
                      return IconButton(
                        icon: Icon(
                          isFav ? Icons.favorite : Icons.favorite_border,
                          color: isFav ? Colors.red : Colors.white,
                        ),
                        onPressed: () {
                          ref.read(favoritesProvider.notifier)
                              .toggleFavorite(widget.companyId, 'company');
                        },
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
                      Row(
                        children: [
                          Expanded(child: Text(name, style: AppTextStyles.heading2)),
                          Row(
                            children: [
                              const Icon(Icons.visibility_outlined,
                                  size: 16, color: AppColors.textLight),
                              const SizedBox(width: 4),
                              const Text(' '),
                              Text('$viewCount', style: AppTextStyles.bodySmall),
                            ],
                          ),
                        ],
                      ),

                      if (yetkiliKisi.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _buildInfoRow(Icons.person_outline, 'Yetkili Kişi', yetkiliKisi),
                      ],

                      if (iletisim.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _buildInfoRow(Icons.phone, 'İletişim', iletisim),
                      ],

                      if (hakkinda.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text('Hakkında', style: AppTextStyles.heading3),
                        const SizedBox(height: 8),
                        Text(hakkinda, style: AppTextStyles.bodyMedium),
                      ],

                      // Optional web & social
                      if (website != null && website.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _buildLinkRow(Icons.language, 'Web Sitesi', website),
                      ],
                      if (instagram != null && instagram.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _buildLinkRow(Icons.camera_alt_outlined, 'Instagram', instagram),
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

  Widget _buildLinkRow(IconData icon, String label, String url) {
    return InkWell(
      onTap: () async {
        String link = url;
        if (!link.startsWith('http')) link = 'https://$link';
        final uri = Uri.parse(link);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Text('$label: ', style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600)),
          Expanded(
            child: Text(
              url,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.primary,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
