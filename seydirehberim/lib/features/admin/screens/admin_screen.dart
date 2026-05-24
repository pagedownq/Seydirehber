import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/services/review_service.dart';
import '../../../core/services/stat_service.dart';
import 'admin_forum_screen.dart';

class AdminScreen extends ConsumerWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdminAsync = ref.watch(isAdminProvider);

    return isAdminAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, __) => const Scaffold(body: Center(child: Text('Yetki kontrolü hatası'))),
      data: (isAdmin) {
        if (!isAdmin) {
          return const Scaffold(
            body: Center(child: Text('Yetkiniz yok')),
          );
        }
        return ref.watch(adminPermissionsProvider).when(
          loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (_, __) => const Scaffold(body: Center(child: Text('Yetki detayları alınamadı'))),
          data: (permissions) {
            return Scaffold(
              backgroundColor: AppColors.background,
              appBar: AppBar(
                title: Text('Yönetim Paneli', style: AppTextStyles.appBarTitle),
                backgroundColor: AppColors.white,
                elevation: 0,
              ),
              body: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // --- Live Statistics ---
                  ref.watch(appStatsProvider).when(
                    data: (stats) => Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.analytics_outlined, color: AppColors.primary, size: 20),
                              const SizedBox(width: 8),
                              Text('Canlı İstatistikler', style: AppTextStyles.heading3.copyWith(fontSize: 16)),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: Colors.green,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${stats.activeNow} Aktif',
                                      style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              // --- Purge Button ---
                              IconButton(
                                icon: const Icon(Icons.cleaning_services_outlined, size: 20, color: Colors.grey),
                                tooltip: 'Gereksiz Cihazları Temizle',
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Veritabanı Temizliği'),
                                      content: const Text('Son 30 gündür uygulamayı hiç açmamış olan cihaz kayıtlarını silmek istediğinize emin misiniz? (Bu işlem sadece çöp verileri temizler)'),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Vazgeç')),
                                        ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Temizle')),
                                      ],
                                    ),
                                  );

                                  if (confirm == true) {
                                    if (!context.mounted) return;
                                    try {
                                      final count = await ref.read(statServiceProvider).purgeInactiveTokens();
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('$count adet geçersiz cihaz kaydı temizlendi.')),
                                      );
                                    } catch (e) {
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Hata: $e')),
                                      );
                                    }
                                  }
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              _StatItem(
                                label: 'Toplam Cihaz',
                                value: stats.totalCount.toString(),
                                icon: Icons.devices,
                                color: AppColors.primary,
                              ),
                              _StatItem(
                                label: 'Bugün Aktif',
                                value: stats.activeToday.toString(),
                                icon: Icons.bolt,
                                color: Colors.orange,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _StatItem(
                                label: 'Misafir',
                                value: stats.guestCount.toString(),
                                icon: Icons.person_outline,
                                color: Colors.grey,
                              ),
                              _StatItem(
                                label: 'Üye',
                                value: stats.registeredCount.toString(),
                                icon: Icons.person,
                                color: Colors.blue,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    loading: () => const Center(child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: CircularProgressIndicator(),
                    )),
                    error: (err, stack) => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text('İstatistik hatası: $err', style: const TextStyle(color: Colors.red, fontSize: 12)),
                      ),
                    ),
                  ),

                  if (permissions['canManageBanners'] ?? false) ...[
                    _AdminCard(
                      icon: Icons.photo_library,
                      title: 'Banner Yönetimi',
                      color: const Color(0xFF7B1FA2),
                      onTap: () => context.push('/admin/manage', extra: {
                        'collection': 'banners',
                        'title': 'Banner Yönetimi',
                        'bucket': 'banner',
                      }),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (permissions['canManageEvents'] ?? false) ...[
                    _AdminCard(
                      icon: Icons.event,
                      title: 'Etkinlik Yönetimi',
                      color: const Color(0xFFE53935),
                      onTap: () => context.push('/admin/manage', extra: {
                        'collection': 'etkinlikler',
                        'title': 'Etkinlik Yönetimi',
                        'bucket': 'etkinlikler',
                      }),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (permissions['canManageNotaries'] ?? false) ...[
                    _AdminCard(
                      icon: Icons.gavel,
                      title: 'Noter Yönetimi',
                      color: const Color(0xFF5C6BC0),
                      onTap: () => context.push('/admin/manage', extra: {
                        'collection': 'noterler',
                        'title': 'Noter Yönetimi',
                        'bucket': 'noter',
                      }),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (permissions['canManageMarkets'] ?? false) ...[
                    _AdminCard(
                      icon: Icons.storefront,
                      title: 'Pazar Yönetimi',
                      color: const Color(0xFFFF8F00),
                      onTap: () => context.push('/admin/manage', extra: {
                        'collection': 'pazarlar',
                        'title': 'Pazar Yönetimi',
                        'bucket': 'pazar',
                      }),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (permissions['canManageBuses'] ?? false) ...[
                    _AdminCard(
                      icon: Icons.directions_bus,
                      title: 'Otobüs Saatleri Yönetimi',
                      color: const Color(0xFF00897B),
                      onTap: () => context.push('/admin/manage', extra: {
                        'collection': 'otobus_saatleri',
                        'title': 'Otobüs Saatleri',
                        'bucket': null,
                      }),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (permissions['canManagePlaces'] ?? false) ...[
                    _AdminCard(
                      icon: Icons.place,
                      title: 'Gezilecek Yerler Yönetimi',
                      color: const Color(0xFF43A047),
                      onTap: () => context.push('/admin/manage', extra: {
                        'collection': 'gezilecek_yerler',
                        'title': 'Gezilecek Yerler',
                        'bucket': 'gezilcek_yerler',
                      }),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (permissions['canManageCompanies'] ?? false) ...[
                    _AdminCard(
                      icon: Icons.business,
                      title: 'Firma Yönetimi',
                      color: const Color(0xFF1565C0),
                      onTap: () => context.push('/admin/manage', extra: {
                        'collection': 'firmalar',
                        'title': 'Firma Yönetimi',
                        'bucket': 'firmalar',
                      }),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (permissions['canManageSupport'] ?? false) ...[
                    _AdminCard(
                      icon: Icons.support_agent,
                      title: 'Yardım & Destek Mesajları',
                      color: const Color(0xFFD32F2F),
                      onTap: () => context.push('/admin/support'),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (permissions['canManageReviews'] ?? false) ...[
                    _AdminCard(
                      icon: Icons.rate_review_outlined,
                      title: 'Yorum Yönetimi',
                      color: const Color(0xFFFBC02D),
                      onTap: () => context.push('/admin/reviews'),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (permissions['canManageReports'] ?? false) ...[
                    _AdminCard(
                      icon: Icons.report_problem_outlined,
                      title: 'Yorum Şikayetleri',
                      color: const Color(0xFFD32F2F),
                      onTap: () => context.push('/admin/reports'),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (permissions['canManageForum'] ?? false) ...[
                    _AdminCard(
                      icon: Icons.forum_rounded,
                      title: 'Forum Moderasyonu',
                      color: const Color(0xFF5C35CC),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const AdminForumScreen(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (permissions['canManageNotifications'] ?? false) ...[
                    _AdminCard(
                      icon: Icons.notifications_active,
                      title: 'Bildirim Yönetimi',
                      color: const Color(0xFF0288D1),
                      onTap: () => context.push('/admin/notifications'),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (permissions['canManageEsnaf'] ?? false) ...[
                    _AdminCard(
                      icon: Icons.people,
                      title: 'Esnaf Hesapları',
                      color: const Color(0xFF7E57C2),
                      onTap: () => context.push('/admin/manage', extra: {
                        'collection': 'esnaf_users',
                        'title': 'Esnaf Hesapları',
                        'bucket': null,
                      }),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (permissions['canManageCoupons'] ?? false) ...[
                    _AdminCard(
                      icon: Icons.confirmation_number,
                      title: 'Kupon Yönetimi',
                      color: const Color(0xFFEC407A),
                      onTap: () => context.push('/admin/manage', extra: {
                        'collection': 'coupons',
                        'title': 'Kupon Yönetimi',
                        'bucket': null,
                      }),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (permissions['canManageAdmins'] ?? false) ...[
                    _AdminCard(
                      icon: Icons.admin_panel_settings,
                      title: 'Admin Yönetimi',
                      color: const Color(0xFF263238),
                      onTap: () => context.push('/admin/manage', extra: {
                        'collection': 'admins',
                        'title': 'Admin Yönetimi',
                        'bucket': null,
                      }),
                    ),
                    const SizedBox(height: 12),
                    _AdminCard(
                      icon: Icons.sync,
                      title: 'Yorum İstatistiklerini Eşitle',
                      color: const Color(0xFF455A64),
                      onTap: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('İstatistikleri Eşitle'),
                            content: const Text('Tüm firma ve yerlerin yorum sayılarını ve puanlarını yeniden hesaplamak istediğinize emin misiniz? Bu işlem biraz zaman alabilir.'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('İptal'),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Evet, Başlat'),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Eşitleme işlemi başlatıldı...')),
                          );
                          
                          try {
                            await ref.read(reviewServiceProvider).syncAllReviewStats();
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Eşitleme başarıyla tamamlandı!')),
                            );
                          } catch (e) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Hata oluştu: $e')),
                            );
                          }
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}
class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color.withOpacity(0.7), size: 16),
              const SizedBox(width: 6),
              Text(label, style: AppTextStyles.caption),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.heading2.copyWith(color: color, fontSize: 24),
          ),
        ],
      ),
    );
  }
}

class _AdminCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _AdminCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 1,
      shadowColor: Colors.black12,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.bodyMedium
                      .copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              const Icon(Icons.arrow_forward_ios,
                  size: 14, color: AppColors.textLight),
            ],
          ),
        ),
      ),
    );
  }
}
