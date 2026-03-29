import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_colors.dart';
import '../services/review_service.dart';

class PostReviewBottomSheet extends ConsumerStatefulWidget {
  final String targetId;
  final String targetType;

  const PostReviewBottomSheet({
    super.key,
    required this.targetId,
    required this.targetType,
  });

  @override
  ConsumerState<PostReviewBottomSheet> createState() => _PostReviewBottomSheetState();
}

class _PostReviewBottomSheetState extends ConsumerState<PostReviewBottomSheet> {
  double _rating = 0;
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
        top: 12,
        left: 24,
        right: 24,
      ),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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
              const Text(
                'Deneyimini Paylaş',
                style: TextStyle(
                  fontSize: 22, 
                  fontWeight: FontWeight.w900, 
                  color: Color(0xFF1E293B),
                  letterSpacing: -0.5,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
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
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isSubmitting || _rating == 0 ? null : _submitReview,
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
                  : const Text(
                      'Yorumu Gönder', 
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitReview() async {
    setState(() => _isSubmitting = true);
    try {
      await ref.read(reviewServiceProvider).addReview(
        targetId: widget.targetId,
        targetType: widget.targetType,
        rating: _rating,
        comment: _commentController.text,
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Yorumunuz başarıyla eklendi.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}
