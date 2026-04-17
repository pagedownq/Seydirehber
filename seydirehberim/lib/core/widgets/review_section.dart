import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_colors.dart';
import '../services/review_service.dart';
import '../widgets/review_card.dart';
import '../widgets/post_review_bottom_sheet.dart';
import '../constants/app_text_styles.dart';
import '../../features/auth/providers/auth_provider.dart';
import 'shimmer_widget.dart';
import 'empty_state_widget.dart';


class ReviewSection extends ConsumerWidget {
  final String targetId;
  final String targetType;

  const ReviewSection({
    super.key,
    required this.targetId,
    required this.targetType,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = ref.watch(reviewsProvider(targetId));
    final averageRatingAsync = ref.watch(averageRatingProvider(targetId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: const Text(
                'Değerlendirme ve Yorumlar',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                HapticFeedback.selectionClick();
                _showAddReview(context, ref);
              },
              icon: const Icon(Icons.edit_note_rounded, size: 20),
              label: const Text('Yorum Yap'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 4,
                shadowColor: AppColors.primary.withOpacity(0.4),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Average Rating Row
        reviewsAsync.when(
          data: (reviews) => _buildRatingSummary(
            reviews.isEmpty ? 0.0 : reviews.fold(0.0, (sum, r) => sum + r.rating) / reviews.length, 
            reviews
          ),
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
        
        const SizedBox(height: 12),
        
        // Review List
        reviewsAsync.when(
          data: (reviews) {
            if (reviews.isEmpty) {
              return EmptyStateWidget(
                icon: Icons.rate_review_outlined,
                title: 'Henüz Yorum Yapılmamış',
                subtitle: 'Bu yer hakkında hala kimse bir şey yazmamış. Burayı ilk sen canlandırmak ister misin?',
                actionLabel: 'İlk Yorumu Sen Yap',
                onActionPressed: () {
                  _showAddReview(context, ref);
                },
              );
            }
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: reviews.length > 5 ? 5 : reviews.length,
              itemBuilder: (context, index) {
                return ReviewCard(review: reviews[index]);
              },
            );
          },
          loading: () => const ReviewShimmer(),
          error: (err, _) {
            if (err.toString().contains('requires an index')) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Yorumlar ilk kez hazırlandığı için birkaç dakika sürebilir. Lütfen bekleyin...',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ),
              );
            }
            return Text('Hata: $err');
          },
        ),
        
        if ((reviewsAsync.asData?.value.length ?? 0) > 5)
          Center(
            child: TextButton(
              onPressed: () {
                HapticFeedback.selectionClick();
                // Show all reviews screen
              },
              child: const Text('Tüm Yorumları Gör'),
            ),
          ),
      ],
    );
  }

  Widget _buildRatingSummary(double averageRating, List<dynamic> reviews) {
    final count = reviews.length;
    
    // Calculate star counts
    Map<int, int> distribution = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    for (var review in reviews) {
      int star = review.rating.toInt();
      if (distribution.containsKey(star)) {
        distribution[star] = distribution[star]! + 1;
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primarySurface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Column(
            children: [
              Text(
                averageRating.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primaryDark,
                ),
              ),
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    Icons.star_rounded,
                    size: 16,
                    color: index < (averageRating.round()) ? Colors.amber : Colors.grey[300],
                  );
                }),
              ),
              const SizedBox(height: 4),
              Text(
                '$count değerlendirme',
                style: const TextStyle(fontSize: 10, color: AppColors.textLight),
              ),
            ],
          ),
          const SizedBox(width: 32),
          Expanded(
            child: Column(
              children: [
                _buildProgress(5, count == 0 ? 0 : distribution[5]! / count),
                _buildProgress(4, count == 0 ? 0 : distribution[4]! / count),
                _buildProgress(3, count == 0 ? 0 : distribution[3]! / count),
                _buildProgress(2, count == 0 ? 0 : distribution[2]! / count),
                _buildProgress(1, count == 0 ? 0 : distribution[1]! / count),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgress(int stars, double value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text('$stars', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: value,
                backgroundColor: Colors.grey[200],
                valueColor: const AlwaysStoppedAnimation(Colors.amber),
                minHeight: 4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddReview(BuildContext context, WidgetRef ref) async {
    final isGuest = ref.read(isGuestProvider);

    if (isGuest) {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (context) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(32),
              topRight: Radius.circular(32),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_person_rounded,
                  size: 40,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Giriş Yapmalısınız',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Yorum yazabilmek ve şehri değerlendirebilmek için lütfen Google hesabınızla giriş yapın.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Tamam',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
      return;
    }


    if (context.mounted) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => PostReviewBottomSheet(
          targetId: targetId,
          targetType: targetType,
        ),
      );
    }
  }
}
