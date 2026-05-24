import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/services/haptic_service.dart';
import '../models/forum_post.dart';
import '../providers/forum_providers.dart';
import '../widgets/forum_post_card.dart';
import '../../auth/providers/auth_provider.dart';
import 'forum_create_screen.dart';
import 'my_forum_posts_screen.dart';

class ForumScreen extends ConsumerWidget {
  const ForumScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(forumPostsProvider);
    final selectedCategory = ref.watch(forumCategoryProvider);
    final isGuest = ref.watch(isGuestProvider);
    final isAdmin = ref.watch(isAdminProvider).value ?? false;
    final myPostsAsync = ref.watch(myForumPostsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.forum_rounded,
                  color: AppColors.primary, size: 18),
            ),
            const SizedBox(width: 10),
            Text('Forum', style: AppTextStyles.appBarTitle),
          ],
        ),
        actions: [
          if (!isGuest)
            myPostsAsync.whenOrNull(
              data: (myPosts) {
                if (myPosts.isEmpty) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: TextButton.icon(
                    onPressed: () {
                      HapticService.selection();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const MyForumPostsScreen(),
                        ),
                      );
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: AppColors.primarySurface,
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.person_rounded, size: 16),
                    label: Text(
                      '${myPosts.length} Gönderi',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                  ),
                );
              },
            ) ?? const SizedBox(),
        ],
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
          borderRadius: BorderRadius.circular(30),
        ),
        child: FloatingActionButton.extended(
          onPressed: () {
            HapticService.selection();
            if (isGuest) {
              _showLoginDialog(context);
              return;
            }
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ForumCreateScreen()),
            );
          },
          backgroundColor: AppColors.primary,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          icon: const Icon(Icons.add_comment_rounded, color: Colors.white, size: 22),
          label: Text(
            'Yeni Gönderi',
            style: AppTextStyles.button.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ),
      body: Column(
        children: [
          // Arama Çubuğu
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                onChanged: (value) {
                  ref.read(forumSearchQueryProvider.notifier).state = value;
                },
                style: AppTextStyles.bodyMedium,
                decoration: InputDecoration(
                  hintText: 'Forumda ara...',
                  hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textLight),
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textLight),
                  suffixIcon: ref.watch(forumSearchQueryProvider).isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, color: AppColors.textLight, size: 20),
                          onPressed: () {
                            HapticService.selection();
                            ref.read(forumSearchQueryProvider.notifier).state = '';
                            FocusScope.of(context).unfocus();
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
          ),

          // Kategori filtre chipları
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: ForumCategory.values.map((cat) {
                final isSelected = selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text('${cat.emoji} ${cat.label}'),
                    selected: isSelected,
                    onSelected: (_) {
                      HapticService.selection();
                      ref.read(forumCategoryProvider.notifier).state = cat;
                    },
                    selectedColor: AppColors.primarySurface,
                    checkmarkColor: AppColors.primary,
                    labelStyle: AppTextStyles.bodySmall.copyWith(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textSecondary,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w400,
                    ),
                    side: BorderSide(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.border,
                    ),
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  ),
                );
              }).toList(),
            ),
          ),

          // Liste
          Expanded(
            child: postsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        color: AppColors.error, size: 40),
                    const SizedBox(height: 12),
                    Text('Bir hata oluştu', style: AppTextStyles.bodyMedium),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => ref.invalidate(forumPostsProvider),
                      child: const Text('Yeniden Dene'),
                    ),
                  ],
                ),
              ),
              data: (posts) {
                if (posts.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: AppColors.primarySurface,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.forum_rounded, size: 48, color: AppColors.primary.withValues(alpha: 0.5)),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Henüz gönderi yok',
                          style: AppTextStyles.heading3
                              .copyWith(color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Sessizliği ilk bozan sen ol!',
                          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textLight),
                        ),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async =>
                      ref.invalidate(forumPostsProvider),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: posts.length,
                    itemBuilder: (context, i) => ForumPostCard(
                      post: posts[i],
                      isAdmin: isAdmin,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showLoginDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Giriş Gerekli', style: AppTextStyles.heading3),
        content: Text(
          'Gönderi paylaşmak için giriş yapmanız gerekiyor.',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }
}
