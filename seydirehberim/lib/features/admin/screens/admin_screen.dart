import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../auth/providers/auth_provider.dart';

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
