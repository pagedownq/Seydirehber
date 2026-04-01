import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/shimmer_widget.dart';

class HorizontalCouponList extends ConsumerWidget {
  final StreamProvider<List<QueryDocumentSnapshot<Map<String, dynamic>>>> provider;
  final Function(String id, Map<String, dynamic> data) onTap;

  const HorizontalCouponList({
    super.key,
    required this.provider,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(provider);

    return dataAsync.when(
      loading: () => SizedBox(
        height: 120,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: 3,
          itemBuilder: (_, __) => const CouponCardShimmer(),
        ),
      ),
      error: (error, __) => Container(
        height: 100,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red[200]!),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Hata: $error',
              style: const TextStyle(color: Colors.red, fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
      data: (docs) {
        // Filter and Sort in Dart to avoid Index errors
        final now = DateTime.now();
        final filteredDocs = docs.where((doc) {
          final data = doc.data();
          if (data['isActive'] != true) return false;
          
          final expiry = data['expiry_date'] as Timestamp?;
          if (expiry != null && expiry.toDate().isBefore(now)) return false;
          
          final totalLimit = data['total_limit'] as int?;
          final usedCount = data['used_count'] as int? ?? 0;
          if (totalLimit != null && usedCount >= totalLimit) return false;
          
          return true;
        }).toList();

        filteredDocs.sort((a, b) {
          final aTime = a.data()['created_at'] as Timestamp?;
          final bTime = b.data()['created_at'] as Timestamp?;
          return (bTime?.seconds ?? 0).compareTo(aTime?.seconds ?? 0);
        });

        // Limit to 10 for horizontal list
        final finalDocs = filteredDocs.take(10).toList();

        if (finalDocs.isEmpty) {
          return Container(
            height: 100,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Center(
              child: Text(
                'Şu anda aktif kupon bulunmamaktadır.',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textLight),
              ),
            ),
          );
        }

        return SizedBox(
          height: 120,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: finalDocs.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final data = finalDocs[index].data();
              final id = finalDocs[index].id;
              return _buildCouponCard(context, data, id);
            },
          ),
        );
      },
    );
  }

  Widget _buildCouponCard(BuildContext context, Map<String, dynamic> data, String id) {
    final title = data['title']?.toString() ?? '';
    final discountPercentage = (data['discountPercentage'] as num?)?.toInt() ?? 0;
    final companyName = data['companyName']?.toString() ?? '';

    return RepaintBoundary(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap(id, data);
        },
        child: Container(
          width: 260,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
            gradient: LinearGradient(
              colors: [
                AppColors.primary,
                AppColors.primary.withOpacity(0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            children: [
              // Left part with discount percentage
              Container(
                width: 80,
                decoration: BoxDecoration(
                  border: Border(
                    right: BorderSide(
                      color: Colors.white.withOpacity(0.3),
                      width: 2,
                      style: BorderStyle.solid,
                    ),
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '%$discountPercentage',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'İndirim',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Right part with details
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.storefront, color: Colors.white70, size: 14),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              companyName,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
