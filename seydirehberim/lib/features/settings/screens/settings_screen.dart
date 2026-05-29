import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/app_notification.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/providers/app_info_provider.dart';
import '../../../core/services/block_service.dart';
import '../../forum/providers/forum_providers.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/daily_notification_service.dart';
import '../../../core/services/haptic_service.dart';

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

          // Vefat Notification Toggle
          const _VefatNotificationToggleItem(),
          const SizedBox(height: 8),

          // Haptic Feedback Toggle
          const _HapticToggleItem(),
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


          // Help & Support
          _buildSettingsItem(
            icon: Icons.help_outline,
            title: 'Yardım & Destek',
            subtitle: 'Bize ulaşın',
            iconColor: AppColors.info,
            onTap: () => context.push('/support'),
          ),
          const SizedBox(height: 8),

          _buildSettingsItem(
            icon: Icons.star_outline,
            title: 'Uygulamayı Değerlendir',
            subtitle: defaultTargetPlatform == TargetPlatform.iOS
                ? 'App Store\'da puanlayın'
                : 'Play Store\'da puanlayın',
            iconColor: AppColors.warning,
            onTap: () async {
              final InAppReview inAppReview = InAppReview.instance;
              await inAppReview.openStoreListing(
                appStoreId: '6762803524',
              );
            },
          ),
          const SizedBox(height: 8),
          _buildSettingsItem(
            icon: Icons.person_remove_outlined,
            title: 'Engellenen Kullanıcılar',
            subtitle: 'Engellediğiniz kişileri yönetin',
            iconColor: AppColors.error,
            onTap: () => _showBlockedUsersBottomSheet(context, ref),
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

          const SizedBox(height: 32),
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
                    HapticService.vibrate();

                    final confirmed = await _showPlatformConfirmDialog(
                      context: context,
                      title: 'Çıkış Yap',
                      content: 'Çıkış yapmak istediğinize emin misiniz?',
                      confirmText: 'Çıkış Yap',
                      isDestructive: true,
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
                    HapticService.vibrate();

                    final confirmed = await _showPlatformConfirmDialog(
                      context: context,
                      title: 'Hesabı Sil',
                      content: 'Hesabınız kalıcı olarak silinecek. Bu işlem geri alınamaz.',
                      confirmText: 'Sil',
                      isDestructive: true,
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
          if (Theme.of(context).platform == TargetPlatform.iOS) ...[
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () async {
                  HapticFeedback.vibrate();
                  await ref.read(authNotifierProvider.notifier).signInWithApple();
                },
                icon: const Icon(Icons.apple, size: 24, color: Colors.black),
                label: const Text('Apple ile Giriş Yap', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.black.withOpacity(0.1)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () async {
                HapticFeedback.vibrate();
                await ref.read(authNotifierProvider.notifier).signInWithGoogle();
              },
              icon: Image.network(
                'https://www.google.com/favicon.ico',
                width: 20,
                height: 20,
              ),
              label: const Text('Google ile Giriş Yap', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }


  void _showBlockedUsersBottomSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    const Icon(Icons.person_off_rounded, color: AppColors.error),
                    const SizedBox(width: 12),
                    Text('Engellenen Kullanıcılar', style: AppTextStyles.heading2),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Engelini kaldırmak istediğiniz kullanıcının yanındaki butona basın.',
                  style: AppTextStyles.bodySmall,
                ),
              ),
              const Divider(height: 32),
              Expanded(
                child: FutureBuilder<List<BlockedUser>>(
                  future: BlockService.getBlockedUsersList(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    
                    final list = snapshot.data ?? [];
                    if (list.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_outline, size: 48, color: AppColors.textLight.withOpacity(0.5)),
                            const SizedBox(height: 16),
                            Text('Henüz kimseyi engellemediniz.', style: AppTextStyles.bodySmall),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final user = list[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            radius: 20,
                            backgroundColor: AppColors.primarySurface,
                            backgroundImage: user.imageUrl != null ? NetworkImage(user.imageUrl!) : null,
                            child: user.imageUrl == null ? const Icon(Icons.person, color: AppColors.primary, size: 20) : null,
                          ),
                          title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          subtitle: Text('UID: ${user.uid.substring(0, 8)}...', style: AppTextStyles.caption),
                          trailing: TextButton(
                            onPressed: () async {
                              HapticService.selection();
                              await ref.read(blockedUsersProvider.notifier).unblockUser(user.uid);
                              setModalState(() {});
                              if (context.mounted) {
                                AppNotification.success(context, 'Engel kaldırıldı.');
                              }
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                            ),
                            child: const Text('Engeli Kaldır', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
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
          HapticService.selection();
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

  static Future<bool> _showPlatformConfirmDialog({
    required BuildContext context,
    required String title,
    required String content,
    String confirmText = 'Evet',
    String cancelText = 'Vazgeç',
    bool isDestructive = false,
  }) async {
    if (Platform.isIOS) {
      return await showCupertinoDialog<bool>(
            context: context,
            builder: (context) => CupertinoAlertDialog(
              title: Text(title),
              content: Text(content),
              actions: [
                CupertinoDialogAction(
                  child: Text(cancelText),
                  onPressed: () => Navigator.pop(context, false),
                ),
                CupertinoDialogAction(
                  isDestructiveAction: isDestructive,
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(confirmText),
                ),
              ],
            ),
          ) ??
          false;
    }

    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(content),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(cancelText),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: isDestructive 
                  ? TextButton.styleFrom(foregroundColor: AppColors.error)
                  : null,
                child: Text(confirmText),
              ),
            ],
          ),
        ) ??
        false;
  }

  static Future<bool> checkAndShowPermissionDialog(BuildContext context) async {
    final status = await NotificationService().getPermissionStatus();
    
    if (status.isGranted) return true;

    if (status.isPermanentlyDenied) {
      if (context.mounted) {
        final confirmed = await _showPlatformConfirmDialog(
          context: context,
          title: 'Bildirim İzni Gerekli',
          content: 'Bildirimleri alabilmek için ayarlardan izin vermeniz gerekmektedir. Ayarlara gitmek ister misiniz?',
          confirmText: 'Ayarlara Git',
          cancelText: 'Vazgeç',
        );
        if (confirmed) {
          await openAppSettings();
        }
      }
      return false;
    }

    // Is denied but not permanently (first time or reset)
    final result = await NotificationService().requestPermission();
    return result;
  }
}

class _NotificationToggleItem extends StatefulWidget {
  const _NotificationToggleItem();

  @override
  State<_NotificationToggleItem> createState() => _NotificationToggleItemState();
}

class _NotificationToggleItemState extends State<_NotificationToggleItem> with WidgetsBindingObserver {
  bool? _notificationsEnabled;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadState();
    }
  }

  Future<void> _loadState() async {
    final prefsEnabled = await NotificationService().isNotificationsEnabled();
    final systemStatus = await NotificationService().getPermissionStatus();
    
    if (mounted) {
      setState(() {
        _notificationsEnabled = prefsEnabled && systemStatus.isGranted;
      });
    }
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
          HapticService.selection();
          
          if (value) {
            final hasPermission = await SettingsScreen.checkAndShowPermissionDialog(context);
            if (!hasPermission) return;
          }

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

class _DailyNotificationToggleItemState extends State<_DailyNotificationToggleItem> with WidgetsBindingObserver {
  bool? _dailyEnabled;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadState();
    }
  }

  Future<void> _loadState() async {
    final prefsEnabled = await DailyNotificationService().isDailyNotificationsEnabled();
    final systemStatus = await NotificationService().getPermissionStatus();
    
    if (mounted) {
      setState(() {
        _dailyEnabled = prefsEnabled && systemStatus.isGranted;
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
          HapticService.selection();

          if (value) {
            final hasPermission = await SettingsScreen.checkAndShowPermissionDialog(context);
            if (!hasPermission) return;
          }

          setState(() {
            _dailyEnabled = value;
          });
          await DailyNotificationService().setDailyNotificationsEnabled(value);
        },
      ),
    );
  }
}

class _HapticToggleItem extends StatefulWidget {
  const _HapticToggleItem();

  @override
  State<_HapticToggleItem> createState() => _HapticToggleItemState();
}

class _HapticToggleItemState extends State<_HapticToggleItem> {
  bool? _hapticsEnabled;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    // Getter is enough since main.dart initializes it
    setState(() {
      _hapticsEnabled = HapticService.hapticsEnabled;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_hapticsEnabled == null) {
      return const SizedBox(height: 60);
    }

    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(14),
      child: SwitchListTile(
        activeColor: AppColors.primary,
        title: Text(
          'Titreşimleri Kapat',
          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          _hapticsEnabled! ? 'Baskı titreşimleri açık' : 'Titreşimler kapatıldı',
          style: AppTextStyles.caption,
        ),
        secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.vibration, color: Colors.orange, size: 22),
        ),
        value: !_hapticsEnabled!, // Switch ON means "Kapat" is active
        onChanged: (value) async {
          // If value is true, we ARE closing vibrations, so new state is false.
          final newHapticState = !value;
          
          setState(() {
            _hapticsEnabled = newHapticState;
          });
          
          await HapticService.setEnabled(newHapticState);
          
          // Only vibrate as feedback if we just TURNED IT ON
          if (newHapticState) {
            HapticService.medium();
          }
        },
      ),
    );
  }
}

class _VefatNotificationToggleItem extends StatefulWidget {
  const _VefatNotificationToggleItem();

  @override
  State<_VefatNotificationToggleItem> createState() => _VefatNotificationToggleItemState();
}

class _VefatNotificationToggleItemState extends State<_VefatNotificationToggleItem> with WidgetsBindingObserver {
  bool? _vefatEnabled;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadState();
    }
  }

  Future<void> _loadState() async {
    final prefsEnabled = await NotificationService().isVefatNotificationsEnabled();
    final systemStatus = await NotificationService().getPermissionStatus();
    
    if (mounted) {
      setState(() {
        _vefatEnabled = prefsEnabled && systemStatus.isGranted;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_vefatEnabled == null) {
      return const SizedBox(height: 60, child: Center(child: CircularProgressIndicator()));
    }

    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(14),
      child: SwitchListTile(
        activeColor: const Color(0xFF1A3F6A),
        title: Text(
          'Vefat İlanları',
          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          _vefatEnabled!
              ? 'Vefat ilanlarından haberdar oluyorsunuz'
              : 'Vefat ilanları bildirimi kapatıldı',
          style: AppTextStyles.caption,
        ),
        secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF1A3F6A).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.history_edu_rounded, color: Color(0xFF1A3F6A), size: 22),
        ),
        value: _vefatEnabled!,
        onChanged: (value) async {
          HapticService.selection();

          if (value) {
            final hasPermission = await SettingsScreen.checkAndShowPermissionDialog(context);
            if (!hasPermission) return;
          }

          setState(() {
            _vefatEnabled = value;
          });
          await NotificationService().setVefatNotificationsEnabled(value);
        },
      ),
    );
  }
}



