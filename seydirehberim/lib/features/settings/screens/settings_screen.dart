import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../auth/providers/auth_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final isAdmin = ref.watch(isAdminProvider);
    final isGuest = ref.watch(isGuestProvider);

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
          if (isAdmin) ...[
            _buildSettingsItem(
              icon: Icons.admin_panel_settings,
              title: 'Yönetim Paneli',
              subtitle: 'İçerik yönetimi',
              iconColor: AppColors.error,
              onTap: () => context.push('/admin'),
            ),
            const SizedBox(height: 8),
          ],

          // Contact Form
          _buildSettingsItem(
            icon: Icons.help_outline,
            title: 'Yardım & Destek',
            subtitle: 'Bize ulaşın',
            iconColor: AppColors.info,
            onTap: () => _showContactForm(context),
          ),
          const SizedBox(height: 8),

          // Rate App
          _buildSettingsItem(
            icon: Icons.star_outline,
            title: 'Uygulamayı Değerlendir',
            subtitle: 'Play Store\'da puanlayın',
            iconColor: AppColors.warning,
            onTap: () async {
              final review = InAppReview.instance;
              if (await review.isAvailable()) {
                review.requestReview();
              }
            },
          ),
          const SizedBox(height: 8),

          // Privacy Policy
          _buildSettingsItem(
            icon: Icons.privacy_tip_outlined,
            title: 'Gizlilik Politikası',
            subtitle: 'Verileriniz güvende',
            iconColor: AppColors.primary,
            onTap: () {},
          ),
          const SizedBox(height: 8),

          // App Version
          _buildSettingsItem(
            icon: Icons.info_outline,
            title: 'Uygulama Hakkında',
            subtitle: 'Seydi Rehber v1.0.0',
            iconColor: AppColors.textLight,
            onTap: () {},
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
            color: Colors.black.withValues(alpha: 0.05),
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
                  label: const Text('Çıkış Yap'),
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
                  label: const Text('Hesabı Sil'),
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
            color: Colors.black.withValues(alpha: 0.05),
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
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
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

  void _showContactForm(BuildContext context) {
    final nameController = TextEditingController();
    final messageController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          20, 20, 20,
          MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Yardım & Destek', style: AppTextStyles.heading3),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Adınız',
                hintText: 'Adınızı girin',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: messageController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Mesajınız',
                hintText: 'Mesajınızı yazın',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (nameController.text.isEmpty || messageController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Tüm alanları doldurun')),
                    );
                    return;
                  }
                  await FirebaseFirestore.instance.collection('yardim_destek').add({
                    'ad': nameController.text,
                    'mesaj': messageController.text,
                    'tarih': FieldValue.serverTimestamp(),
                  });
                  if (context.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Mesajınız gönderildi!'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                },
                child: const Text('Gönder'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
