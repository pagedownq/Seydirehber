import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../providers/forum_providers.dart';
import '../widgets/forum_post_card.dart';

class MyForumPostsScreen extends ConsumerWidget {
  const MyForumPostsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(myForumPostsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text('Gönderilerim', style: AppTextStyles.appBarTitle),
      ),
      body: postsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Hata: $e')),
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
                    child: Icon(Icons.post_add_rounded,
                        size: 48,
                        color: AppColors.primary.withValues(alpha: 0.5)),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Henüz gönderiniz yok',
                    style: AppTextStyles.heading3
                        .copyWith(color: AppColors.textPrimary),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              return ForumPostCard(post: posts[index]);
            },
          );
        },
      ),
    );
  }
}
