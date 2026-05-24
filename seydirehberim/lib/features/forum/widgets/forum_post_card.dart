import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/services/haptic_service.dart';
import '../models/forum_post.dart';
import '../providers/forum_providers.dart';
import '../widgets/forum_report_sheet.dart';
import '../widgets/forum_edit_sheet.dart';
import '../../auth/providers/auth_provider.dart';

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
                        ? NetworkImage(post.photoUrl!)
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
                      icon: const Icon(Icons.more_vert,
                          color: AppColors.textLight, size: 20),
                      itemBuilder: (_) => [
                        if (userId != post.userId)
                          PopupMenuItem(
                            value: 'report',
                            child: Row(
                              children: [
                                const Icon(Icons.flag_outlined,
                                    color: AppColors.error, size: 18),
                                const SizedBox(width: 8),
                                Text('Bildir',
                                    style: AppTextStyles.bodySmall
                                        .copyWith(color: AppColors.error)),
                              ],
                            ),
                          ),
                        if (userId == post.userId || isAdmin)
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                const Icon(Icons.delete_outline,
                                    color: AppColors.error, size: 18),
                                const SizedBox(width: 8),
                                Text('Sil',
                                    style: AppTextStyles.bodySmall
                                        .copyWith(color: AppColors.error)),
                              ],
                            ),
                          ),
                        if (userId == post.userId)
                          PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                const Icon(Icons.edit_outlined,
                                    color: AppColors.textSecondary, size: 18),
                                const SizedBox(width: 8),
                                Text('Düzenle',
                                    style: AppTextStyles.bodySmall
                                        .copyWith(color: AppColors.textSecondary)),
                              ],
                            ),
                          ),
                        if (userId != post.userId)
                          PopupMenuItem(
                            value: 'block',
                            child: Row(
                              children: [
                                const Icon(Icons.block,
                                    color: AppColors.error, size: 18),
                                const SizedBox(width: 8),
                                Text('Kullanıcıyı Engelle',
                                    style: AppTextStyles.bodySmall
                                        .copyWith(color: AppColors.error)),
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
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Kullanıcıyı Engelle'),
                              content: const Text('Bu kullanıcıyı engellemek istediğinize emin misiniz? Engellediğinizde bu kişinin paylaşımlarını bir daha göremeyeceksiniz.'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
                                TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Engelle', style: TextStyle(color: Colors.red))),
                              ],
                            ),
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
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Gönderiyi Sil'),
                              content: const Text('Bu gönderiyi silmek istediğinize emin misiniz?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgeç')),
                                TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sil', style: TextStyle(color: Colors.red))),
                              ],
                            ),
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
              child: Text(
                post.content,
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
