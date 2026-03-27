import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/shimmer_widget.dart';
import '../../home/providers/home_providers.dart';

class OtobusScreen extends ConsumerWidget {
  const OtobusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(otobusSaatleriProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Otobüs Saatleri', style: AppTextStyles.appBarTitle),
        backgroundColor: AppColors.white,
      ),
      body: dataAsync.when(
        loading: () => ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: 3,
          itemBuilder: (_, __) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ShimmerWidget.rectangular(height: 100),
          ),
        ),
        error: (_, __) => const Center(child: Text('Veriler yüklenemedi')),
        data: (snapshot) {
          final docs = snapshot.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('Henüz otobüs saati eklenmemiş'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final data = docs[index].data();
              final guzergah = data['guzergah'] as String? ?? '';
              final saatler = data['saatler'] as String? ?? '';
              final duraklar = data['duraklar'] as String?;

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
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primarySurface,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.directions_bus,
                                color: AppColors.primary, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              guzergah,
                              style: AppTextStyles.heading3,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.access_time,
                              size: 16, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              saatler,
                              style: AppTextStyles.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                      if (duraklar != null && duraklar.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        const Divider(),
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.pin_drop_outlined,
                                size: 16, color: AppColors.textLight),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                duraklar,
                                style: AppTextStyles.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
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
