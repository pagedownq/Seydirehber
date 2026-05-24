import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

/// Topluluk kuralları onay ekranı.
/// 18+ yaş doğrulaması değil — store politikasına uygun "kural onayı".
/// Sadece bir kez gösterilir, kabul SharedPreferences'a kaydedilir.
class ForumRulesSheet extends StatefulWidget {
  final VoidCallback onAccepted;

  const ForumRulesSheet({super.key, required this.onAccepted});

  static const String _prefsKey = 'forum_rules_accepted';

  /// Kurallar kabul edilmişse direkt callback'i çağır,
  /// değilse bottom sheet göster.
  static Future<void> showIfNeeded(
    BuildContext context, {
    required VoidCallback onAccepted,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final accepted = prefs.getBool(_prefsKey) ?? false;
    if (accepted) {
      onAccepted();
      return;
    }
    if (!context.mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ForumRulesSheet(onAccepted: onAccepted),
    );
  }

  @override
  State<ForumRulesSheet> createState() => _ForumRulesSheetState();
}

class _ForumRulesSheetState extends State<ForumRulesSheet> {
  bool _accepted = false;

  Future<void> _accept() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(ForumRulesSheet._prefsKey, true);
    if (!mounted) return;
    Navigator.of(context).pop();
    widget.onAccepted();
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

          // Başlık
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.forum_rounded,
                    color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'Seydi Rehber Forumu',
                  style: AppTextStyles.heading3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          Text(
            'Foruma hoş geldiniz! Devam etmeden önce lütfen topluluk kurallarımızı okuyun.',
            style:
                AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),

          // Kurallar listesi
          ..._rules.map((rule) => _RuleItem(
                icon: rule.$1,
                text: rule.$2,
              )),

          const SizedBox(height: 20),

          // Onay checkbox
          Material(
            color: _accepted ? AppColors.primarySurface : Colors.grey[50],
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => setState(() => _accepted = !_accepted),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    Checkbox(
                      value: _accepted,
                      onChanged: (v) =>
                          setState(() => _accepted = v ?? false),
                      activeColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Topluluk kurallarını okudum ve kabul ediyorum.',
                        style: AppTextStyles.bodyMedium
                            .copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Devam butonu
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _accepted ? _accept : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: Colors.grey[200],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                'Foruma Giriş Yap',
                style: AppTextStyles.button,
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  static const List<(IconData, String)> _rules = [
    (
      Icons.block_rounded,
      'Küfür, hakaret ve argo içerikler kesinlikle yasaktır.',
    ),
    (
      Icons.person_off_rounded,
      'Başkalarının kişisel bilgilerini (isim, telefon vb.) paylaşmayın.',
    ),
    (
      Icons.campaign_rounded,
      'Reklam ve spam içerikler paylaşmayın.',
    ),
    (
      Icons.fact_check_rounded,
      'Yanlış veya yanıltıcı bilgi yaymayın.',
    ),
    (
      Icons.gavel_rounded,
      'İhlaller; içerik gizleme veya hesap kısıtlamasıyla sonuçlanabilir.',
    ),
  ];
}

class _RuleItem extends StatelessWidget {
  final IconData icon;
  final String text;
  const _RuleItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textSecondary, height: 1.4)),
          ),
        ],
      ),
    );
  }
}
