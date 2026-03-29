import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/review.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/review_service.dart';

class ReviewCard extends StatelessWidget {
  final Review review;

  const ReviewCard({super.key, required this.review});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.1),
                    width: 2,
                  ),
                ),
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primarySurface,
                  backgroundImage: review.userImageUrl != null 
                      ? NetworkImage(review.userImageUrl!) 
                      : null,
                  child: review.userImageUrl == null 
                      ? const Icon(Icons.person, color: AppColors.primary, size: 20) 
                      : null,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.userName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: Color(0xFF1E293B),
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DateFormat('dd MMMM yyyy', 'tr_TR').format(review.createdAt),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildStars(review.rating, size: 14),
                  if (FirebaseAuth.instance.currentUser?.uid == review.userId)
                    GestureDetector(
                      onTap: () => _showDeleteDialog(context),
                      child: Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.05),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 16),
                      ),
                    ),
                ],
              ),
            ],
          ),
          if (review.comment.trim().isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              review.comment,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF334155),
                height: 1.6,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStars(double rating, {double size = 18}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          Icons.star_rounded, 
          color: index < rating ? const Color(0xFFFBBF24) : const Color(0xFFE2E8F0), 
          size: size
        );
      }),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(32),
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
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.delete_sweep_rounded, color: Colors.red, size: 30),
            ),
            const SizedBox(height: 20),
            const Text(
              'Yorumu Siliyorsunuz',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 10),
            const Text(
              'Bu işlemin geri dönüşü yoktur. Yorumunuzu silmek istediğinize emin misiniz?',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF64748B), fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Vazgeç', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      await ReviewService().deleteReview(review.id);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Evet, Sil', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
