import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/review.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/review_service.dart';
import '../services/block_service.dart';
import 'post_review_bottom_sheet.dart';

class ReviewCard extends StatefulWidget {
  final Review review;

  const ReviewCard({super.key, required this.review});

  @override
  State<ReviewCard> createState() => _ReviewCardState();
}

class _ReviewCardState extends State<ReviewCard> {
  bool _isHidden = false;

  @override
  void initState() {
    super.initState();
    _checkIfBlocked();
  }

  Future<void> _checkIfBlocked() async {
    final blocked = await BlockService.isUserBlocked(widget.review.userId);
    if (blocked && mounted) {
      setState(() => _isHidden = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isHidden) return const SizedBox.shrink();

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
                  backgroundImage: widget.review.userImageUrl != null 
                      ? NetworkImage(widget.review.userImageUrl!) 
                      : null,
                  child: widget.review.userImageUrl == null 
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
                      widget.review.userName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: Color(0xFF1E293B),
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DateFormat('dd MMMM yyyy', 'tr_TR').format(widget.review.createdAt),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildStars(widget.review.rating, size: 14),
                  PopupMenuButton<String>(
                    elevation: 10,
                    icon: const Icon(Icons.more_vert, color: Color(0xFF64748B), size: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    onSelected: (value) {
                      if (value == 'edit') _showEditSheet(context);
                      if (value == 'delete') _showDeleteDialog(context);
                      if (value == 'report') _showReportDialog(context);
                      if (value == 'block') {
                        setState(() => _isHidden = true);
                        BlockService.blockUser(
                          widget.review.userId,
                          name: widget.review.userName,
                          imageUrl: widget.review.userImageUrl,
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Kullanıcı engellendi ve içerikleri gizlendi.'),
                            backgroundColor: Colors.blueGrey,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                    itemBuilder: (context) => [
                      if (FirebaseAuth.instance.currentUser?.uid == widget.review.userId) ...[
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined, color: AppColors.primary, size: 18),
                              SizedBox(width: 8),
                              Text('Yorumu Düzenle'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                              SizedBox(width: 8),
                              Text('Yorumu Sil'),
                            ],
                          ),
                        ),
                      ],
                      if (FirebaseAuth.instance.currentUser?.uid != widget.review.userId) ...[
                        const PopupMenuItem(
                          value: 'report',
                          child: Row(
                            children: [
                              Icon(Icons.flag_outlined, color: Colors.orange, size: 18),
                              SizedBox(width: 8),
                              Text('Rapor Et'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'block',
                          child: Row(
                            children: [
                              Icon(Icons.block, color: Colors.blueGrey, size: 18),
                              SizedBox(width: 8),
                              Text('Kullanıcıyı Engelle'),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ],
          ),
          if (widget.review.comment.trim().isNotEmpty) ...[
            const SizedBox(height: 16),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: widget.review.comment,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF334155),
                      height: 1.6,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  if (widget.review.isEdited)
                    TextSpan(
                      text: ' (düzenlendi)',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
            ),
          ],
          
          // BUSINESS REPLY
          if (widget.review.reply != null) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.04),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.08),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.store_rounded, 
                          color: AppColors.primary, 
                          size: 14
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'İşletme Yanıtı',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                          color: AppColors.primary,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        DateFormat('dd.MM.yyyy').format(widget.review.reply!.createdAt),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.review.reply!.text,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF475569),
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
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
                    onPressed: () {
                      Navigator.pop(context);
                    },
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
                      await ReviewService().deleteReview(widget.review.id);
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

  void _showEditSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PostReviewBottomSheet(
        targetId: widget.review.targetId,
        targetType: widget.review.targetType,
        existingReview: widget.review,
      ),
    );
  }

  void _showReportDialog(BuildContext context) {
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
                color: Colors.orange.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.report_problem_rounded, color: Colors.orange, size: 30),
            ),
            const SizedBox(height: 20),
            const Text(
              'Yorumu Raporla',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 10),
            const Text(
              'Bu yorumun topluluk kurallarımızı ihlal ettiğini veya uygunsuz olduğunu mu düşünüyorsunuz? Ekibimiz inceleyecektir.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF64748B), fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('Vazgeç', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      try {
                        await ReviewService().reportReview(widget.review);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Bildiriminiz alındı, teşekkür ederiz.'),
                              backgroundColor: Colors.orange,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(e == 'ALREADY_REPORTED' 
                                ? 'Bu yorumu zaten raporladınız.' 
                                : 'Hata oluştu, tekrar deneyin.'),
                              backgroundColor: e == 'ALREADY_REPORTED' ? Colors.blueGrey : Colors.red,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      } finally {
                        if (context.mounted) Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Raporla', style: TextStyle(fontWeight: FontWeight.bold)),
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
