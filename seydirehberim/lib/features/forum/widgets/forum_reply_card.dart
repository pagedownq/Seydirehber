import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/modern_confirm_dialog.dart';
import '../models/forum_reply.dart';
import '../providers/forum_providers.dart';
import '../widgets/forum_report_sheet.dart';
import '../widgets/forum_edit_sheet.dart';
import '../../auth/providers/auth_provider.dart';

/// Yanıt kartı.
class ForumReplyCard extends ConsumerWidget {
  final ForumReply reply;
  final bool isAdmin;

  const ForumReplyCard({
    super.key,
    required this.reply,
    this.isAdmin = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(authStateProvider).value?.uid;
    final service = ref.read(forumServiceProvider);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 15,
                backgroundColor: reply.isAnonymous
                    ? Colors.grey[200]
                    : AppColors.primarySurface,
                backgroundImage: !reply.isAnonymous && reply.photoUrl != null
                    ? NetworkImage(reply.photoUrl!)
                    : null,
                child: (!reply.isAnonymous && reply.photoUrl != null)
                    ? null
                    : Icon(
                        reply.isAnonymous
                            ? Icons.person_off_rounded
                            : Icons.person_rounded,
                        size: 15,
                        color: reply.isAnonymous
                            ? Colors.grey[500]
                            : AppColors.primary,
                      ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAdmin && reply.isAnonymous
                          ? '${reply.publicDisplayName} (${reply.displayName})'
                          : reply.publicDisplayName,
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        fontSize: 12,
                      ),
                    ),
                    Text(_timeAgo(reply.createdAt) + (reply.isEdited ? ' (Düzenlendi)' : ''),
                        style: AppTextStyles.caption),
                  ],
                ),
              ),
              // Menü (Bildir veya Sil)
              if (userId != null)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_horiz_rounded,
                      color: AppColors.textLight, size: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  color: Colors.white,
                  elevation: 10,
                  position: PopupMenuPosition.under,
                  offset: const Offset(0, 5),
                  itemBuilder: (_) => [
                    if (userId != reply.userId)
                      PopupMenuItem(
                        value: 'report',
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: AppColors.error.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                              child: const Icon(Icons.flag_rounded, color: AppColors.error, size: 16),
                            ),
                            const SizedBox(width: 12),
                            Text('Bildir', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    if (userId == reply.userId || isAdmin)
                      PopupMenuItem(
                        value: 'delete',
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: AppColors.error.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                              child: const Icon(Icons.delete_rounded, color: AppColors.error, size: 16),
                            ),
                            const SizedBox(width: 12),
                            Text('Sil', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    if (userId == reply.userId)
                      PopupMenuItem(
                        value: 'edit',
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                              child: const Icon(Icons.edit_rounded, color: AppColors.primary, size: 16),
                            ),
                            const SizedBox(width: 12),
                            Text('Düzenle', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    if (userId != reply.userId)
                      PopupMenuItem(
                        value: 'block',
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: AppColors.error.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                              child: const Icon(Icons.block_rounded, color: AppColors.error, size: 16),
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
                        contentType: 'yanıt',
                        onReport: (reason) => service.reportReply(
                          replyId: reply.id,
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
                          reply.userId, 
                          reply.publicDisplayName, 
                          reply.photoUrl
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kullanıcı engellendi.')));
                        }
                      }
                    } else if (value == 'delete') {
                      final confirm = await showModernConfirmDialog(
                        context: context,
                        title: 'Yanıtı Sil',
                        content: 'Bu yanıtı silmek istediğinize emin misiniz? Bu işlem geri alınamaz.',
                        confirmLabel: 'Sil',
                        cancelLabel: 'Vazgeç',
                        icon: Icons.delete_outline_rounded,
                        iconColor: AppColors.error,
                        isDestructive: true,
                      );
                      if (confirm == true) {
                        try {
                          if (isAdmin) {
                            await service.deleteReply(replyId: reply.id, postId: reply.postId);
                          } else {
                            await service.deleteOwnReply(reply.id, reply.postId);
                          }
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Yanıt silindi.')));
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
                          }
                        }
                      }
                    } else if (value == 'edit') {
                      ForumEditSheet.showReplyEdit(context, reply, service);
                    }
                  },
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            reply.content,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return '${diff.inDays}g önce';
    if (diff.inHours > 0) return '${diff.inHours}s önce';
    if (diff.inMinutes > 0) return '${diff.inMinutes}d önce';
    return 'Az önce';
  }
}
