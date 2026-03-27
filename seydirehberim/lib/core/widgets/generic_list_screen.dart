import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/widgets/cached_image_widget.dart';
import '../../core/widgets/shimmer_widget.dart';

class GenericListScreen extends ConsumerWidget {
  final String title;
  final StreamProvider<QuerySnapshot<Map<String, dynamic>>> provider;
  final String routePrefix;
  final bool showViewCount;

  const GenericListScreen({
    super.key,
    required this.title,
    required this.provider,
    required this.routePrefix,
    this.showViewCount = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(provider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(title, style: AppTextStyles.appBarTitle),
        backgroundColor: AppColors.white,
      ),
      body: dataAsync.when(
        loading: () => ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: 5,
          itemBuilder: (_, __) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ShimmerWidget.rectangular(height: 90),
          ),
        ),
        error: (_, __) => const Center(child: Text('Veriler yüklenemedi')),
        data: (snapshot) {
          final docs = snapshot.docs;
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.inbox_outlined, size: 48, color: AppColors.textLight),
                  const SizedBox(height: 12),
                  Text('Henüz veri bulunmuyor', style: AppTextStyles.bodyMedium),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final data = docs[index].data();
              final id = docs[index].id;
              final name = data['ad'] as String? ?? data['name'] as String? ?? '';
              final imageUrl = data['image_url'] as String? ?? data['gorsel'] as String? ?? '';
              final viewCount = data['goruntulenme'] as int? ?? 0;

              return Material(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(16),
                elevation: 1,
                shadowColor: Colors.black12,
                child: InkWell(
                  onTap: () => context.push('/$routePrefix/$id'),
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        if (imageUrl.isNotEmpty)
                          CachedImageWidget(
                            imageUrl: imageUrl,
                            width: 70,
                            height: 70,
                            borderRadius: 12,
                          )
                        else
                          Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              color: AppColors.primarySurface,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.image, color: AppColors.textLight),
                          ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (showViewCount) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.visibility_outlined,
                                        size: 14, color: AppColors.textLight),
                                    const SizedBox(width: 4),
                                    Text('$viewCount', style: AppTextStyles.caption),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios,
                            size: 14, color: AppColors.textLight),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
