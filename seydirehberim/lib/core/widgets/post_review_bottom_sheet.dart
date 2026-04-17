import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_colors.dart';
import '../models/review.dart';
import '../services/review_service.dart';
import '../utils/app_notification.dart';

class PostReviewBottomSheet extends ConsumerStatefulWidget {
  final String targetId;
  final String targetType;
  final Review? existingReview;

  const PostReviewBottomSheet({
    super.key,
    required this.targetId,
    required this.targetType,
    this.existingReview,
  });

  @override
  ConsumerState<PostReviewBottomSheet> createState() => _PostReviewBottomSheetState();
}

class _PostReviewBottomSheetState extends ConsumerState<PostReviewBottomSheet> {
  double _rating = 0;
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;
  bool _isOver18 = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingReview != null) {
      _rating = widget.existingReview!.rating;
      _commentController.text = widget.existingReview!.comment;
      _isOver18 = true; // Zaten yorum yapmışsa onaylamıştır
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 20,
            spreadRadius: 5,
          )
        ],
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            // Handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.existingReview != null ? 'Yorumu Düzenle' : 'Deneyimini Paylaş',
                  style: const TextStyle(
                    fontSize: 22, 
                    fontWeight: FontWeight.w900, 
                    color: Color(0xFF1E293B),
                    letterSpacing: -0.5,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    Navigator.pop(context);
                  },
                  icon: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, size: 20, color: Color(0xFF64748B)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Bu yer/firma hakkında ne düşünüyorsun?',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
            ),
            const SizedBox(height: 24),
            
            // Star Rating
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final isSelected = index < _rating;
                  return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _rating = index + 1.0;
                        });
                      },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        Icons.star_rounded,
                        size: 48,
                        color: isSelected ? const Color(0xFFFBBF24) : const Color(0xFFE2E8F0),
                      ),
                    ),
                  );
                }),
              ),
            ),
            
            const SizedBox(height: 24),
            TextField(
              controller: _commentController,
              maxLines: 4,
              style: const TextStyle(fontSize: 15),
              decoration: InputDecoration(
                hintText: 'Fikirlerin başkalarına ilham verebilir...',
                hintStyle: TextStyle(color: Colors.grey[400]),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                contentPadding: const EdgeInsets.all(20),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(color: Color(0xFFF1F5F9)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              value: _isOver18,
              onChanged: (value) {
                HapticFeedback.selectionClick();
                setState(() => _isOver18 = value ?? false);
              },
              title: const Text(
                '18 yaşından büyüğüm ve topluluk kurallarını kabul ediyorum',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
              subtitle: const Text(
                'Yorumlarımın saygılı olacağını, hakaret içermeyeceğini ve uygunsuz içeriklerin moderatörler tarafından kaldırılabileceğini onaylıyorum.',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              dense: true,
              activeColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isSubmitting || _rating == 0 || !_isOver18 ? null : () {
                  HapticFeedback.vibrate();
                  _submitReview();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shadowColor: AppColors.primary.withOpacity(0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        widget.existingReview != null ? 'Yorumu Güncelle' : 'Yorumu Gönder', 
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)
                      ),
              ),
            ),
            // Klavye açıldığında butonu yukarı itmek için boşluk
            SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 24),
          ],
        ),
      ),
    );
  }

  void _showProfanityErrorDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 40),
              ),
              const SizedBox(height: 20),
              const Text(
                'Uygunsuz İçerik!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 12),
              const Text(
                'Yorumunuz topluluk kurallarımıza aykırı veya uygunsuz kelimeler içeriyor olabilir. Lütfen mesajınızı kontrol edip tekrar deneyin.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF64748B), fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E293B),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Düzenle'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitReview() async {
    setState(() => _isSubmitting = true);
    try {
      if (widget.existingReview != null) {
        await ref.read(reviewServiceProvider).updateReview(
          reviewId: widget.existingReview!.id,
          rating: _rating,
          comment: _commentController.text,
        );
      } else {
        await ref.read(reviewServiceProvider).addReview(
          targetId: widget.targetId,
          targetType: widget.targetType,
          rating: _rating,
          comment: _commentController.text,
        );
      }
      
      if (mounted) {
        Navigator.pop(context);
        AppNotification.success(
          context, 
          widget.existingReview != null ? 'Yorumunuz güncellendi.' : 'Yorumunuz başarıyla eklendi.'
        );
      }
    } catch (e) {
      if (mounted) {
        if (e == 'PROFANITY_DETECTED') {
          _showProfanityErrorDialog(context);
        } else {
          String errorMessage = 'Hata oluştu, tekrar deneyin.';
          if (e is Exception) {
            errorMessage = e.toString().replaceAll('Exception: ', '');
          }
          AppNotification.error(context, errorMessage);
        }
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}
