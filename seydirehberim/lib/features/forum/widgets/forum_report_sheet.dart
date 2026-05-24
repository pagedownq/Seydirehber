import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

enum ReportReason {
  harassment('Hakaret / Argo / Küfür', Icons.sentiment_very_dissatisfied_rounded),
  misinformation('Yanlış / Yanıltıcı Bilgi', Icons.info_outline_rounded),
  spam('Reklam / Spam', Icons.campaign_rounded),
  privacy('Kişisel Verilerin İfşası', Icons.person_off_rounded);

  final String label;
  final IconData icon;
  const ReportReason(this.label, this.icon);
}

/// İçerik bildirme bottom sheet.
/// Kullanıcının bir neden seçmesini zorunlu kılar.
class ForumReportSheet extends StatefulWidget {
  final Future<bool> Function(ReportReason reason) onReport;
  final String contentType; // "gönderi" veya "yanıt"

  const ForumReportSheet({
    super.key,
    required this.onReport,
    this.contentType = 'gönderi',
  });

  /// Bottom sheet göster, seçim yapılırsa callback çağır.
  static Future<void> show(
    BuildContext context, {
    required Future<bool> Function(ReportReason reason) onReport,
    String contentType = 'gönderi',
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ForumReportSheet(
        onReport: onReport,
        contentType: contentType,
      ),
    );
  }

  @override
  State<ForumReportSheet> createState() => _ForumReportSheetState();
}

class _ForumReportSheetState extends State<ForumReportSheet> {
  ReportReason? _selected;
  bool _loading = false;

  Future<void> _submit() async {
    if (_selected == null) return;
    setState(() => _loading = true);
    try {
      final success = await widget.onReport(_selected!);
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? '${widget.contentType.capitalize()} bildirildi. Teşekkürler!'
                : 'Bu içeriği zaten bildirdiniz.',
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          Text(
            '${widget.contentType.capitalize()} Bildir',
            style: AppTextStyles.heading3,
          ),
          const SizedBox(height: 6),
          Text(
            'Neden bildirmek istiyorsunuz?',
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: 16),

          // Neden seçenekleri
          ...ReportReason.values.map((reason) => _ReasonTile(
                reason: reason,
                isSelected: _selected == reason,
                onTap: () => setState(() => _selected = reason),
              )),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: (_selected != null && !_loading) ? _submit : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                disabledBackgroundColor: Colors.grey[200],
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text('Bildir', style: AppTextStyles.button),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _ReasonTile extends StatelessWidget {
  final ReportReason reason;
  final bool isSelected;
  final VoidCallback onTap;

  const _ReasonTile({
    required this.reason,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: isSelected ? const Color(0xFFFFF3F3) : Colors.grey[50],
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? AppColors.error : AppColors.border,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  reason.icon,
                  color: isSelected ? AppColors.error : AppColors.textLight,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    reason.label,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: isSelected
                          ? AppColors.error
                          : AppColors.textPrimary,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ),
                if (isSelected)
                  const Icon(Icons.check_circle_rounded,
                      color: AppColors.error, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

extension _StringExtension on String {
  String capitalize() =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}
