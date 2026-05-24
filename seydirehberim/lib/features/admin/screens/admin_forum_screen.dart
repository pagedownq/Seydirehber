import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../forum/models/forum_post.dart';
import '../../forum/models/forum_reply.dart';
import '../../forum/providers/forum_providers.dart';

/// Admin forum moderasyon paneli.
/// Gizlenmiş gönderileri ve yanıtları listeler, onaylama / silme işlemi yapar.
class AdminForumScreen extends ConsumerWidget {
  const AdminForumScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          title: Text('Forum Moderasyonu', style: AppTextStyles.appBarTitle),
          bottom: TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textLight,
            indicatorColor: AppColors.primary,
            tabs: const [
              Tab(text: 'Gönderiler'),
              Tab(text: 'Yanıtlar'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _HiddenPostsTab(),
            _HiddenRepliesTab(),
          ],
        ),
      ),
    );
  }
}

// ── Gizlenmiş Gönderiler Sekmesi ────────────────────────────────────────────

class _HiddenPostsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(hiddenForumPostsProvider);
    final service = ref.read(forumServiceProvider);

    return postsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Hata: $e')),
      data: (posts) {
        if (posts.isEmpty) {
          return _EmptyModeration(
            label: 'İncelenecek gönderi yok 🎉',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: posts.length,
          itemBuilder: (context, i) => _AdminPostTile(
            post: posts[i],
            onApprove: () async {
              await service.approvePost(posts[i].id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Gönderi onaylandı ve yayına alındı.')),
                );
              }
            },
            onDelete: () async {
              final confirm = await _confirm(context, 'Gönderiyi kalıcı olarak silmek istediğinizden emin misiniz? Tüm yanıtlar da silinecek.');
              if (confirm != true) return;
              await service.deletePost(posts[i].id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Gönderi kalıcı olarak silindi.')),
                );
              }
            },
          ),
        );
      },
    );
  }
}

// ── Gizlenmiş Yanıtlar Sekmesi ───────────────────────────────────────────────

class _HiddenRepliesTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repliesAsync = ref.watch(hiddenForumRepliesProvider);
    final service = ref.read(forumServiceProvider);

    return repliesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Hata: $e')),
      data: (replies) {
        if (replies.isEmpty) {
          return _EmptyModeration(label: 'İncelenecek yanıt yok 🎉');
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: replies.length,
          itemBuilder: (context, i) => _AdminReplyTile(
            reply: replies[i],
            onApprove: () async {
              await service.approveReply(replies[i].id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Yanıt onaylandı ve yayına alındı.')),
                );
              }
            },
            onDelete: () async {
              final confirm = await _confirm(context, 'Yanıtı kalıcı olarak silmek istediğinizden emin misiniz?');
              if (confirm != true) return;
              await service.deleteReply(
                  replyId: replies[i].id, postId: replies[i].postId);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Yanıt kalıcı olarak silindi.')),
                );
              }
            },
          ),
        );
      },
    );
  }
}

// ── Admin Gönderi Tile ───────────────────────────────────────────────────────

class _AdminPostTile extends StatelessWidget {
  final ForumPost post;
  final VoidCallback onApprove;
  final VoidCallback onDelete;

  const _AdminPostTile({
    required this.post,
    required this.onApprove,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Rapor sayısı badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${post.reportCount} Rapor',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Gerçek kullanıcı kimliği (admin görür)
              Expanded(
                child: Text(
                  'Kullanıcı: ${post.displayName}',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(post.title,
              style: AppTextStyles.bodyMedium
                  .copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(
            post.content,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onApprove,
                  icon: const Icon(Icons.check_circle_outline_rounded,
                      size: 16),
                  label: const Text('Onayla'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.success,
                    side: const BorderSide(color: AppColors.success),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline_rounded, size: 16),
                  label: const Text('Kalıcı Sil'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Admin Yanıt Tile ─────────────────────────────────────────────────────────

class _AdminReplyTile extends StatelessWidget {
  final ForumReply reply;
  final VoidCallback onApprove;
  final VoidCallback onDelete;

  const _AdminReplyTile({
    required this.reply,
    required this.onApprove,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.warning.withOpacity(0.3)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${reply.reportCount} Rapor',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.warning,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Kullanıcı: ${reply.displayName}',
                  style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            reply.content,
            maxLines: 5,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onApprove,
                  icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                  label: const Text('Onayla'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.success,
                    side: const BorderSide(color: AppColors.success),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline_rounded, size: 16),
                  label: const Text('Kalıcı Sil'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Boş durum ────────────────────────────────────────────────────────────────

class _EmptyModeration extends StatelessWidget {
  final String label;
  const _EmptyModeration({required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.verified_rounded, size: 56, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(label,
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textLight)),
        ],
      ),
    );
  }
}

// ── Onay dialog'u ─────────────────────────────────────────────────────────────

Future<bool?> _confirm(BuildContext context, String message) {
  return showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Emin misiniz?'),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Vazgeç'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
          child: const Text('Evet, Sil', style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
}
