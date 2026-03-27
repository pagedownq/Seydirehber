import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/cached_image_widget.dart';
import '../../../core/widgets/map_button.dart';
import '../../../core/widgets/shimmer_widget.dart';
import '../../home/providers/home_providers.dart';

class NoterlerScreen extends ConsumerWidget {
  const NoterlerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(noterlerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Noterler', style: AppTextStyles.appBarTitle),
        backgroundColor: AppColors.white,
      ),
      body: dataAsync.when(
        loading: () => ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: 3,
          itemBuilder: (_, __) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ShimmerWidget.rectangular(height: 120),
          ),
        ),
        error: (_, __) => const Center(child: Text('Veriler yüklenemedi')),
        data: (snapshot) {
          final docs = snapshot.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('Henüz noter eklenmemiş'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final data = docs[index].data();
              return _NoterCard(data: data);
            },
          );
        },
      ),
    );
  }
}

class _NoterCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const _NoterCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final name = data['ad'] as String? ?? '';
    final imageUrl = data['image_url'] as String? ?? data['gorsel'] as String? ?? '';
    final gunler = data['gunler'] as String? ?? '';
    final telefon = data['telefon'] as String? ?? '';
    final konum = data['konum'] as String?;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imageUrl.isNotEmpty)
            CachedImageWidget(
              imageUrl: imageUrl,
              width: double.infinity,
              height: 150,
              borderRadius: 16,
            ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppTextStyles.heading3),
                if (gunler.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.schedule, size: 16, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Expanded(child: Text(gunler, style: AppTextStyles.bodySmall)),
                    ],
                  ),
                ],
                if (telefon.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.phone, size: 16, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text(telefon, style: AppTextStyles.bodySmall),
                    ],
                  ),
                ],
                if (konum != null && konum.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  MapButton(locationUrl: konum),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
