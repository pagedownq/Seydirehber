import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/cached_image_widget.dart';
import '../../../core/widgets/map_button.dart';
import 'package:share_plus/share_plus.dart';
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
    return Scaffold(
      backgroundColor: Colors.white,
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
          final email = data['email'] as String? ?? '';
          final category = data['kategori'] as String? ?? '';
          final konum = data['konum'] as String?;
          final website = data['website'] as String?;
          final instagram = data['instagram'] as String?;

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
                            isCompany: true,
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
                            Share.share('$name firmasını Seydi Rehber\'de keşfet!');
                          },
                        ),
                      ),
                      Consumer(
                        builder: (context, ref, child) {
                          final favorites = ref.watch(favoritesProvider);
                          final isFav = favorites.any((e) => 
                            e.id == widget.companyId && e.type == 'company');
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
                                    .toggleFavorite(widget.companyId, 'company');
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
                      padding: const EdgeInsets.fromLTRB(25, 10, 25, 120),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title and Category (No Logo)
                            Text(
                              name,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: Colors.black,
                                height: 1.1,
                              ),
                            ),
                                if (category.isNotEmpty) ...[
                                  Text(
                                    category.toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.primaryDark,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                ],

                            const SizedBox(height: 32),

                            // Description
                            if (hakkinda.isNotEmpty) ...[
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

                            // Contact Info Section
                            const Text(
                              'İletişim Bilgileri',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 25),
                            
                            if (yetkiliKisi.isNotEmpty)
                              _buildModernInfoRow(Icons.person_rounded, 'YETKİLİ KİŞİ', yetkiliKisi),
                            if (iletisim.isNotEmpty)
                              _buildModernInfoRow(Icons.phone_rounded, 'TELEFON', iletisim, 
                                onTap: () => _launchURL('tel:$iletisim')),
                            if (website != null && website.isNotEmpty)
                              _buildModernInfoRow(Icons.language_rounded, 'WEB SİTESİ', website,
                                onTap: () => _launchURL(website)),
                            if (email.isNotEmpty)
                              _buildModernInfoRow(Icons.email_rounded, 'E-POSTA ADRESİ', email,
                                onTap: () => _launchURL('mailto:$email')),

                            const SizedBox(height: 20),

                             if (instagram != null && instagram.isNotEmpty) ...[
                               const SizedBox(height: 10),
                               _buildSocialIcon(Icons.camera_alt_rounded, () => _launchURL(instagram)),
                             ],

                            const SizedBox(height: 40),

                            // Location Section
                            const Text(
                              'Konum',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (konum != null && konum.isNotEmpty)
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () => _launchMap(konum),
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

  Widget _buildModernInfoRow(IconData icon, String label, String value, {VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 25),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
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
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialIcon(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.primarySurface,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 20, color: AppColors.primaryDark),
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    String link = url;
    if (link.startsWith('tel:')) {
      final uri = Uri.parse(link);
      if (await canLaunchUrl(uri)) await launchUrl(uri);
      return;
    }
    if (!link.startsWith('http')) link = 'https://$link';
    final uri = Uri.parse(link);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _launchMap(String query) async {
    String mapUrl = '';
    // If it's already a full link, use it, otherwise treat as search query
    if (query.startsWith('http')) {
      mapUrl = query;
    } else {
      mapUrl = 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}';
    }
    
    final uri = Uri.parse(mapUrl);
    
    // On Android/iOS, this LaunchMode will prefer the native app
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
