import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/cached_image_widget.dart';
import '../../../core/widgets/map_button.dart';
import '../../../core/widgets/interactive_map_widget.dart';
import '../../../core/utils/map_helper.dart';
import 'package:share_plus/share_plus.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:latlong2/latlong.dart';
import '../../favorites/providers/favorites_provider.dart';
import '../../../core/widgets/review_section.dart';

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

  // Permanent single increment view counter using shared_preferences
  Future<void> _incrementViewCount() async {
    final prefs = await SharedPreferences.getInstance();
    // Unique key per company for this device/user
    final key = 'is_viewed_${widget.companyId}';

    // Only increment if this specific company was NEVER viewed before on this device
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
            return const Scaffold(body: Center(child: Text('Firma bulunamadı')));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final now = DateTime.now();
          if (data.containsKey('expiry_date') && data['expiry_date'] != null) {
            try {
              final expiry = (data['expiry_date'] as Timestamp).toDate();
              if (expiry.isBefore(now)) {
                return Scaffold(
                  appBar: AppBar(),
                  body: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.timer_off_outlined, size: 80, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          const Text(
                            'Bu firmanın kayıt süresi dolmuş veya hizmet geçici olarak durdurulmuştur.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  )
                );
              }
            } catch (e) {
              // handle potentially malformed date data
            }
          }
          final name = data['ad'] as String? ?? '';
          final imageUrl = data['image_url'] as String? ?? data['gorsel'] as String? ?? '';
          final hakkinda = data['hakkinda'] as String? ?? '';
          final iletisim = data['iletisim'] as String? ?? '';
          final yetkiliKisi = data['yetkili_kisi'] as String? ?? '';
          final email = data['email'] as String? ?? '';
          final category = data['kategori'] as String? ?? '';
          final konum = data['konum'] as String?;
          final adres = data['adres'] as String? ?? data['konum'] as String? ?? '';
          final website = data['website'] as String?;
          final instagram = data['instagram'] as String?;

          return Stack(
            children: [
              CustomScrollView(
                physics: const ClampingScrollPhysics(),
                slivers: [
                  // App Bar with Image
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
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    flexibleSpace: FlexibleSpaceBar(
                      background: Stack(
                        fit: StackFit.expand,
                        children: [
                          Hero(
                            tag: 'company-${widget.companyId}',
                            child: CachedImageWidget(
                              imageUrl: imageUrl,
                              fit: BoxFit.cover,
                              isCompany: true,
                            ),
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
                                fontSize: 24,
                                fontWeight: FontWeight.normal,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            if (yetkiliKisi.isNotEmpty)
                              _buildContactRow(Icons.person_rounded, 'Yetkili Kişi', yetkiliKisi),
                            if (iletisim.isNotEmpty)
                              _buildContactRow(Icons.phone_rounded, 'Telefon', iletisim, 
                                onTap: () => _launchURL('tel:$iletisim')),
                            if (website != null && website.isNotEmpty)
                              _buildContactRow(Icons.language_rounded, 'Web Sitesi', website,
                                onTap: () => _launchURL(website)),
                            if (email.isNotEmpty)
                              _buildContactRow(Icons.email_rounded, 'E-Posta', email,
                                onTap: () => _launchURL('mailto:$email')),

                            if (instagram != null && instagram.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              _buildSocialIcon(FontAwesomeIcons.instagram, () => _launchURL(instagram)),
                            ],

                            const SizedBox(height: 40),

                            const Text(
                              'Konum',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (adres.isNotEmpty) ...[
                              _buildModernInfoRow(Icons.location_on_outlined, 'ADRES', adres),
                            ],
                            if (konum != null && konum.isNotEmpty) ...[
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
                            ],
                            const SizedBox(height: 48),

                            // YORUMLAR VE PUANLAMA
                            ReviewSection(
                              targetId: widget.companyId,
                              targetType: 'company',
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

  Widget _buildContactRow(IconData icon, String label, String value, {VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: onTap,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, size: 28, color: const Color(0xFF2E7D32)),
            const SizedBox(width: 12),
            SizedBox(
              width: 90,
              child: Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF2E7D32),
                  fontSize: 16,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ),
            const Text(
              ' :  ',
              style: TextStyle(
                color: Color(0xFF2E7D32),
                fontSize: 16,
                fontWeight: FontWeight.normal,
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 15,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
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

  Widget _buildSocialIcon(dynamic icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (Rect bounds) => const RadialGradient(
            center: Alignment.bottomLeft,
            radius: 1.5,
            colors: [
              Color(0xFFfdf497),
              Color(0xFFf58529),
              Color(0xFFdd2a7b),
              Color(0xFF8134af),
              Color(0xFF515bd4),
            ],
            stops: [0.0, 0.2, 0.5, 0.8, 1.0],
          ).createShader(bounds),
          child: FaIcon(icon, size: 28),
        ),
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
