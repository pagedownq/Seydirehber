import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/services/haptic_service.dart';
import '../../../core/widgets/modern_confirm_dialog.dart';
import '../models/forum_post.dart';
import '../providers/forum_providers.dart';
import '../widgets/forum_report_sheet.dart';
import '../widgets/forum_edit_sheet.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/widgets/linkable_text.dart';

/// Gönderi listesi kartı.
class ForumPostCard extends ConsumerWidget {
  final ForumPost post;
  /// Admin ise gerçek kullanıcı bilgisini göster
  final bool isAdmin;

  const ForumPostCard({
    super.key,
    required this.post,
    this.isAdmin = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(authStateProvider).value?.uid;
    final service = ref.read(forumServiceProvider);

    return GestureDetector(
      onTap: () {
        HapticService.selection();
        context.push('/forum/${post.id}');
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Üst kısım: avatar + isim + kategori + menü
            Padding(
              padding:
                  const EdgeInsets.only(left: 16, right: 8, top: 14, bottom: 4),
              child: Row(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: post.isAnonymous
                        ? Colors.grey[200]
                        : AppColors.primarySurface,
                    backgroundImage: !post.isAnonymous && post.photoUrl != null
                        ? CachedNetworkImageProvider(post.photoUrl!)
                        : null,
                    child: (!post.isAnonymous && post.photoUrl != null)
                        ? null
                        : Icon(
                            post.isAnonymous
                                ? Icons.person_off_rounded
                                : Icons.person_rounded,
                            color: post.isAnonymous
                                ? Colors.grey[500]
                                : AppColors.primary,
                            size: 18,
                          ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Admin gerçek ismi görür
                        Text(
                          isAdmin && post.isAnonymous
                              ? '${post.publicDisplayName} (${post.displayName})'
                              : post.publicDisplayName,
                          style: AppTextStyles.bodySmall.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          _timeAgo(post.createdAt) + (post.isEdited ? ' (Düzenlendi)' : ''),
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ),
                  // Kategori chip
                  _CategoryChip(category: post.category),
                  const SizedBox(width: 4),
                  // Menü (Bildir veya Sil)
                  if (userId != null)
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_horiz_rounded,
                          color: AppColors.textLight, size: 22),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      color: Colors.white,
                      elevation: 10,
                      position: PopupMenuPosition.under,
                      offset: const Offset(0, 5),
                      itemBuilder: (_) => [
                        if (userId != post.userId)
                          PopupMenuItem(
                            value: 'report',
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(color: AppColors.error.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                                  child: const Icon(Icons.flag_rounded, color: AppColors.error, size: 18),
                                ),
                                const SizedBox(width: 12),
                                Text('Bildir', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        if (userId == post.userId || isAdmin)
                          PopupMenuItem(
                            value: 'delete',
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(color: AppColors.error.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                                  child: const Icon(Icons.delete_rounded, color: AppColors.error, size: 18),
                                ),
                                const SizedBox(width: 12),
                                Text('Sil', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        if (userId == post.userId)
                          PopupMenuItem(
                            value: 'edit',
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                                  child: const Icon(Icons.edit_rounded, color: AppColors.primary, size: 18),
                                ),
                                const SizedBox(width: 12),
                                Text('Düzenle', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        if (userId != post.userId)
                          PopupMenuItem(
                            value: 'block',
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(color: AppColors.error.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                                  child: const Icon(Icons.block_rounded, color: AppColors.error, size: 18),
                                ),
                                const SizedBox(width: 12),
                                Text('Kullanıcıyı Engelle', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                      ],
                      onSelected: (value) async {
                        if (value == 'report') {
                          ForumReportSheet.show(
                            context,
                            contentType: 'gönderi',
                            onReport: (reason) => service.reportPost(
                              postId: post.id,
                              reporterId: userId,
                            ),
                          );
                        } else if (value == 'block') {
                          final confirm = await showModernConfirmDialog(
                            context: context,
                            title: 'Kullanıcıyı Engelle',
                            content: 'Bu kullanıcıyı engellemek istediğinize emin misiniz? Engellediğinizde bu kişinin paylaşımlarını bir daha göremeyeceksiniz.',
                            confirmLabel: 'Engelle',
                            cancelLabel: 'İptal',
                            icon: Icons.block_outlined,
                            iconColor: AppColors.error,
                            isDestructive: true,
                          );
                          if (confirm == true) {
                            ref.read(blockedUsersProvider.notifier).blockUser(
                              post.userId, 
                              post.publicDisplayName, 
                              post.photoUrl
                            );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kullanıcı engellendi.')));
                            }
                          }
                        } else if (value == 'delete') {
                          final confirm = await showModernConfirmDialog(
                            context: context,
                            title: 'Gönderiyi Sil',
                            content: 'Bu gönderiyi silmek istediğinize emin misiniz? Bu işlem geri alınamaz.',
                            confirmLabel: 'Sil',
                            cancelLabel: 'Vazgeç',
                            icon: Icons.delete_outline_rounded,
                            iconColor: AppColors.error,
                            isDestructive: true,
                          );
                          if (confirm == true) {
                            try {
                              if (isAdmin) {
                                await service.deletePost(post.id);
                              } else {
                                await service.deleteOwnPost(post.id);
                              }
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gönderi silindi.')));
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
                              }
                            }
                          }
                        } else if (value == 'edit') {
                          ForumEditSheet.showPostEdit(context, post, service);
                        }
                      },
                    ),
                ],
              ),
            ),

            // Başlık
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(
                post.title,
                style: AppTextStyles.bodyMedium
                    .copyWith(fontWeight: FontWeight.w700),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // İçerik önizleme
            Padding(
              padding:
                  const EdgeInsets.only(left: 16, right: 16, bottom: 14, top: 2),
              child: LinkableText(
                text: post.content,
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textSecondary, height: 1.5),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Alt çizgi ve yanıt sayısı
            Container(
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(18)),
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  const Icon(Icons.chat_bubble_outline_rounded,
                      size: 14, color: AppColors.textLight),
                  const SizedBox(width: 4),
                  Text(
                    '${post.replyCount} yanıt',
                    style: AppTextStyles.caption,
                  ),
                  const Spacer(),
                  if (post.helpfulVoterIds.isNotEmpty || post.unhelpfulVoterIds.isNotEmpty) ...[
                    const Icon(Icons.thumb_up_alt_outlined, size: 14, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text('${post.helpfulVoterIds.length}', style: AppTextStyles.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 12),
                    const Icon(Icons.thumb_down_alt_outlined, size: 14, color: AppColors.error),
                    const SizedBox(width: 4),
                    Text('${post.unhelpfulVoterIds.length}', style: AppTextStyles.caption.copyWith(color: AppColors.error, fontWeight: FontWeight.w600)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _timeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inDays > 0) return '${diff.inDays}g önce';
    if (diff.inHours > 0) return '${diff.inHours}s önce';
    if (diff.inMinutes > 0) return '${diff.inMinutes}d önce';
    return 'Az önce';
  }
}

class _CategoryChip extends StatelessWidget {
  final String category;
  const _CategoryChip({required this.category});

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (category) {
      'soru' => (const Color(0xFF1565C0), '❓ Soru'),
      'tavsiye' => (const Color(0xFF2E7D32), '💡 Tavsiye'),
      'etkinlik' => (const Color(0xFFE65100), '📅 Etkinlik'),
      _ => (const Color(0xFF546E7A), '💬 Genel'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
