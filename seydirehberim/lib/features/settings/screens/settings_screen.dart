import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/app_notification.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/providers/app_info_provider.dart';
import '../../../core/services/block_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/daily_notification_service.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final isAdmin = ref.watch(isAdminProvider);
    final isGuest = ref.watch(isGuestProvider);

    // Listen to authentication status and errors
    ref.listen<AsyncValue<User?>>(authNotifierProvider, (previous, next) {
      if (next is AsyncError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error.toString()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Ayarlar', style: AppTextStyles.appBarTitle),
        backgroundColor: AppColors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile Card
          authState.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const SizedBox.shrink(),
            data: (user) {
              if (user == null || isGuest) {
                return _buildGuestCard(context, ref);
              }
              return _buildProfileCard(context, user, ref);
            },
          ),

          const SizedBox(height: 20),

          // Admin Panel - Only for admin user
          isAdmin.when(
            data: (isAdminValue) => isAdminValue
                ? Column(
                    children: [
                      _buildSettingsItem(
                        icon: Icons.admin_panel_settings,
                        title: 'Yönetim Paneli',
                        subtitle: 'İçerik yönetimi',
                        iconColor: AppColors.error,
                        onTap: () => context.push('/admin'),
                      ),
                      const SizedBox(height: 8),
                    ],
                  )
                : const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          // Notification Toggle
          const _NotificationToggleItem(),
          const SizedBox(height: 8),

          // Daily Notification Toggle
          const _DailyNotificationToggleItem(),
          const SizedBox(height: 8),

          // Favorites
          _buildSettingsItem(
            icon: Icons.favorite_border,
            title: 'Favorilerim',
            subtitle: 'Kaydettiğiniz yerler ve firmalar',
            iconColor: Colors.red,
            onTap: () => context.push('/favorites'),
          ),
          const SizedBox(height: 8),

          // Interactive Map
          _buildSettingsItem(
            icon: Icons.map_outlined,
            title: 'Seydi Harita',
            subtitle: 'Şehri interaktif keşfedin',
            iconColor: AppColors.primary,
            onTap: () => context.push('/seydi-map'),
          ),
          const SizedBox(height: 8),

          // Help & Support
          _buildSettingsItem(
            icon: Icons.help_outline,
            title: 'Yardım & Destek',
            subtitle: 'Bize ulaşın',
            iconColor: AppColors.info,
            onTap: () => context.push('/support'),
          ),
          const SizedBox(height: 8),

          // Rate App
          _buildSettingsItem(
            icon: Icons.star_outline,
            title: 'Uygulamayı Değerlendir',
            subtitle: 'Play Store\'da puanlayın',
            iconColor: AppColors.warning,
            onTap: () async {
              final InAppReview inAppReview = InAppReview.instance;
              // Uygulama mağazası sayfasını direkt açar
              await inAppReview.openStoreListing();
            },
          ),
          // Clear Blocked Users
          _buildSettingsItem(
            icon: Icons.person_remove_outlined,
            title: 'Engellenen Kullanıcıları Kaldır',
            subtitle: 'Tüm engelleri temizle',
            iconColor: AppColors.error,
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => Dialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.error.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.person_remove_rounded, size: 32, color: AppColors.error),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Engelleri Kaldır',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.heading2,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Tüm engellediğiniz kullanıcıların engelini kaldırmak istediğinize emin misiniz? Bu işlem geri alınamaz.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textSecondary, height: 1.4),
                        ),
                        const SizedBox(height: 32),
                        Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: const Text('Vazgeç', style: TextStyle(fontWeight: FontWeight.w600)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.error,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: const Text('Kaldır', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );

              if (confirm == true) {
                await BlockService.clearBlockedUsers();
                if (context.mounted) {
                  AppNotification.success(context, 'Tüm kullanıcıların engeli kaldırıldı.');
                }
              }
            },
          ),
          const SizedBox(height: 8),


          // Policies
          _buildSettingsItem(
            icon: Icons.privacy_tip_outlined,
            title: 'Politikalar',
            subtitle: 'Gizlilik ve kullanım koşulları',
            iconColor: AppColors.primary,
            onTap: () => context.push('/policies'),
          ),
          const SizedBox(height: 8),

          // App Version
          ref.watch(appVersionProvider).when(
            data: (version) => _buildSettingsItem(
              icon: Icons.info_outline,
              title: 'Uygulama Hakkında',
              subtitle: 'Seydi Rehber v$version',
              iconColor: AppColors.textLight,
              onTap: () {},
            ),
            loading: () => _buildSettingsItem(
              icon: Icons.info_outline,
              title: 'Uygulama Hakkında',
              subtitle: 'Sürüm bilgisi yükleniyor...',
              iconColor: AppColors.textLight,
              onTap: () {},
            ),
            error: (_, __) => _buildSettingsItem(
              icon: Icons.info_outline,
              title: 'Uygulama Hakkında',
              subtitle: 'Seydi Rehber',
              iconColor: AppColors.textLight,
              onTap: () {},
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context, dynamic user, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.primarySurface,
                backgroundImage: user.photoURL != null
                    ? NetworkImage(user.photoURL!)
                    : null,
                child: user.photoURL == null
                    ? const Icon(Icons.person, color: AppColors.primary, size: 28)
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.displayName ?? 'Kullanıcı',
                      style: AppTextStyles.heading3,
                    ),
                    Text(
                      user.email ?? '',
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {

                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Çıkış Yap'),
                        content: const Text('Çıkış yapmak istediğinize emin misiniz?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('İptal'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Çıkış Yap'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true) {
                      await ref.read(authNotifierProvider.notifier).signOut();
                    }
                  },
                  icon: const Icon(Icons.logout, size: 18),
                  label: const Text('Çıkış Yap', maxLines: 1, overflow: TextOverflow.ellipsis),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {

                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Hesabı Sil'),
                        content: const Text(
                            'Hesabınız kalıcı olarak silinecek. Bu işlem geri alınamaz.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('İptal'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            style: TextButton.styleFrom(foregroundColor: AppColors.error),
                            child: const Text('Sil'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true) {
                      await ref.read(authNotifierProvider.notifier).deleteAccount();
                    }
                  },
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Hesabı Sil', maxLines: 1, overflow: TextOverflow.ellipsis),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textLight,
                    side: const BorderSide(color: AppColors.border),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGuestCard(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.primarySurface,
            child: Icon(Icons.person_outline, color: AppColors.primary, size: 28),
          ),
          const SizedBox(height: 12),
          Text('Misafir Kullanıcı', style: AppTextStyles.heading3),
          const SizedBox(height: 4),
          Text(
            'Giriş yaparak tüm özelliklere erişin',
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {

                await ref.read(authNotifierProvider.notifier).signInWithGoogle();
              },
              icon: const Icon(Icons.login, size: 18),
              label: const Text('Google ile Giriş Yap'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(14),
      child: ListTile(
        onTap: () {

          onTap();
        },
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        title: Text(title, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: AppTextStyles.caption),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textLight),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}

class _NotificationToggleItem extends StatefulWidget {
  const _NotificationToggleItem();

  @override
  State<_NotificationToggleItem> createState() => _NotificationToggleItemState();
}

class _NotificationToggleItemState extends State<_NotificationToggleItem> {
  bool? _notificationsEnabled;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    final enabled = await NotificationService().isNotificationsEnabled();
    setState(() {
      _notificationsEnabled = enabled;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_notificationsEnabled == null) {
      return const SizedBox(height: 60, child: Center(child: CircularProgressIndicator()));
    }

    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(14),
      child: SwitchListTile(
        activeColor: AppColors.primary,
        title: Text(
          'Bildirimleri Al',
          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          _notificationsEnabled! ? 'Duyuruları alıyorsunuz' : 'Duyurular kapatıldı',
          style: AppTextStyles.caption,
        ),
        secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.notifications_outlined, color: AppColors.primary, size: 22),
        ),
        value: _notificationsEnabled!,
        onChanged: (value) async {

          setState(() {
            _notificationsEnabled = value;
          });
          await NotificationService().setNotificationsEnabled(value);
        },
      ),
    );
  }
}

class _DailyNotificationToggleItem extends StatefulWidget {
  const _DailyNotificationToggleItem();

  @override
  State<_DailyNotificationToggleItem> createState() => _DailyNotificationToggleItemState();
}

class _DailyNotificationToggleItemState extends State<_DailyNotificationToggleItem> {
  bool? _dailyEnabled;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    final enabled = await DailyNotificationService().isDailyNotificationsEnabled();
    if (mounted) {
      setState(() {
        _dailyEnabled = enabled;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_dailyEnabled == null) {
      return const SizedBox(height: 60, child: Center(child: CircularProgressIndicator()));
    }

    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(14),
      child: SwitchListTile(
        activeColor: AppColors.primary,
        title: Text(
          'Günlük Hatırlatmalar',
          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          _dailyEnabled!
              ? 'Gün içinde öneriler alıyorsunuz'
              : 'Günlük öneriler kapatıldı',
          style: AppTextStyles.caption,
        ),
        secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.info.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.tips_and_updates_outlined, color: AppColors.info, size: 22),
        ),
        value: _dailyEnabled!,
        onChanged: (value) async {

          setState(() {
            _dailyEnabled = value;
          });
          await DailyNotificationService().setDailyNotificationsEnabled(value);
        },
      ),
    );
  }
}
