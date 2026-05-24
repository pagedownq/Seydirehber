import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/services/haptic_service.dart';
import '../models/forum_post.dart';
import '../providers/forum_providers.dart';
import '../widgets/forum_reply_card.dart';
import '../widgets/forum_report_sheet.dart';
import '../widgets/forum_edit_sheet.dart';
import '../../../core/services/notification_service.dart';
import '../../auth/providers/auth_provider.dart';

class ForumDetailScreen extends ConsumerStatefulWidget {
  final String postId;
  const ForumDetailScreen({super.key, required this.postId});

  @override
  ConsumerState<ForumDetailScreen> createState() =>
      _ForumDetailScreenState();
}

class _ForumDetailScreenState extends ConsumerState<ForumDetailScreen> {
  final TextEditingController _replyController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isAnonymousReply = false;
  bool _submitting = false;

  bool _hasVotedHelpful = false;
  bool _showStickyFeedback = false;
  Timer? _feedbackTimer;

  @override
  void initState() {
    super.initState();
    _feedbackTimer = Timer(const Duration(seconds: 10), () {
      if (mounted && !_hasVotedHelpful) {
        setState(() => _showStickyFeedback = true);
      }
    });

    _scrollController.addListener(() {
      if (_scrollController.hasClients) {
        final maxScroll = _scrollController.position.maxScrollExtent;
        final currentScroll = _scrollController.position.pixels;
        // Alt kısımdaki butonlara yaklaşınca (veya görününce) sticky bar'ı gizle
        if (maxScroll - currentScroll < 300 && _showStickyFeedback) {
          setState(() => _showStickyFeedback = false);
        }
      }
    });
  }

  @override
  void dispose() {
    _feedbackTimer?.cancel();
    _scrollController.dispose();
    _replyController.dispose();
    super.dispose();
  }

  void _handleFeedbackVote(bool isHelpful) {
    setState(() {
      _hasVotedHelpful = true;
      _showStickyFeedback = false;
    });
    
    final user = ref.read(authStateProvider).value;
    if (user != null) {
      ref.read(forumServiceProvider).votePost(
        postId: widget.postId,
        userId: user.uid,
        isHelpful: isHelpful,
      );
    }
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Geri bildiriminiz için teşekkürler!')),
      );
    }
  }

  Widget _buildFeedbackWidget(bool alreadyVoted) {
    if (_hasVotedHelpful || alreadyVoted) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        alignment: Alignment.center,
        child: Text(
          'Geri bildiriminiz için teşekkürler! 🎉',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primary),
        ),
      );
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        color: AppColors.primarySurface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            'Bu gönderi sizin için yararlı oldu mu?',
            style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: () => _handleFeedbackVote(true),
                icon: const Icon(Icons.thumb_up_outlined, size: 18),
                label: const Text('Evet'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                ),
              ),
              const SizedBox(width: 16),
              OutlinedButton.icon(
                onPressed: () => _handleFeedbackVote(false),
                icon: const Icon(Icons.thumb_down_outlined, size: 18),
                label: const Text('Hayır'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Future<void> _submitReply(ForumPost post) async {
    final content = _replyController.text.trim();
    if (content.isEmpty) return;

    final user = ref.read(authStateProvider).value;
    final isGuest = ref.read(isGuestProvider);

    if (user == null || isGuest) {
      _showLoginSnack();
      return;
    }

    setState(() => _submitting = true);
    try {
      await ref.read(forumServiceProvider).createReply(
            postId: widget.postId,
            userId: user.uid,
            displayName: user.displayName ?? 'Kullanıcı',
            photoUrl: user.photoURL,
            isAnonymous: _isAnonymousReply,
            content: content,
          );
      if (!mounted) return;
      _replyController.clear();
      setState(() => _isAnonymousReply = false);
      FocusScope.of(context).unfocus();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Yanıt gönderilemedi: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }

  }

  void _showLoginSnack() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Yanıt yazabilmek için giriş yapmanız gerekiyor.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final postAsync = ref.watch(forumPostProvider(widget.postId));
    final repliesAsync = ref.watch(forumRepliesProvider(widget.postId));
    final isGuest = ref.watch(isGuestProvider);
    final userId = ref.watch(authStateProvider).value?.uid;
    final isAdmin = ref.watch(isAdminProvider).value ?? false;
    final service = ref.read(forumServiceProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text('Gönderi', style: AppTextStyles.appBarTitle),
        actions: [
          // Admin: rapor sayısı göster
          if (isAdmin)
            postAsync.whenOrNull(
              data: (post) => post != null
                  ? Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Chip(
                        label: Text(
                          '${post.reportCount} rapor',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 11),
                        ),
                        backgroundColor: post.reportCount > 0
                            ? AppColors.error
                            : Colors.grey,
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      ),
                    )
                  : const SizedBox(),
            ) ??
            const SizedBox(),
        ],
      ),
      body: postAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Gönderi yüklenemedi: $e')),
        data: (post) {
          if (post == null) {
            return Center(
              child: Text('Gönderi bulunamadı.',
                  style: AppTextStyles.bodyMedium),
            );
          }

          // Gizlenmiş içerik uyarısı (admin değilse)
          if (post.isHidden && !isAdmin) {
            return _HiddenContentWidget();
          }

          return Stack(
            children: [
              Column(
                children: [
                  Expanded(
                    child: ListView(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      children: [
                        // Gönderi detay kartı
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Yazar satırı
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
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
                                        size: 20,
                                      ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isAdmin && post.isAnonymous
                                          ? '${post.publicDisplayName} (${post.displayName})'
                                          : post.publicDisplayName,
                                      style: AppTextStyles.bodySmall
                                          .copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      _timeAgo(post.createdAt) + (post.isEdited ? ' (Düzenlendi)' : ''),
                                      style: AppTextStyles.caption,
                                    ),
                                  ],
                                ),
                              ),
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
                                          Navigator.of(context).pop(); // Go back to forum screen
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
                                            Navigator.of(context).pop(); // Go back to forum screen
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
                          const SizedBox(height: 14),

                          Text(
                            post.title,
                            style: AppTextStyles.heading3,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            post.content,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                              height: 1.6,
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Kategori + yanıt sayısı
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.primarySurface,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  post.category,
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Icon(Icons.chat_bubble_outline_rounded,
                                  size: 13, color: AppColors.textLight),
                              const SizedBox(width: 4),
                              Text(
                                '${post.replyCount} yanıt',
                                style: AppTextStyles.caption,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    _buildFeedbackWidget(
                      userId != null && (post.helpfulVoterIds.contains(userId) || post.unhelpfulVoterIds.contains(userId))
                    ),

                    const SizedBox(height: 20),

                    // Yanıtlar başlığı
                    if (post.replyCount > 0)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text('Yanıtlar',
                            style: AppTextStyles.heading3
                                .copyWith(fontSize: 16)),
                      ),

                    // Yanıtlar listesi
                    repliesAsync.when(
                      loading: () => const Center(
                          child: Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(),
                      )),
                      error: (e, _) =>
                          Text('Yanıtlar yüklenemedi: $e'),
                      data: (replies) {
                        if (replies.isEmpty) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: Text('Henüz yanıt yok.'),
                            ),
                          );
                        }

                        if (isGuest) {
                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              ImageFiltered(
                                imageFilter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                                child: Column(
                                  children: replies
                                      .map((r) => ForumReplyCard(
                                            reply: r,
                                            isAdmin: isAdmin,
                                          ))
                                      .toList(),
                                ),
                              ),
                              // Giriş Yap Overlay
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                child: Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.95),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 15,
                                        offset: const Offset(0, 5),
                                      )
                                    ]
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.lock_outline_rounded, size: 48, color: AppColors.primary),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Yanıtları görebilmek için giriş yapmalısınız',
                                        textAlign: TextAlign.center,
                                        style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold, fontSize: 15),
                                      ),
                                      const SizedBox(height: 20),
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton(
                                          onPressed: () {
                                            HapticService.selection();
                                            NotificationService().navigateTo?.call('/settings');
                                            context.go('/');
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.primary,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(vertical: 14),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                            elevation: 0,
                                          ),
                                          child: const Text('Giriş Yap', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          );
                        }

                        return Column(
                          children: replies
                              .map((r) => ForumReplyCard(
                                    reply: r,
                                    isAdmin: isAdmin,
                                  ))
                              .toList(),
                        );
                      },
                    ),

                    const SizedBox(height: 80),
                  ],
                ),
              ),

              // Alt: Yanıt yazma alanı
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 12,
                  bottom: MediaQuery.of(context).padding.bottom > 0
                      ? MediaQuery.of(context).padding.bottom + 8
                      : 12,
                ),
                child: isGuest
                    ? _GuestReplyBanner()
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Anonim toggle
                          Row(
                            children: [
                              Transform.scale(
                                scale: 0.8,
                                child: Switch(
                                  value: _isAnonymousReply,
                                  onChanged: (v) =>
                                      setState(() => _isAnonymousReply = v),
                                  activeColor: AppColors.primary,
                                ),
                              ),
                              Text(
                                'Anonim yanıtla',
                                style: AppTextStyles.caption.copyWith(
                                  color: _isAnonymousReply
                                      ? AppColors.primary
                                      : AppColors.textLight,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _replyController,
                                  maxLines: 3,
                                  minLines: 1,
                                  maxLength: 1000,
                                  decoration: InputDecoration(
                                    hintText: 'Yanıtınızı yazın...',
                                    hintStyle: AppTextStyles.bodySmall,
                                    filled: true,
                                    fillColor: AppColors.background,
                                    border: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.circular(14),
                                      borderSide: const BorderSide(
                                          color: AppColors.border),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.circular(14),
                                      borderSide: const BorderSide(
                                          color: AppColors.border),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.circular(14),
                                      borderSide: const BorderSide(
                                          color: AppColors.primary,
                                          width: 1.5),
                                    ),
                                    contentPadding: const EdgeInsets.all(12),
                                    counterText: '',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              _submitting
                                  ? const CircularProgressIndicator()
                                  : IconButton.filled(
                                      onPressed: () {
                                        HapticService.selection();
                                        _submitReply(post);
                                      },
                                      style: IconButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(14),
                                        ),
                                      ),
                                      icon: const Icon(Icons.send_rounded,
                                          color: Colors.white),
                                    ),
                            ],
                          ),
                        ],
                      ),
              ),
            ],
          ),

          // Sticky Bar
          if (_showStickyFeedback && !_hasVotedHelpful && (userId == null || (!post.helpfulVoterIds.contains(userId) && !post.unhelpfulVoterIds.contains(userId))))
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom > 0
                  ? MediaQuery.of(context).padding.bottom + 90
                  : 100, // Yanıt yazma alanının hemen üstü
                  left: 16,
                  right: 16,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 300),
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(0, 20 * (1 - value)),
                          child: child,
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Bu gönderi yararlı oldu mu?',
                              style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),
                          IconButton(
                            onPressed: () => _handleFeedbackVote(true),
                            icon: const Icon(Icons.thumb_up_alt_outlined, color: AppColors.primary, size: 20),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          const SizedBox(width: 16),
                          IconButton(
                            onPressed: () => _handleFeedbackVote(false),
                            icon: const Icon(Icons.thumb_down_alt_outlined, color: AppColors.textLight, size: 20),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () => setState(() => _showStickyFeedback = false),
                            icon: const Icon(Icons.close, color: AppColors.textLight, size: 16),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
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

/// Gizlenmiş içerik uyarısı
class _HiddenContentWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.warning_amber_rounded,
                  color: Color(0xFFFF8F00), size: 40),
            ),
            const SizedBox(height: 20),
            Text(
              'İnceleme Altında',
              style: AppTextStyles.heading3,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Bu içerik topluluk kuralları ihlali şikayetleri nedeniyle geçici olarak incelemeye alınmıştır.',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Misafir için yanıt yazma engeli
class _GuestReplyBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_outline_rounded,
              color: AppColors.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Yanıt yazabilmek için giriş yapmanız gerekiyor.',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}
