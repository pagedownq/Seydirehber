import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../services/haptic_service.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

/// Kullanıcıya Google Form anketini gösteren premium dialog.
/// 
/// - "Başla" → Form linki açılır, bir daha gösterilmez.
/// - "Sonra Hatırlat" → Kapatılır, bir sonraki açılışta tekrar gösterilir.
class SurveyDialog extends StatelessWidget {
  /// SharedPreferences anahtarı – anket tamamlandıysa true olur.
  /// Not: Anket ID'si ile birlikte tutulur (survey_completed_ID)
  static const String _prefKeyPrefix = 'survey_completed_';

  final String surveyId;
  final String surveyUrl;
  final String title;
  final String? description;

  const SurveyDialog({
    super.key,
    required this.surveyId,
    required this.surveyUrl,
    required this.title,
    this.description,
  });

  // ─── Yardımcı Statik Metotlar ───────────────────────────────────

  /// Anketi daha önce tamamlayıp tamamlamadığını kontrol eder.
  static Future<bool> isSurveyCompleted(String id) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_prefKeyPrefix$id') ?? false;
  }

  /// Anketi "tamamlandı" olarak işaretler.
  static Future<void> markSurveyCompleted(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_prefKeyPrefix$id', true);
  }

  /// MainShell'den çağrılır. Anket henüz yapılmadıysa dialog'u gösterir.
  static Future<void> showIfNeeded(BuildContext context) async {
    try {
      // 1. Firestore'dan aktif anketi çek
      final snapshot = await FirebaseFirestore.instance
          .collection('surveys')
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return;

      final doc = snapshot.docs.first;
      final data = doc.data();
      final id = doc.id;
      final url = data['url'] as String?;
      final title = data['title'] as String? ?? 'Görüşün Bizim İçin\nÇok Değerli! 💚';
      final description = data['description'] as String?;

      if (url == null || url.isEmpty) return;

      // 2. Bu anket ID'si tamamlanmış mı kontrol et
      final completed = await isSurveyCompleted(id);
      if (completed) return;

      if (!context.mounted) return;

      // Ekran yüklendikten kısa bir süre sonra göster
      await Future.delayed(const Duration(milliseconds: 800));
      if (!context.mounted) return;

      showGeneralDialog(
        context: context,
        barrierDismissible: true,
        barrierLabel: 'Survey',
        barrierColor: Colors.black.withOpacity(0.5),
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (context, anim1, anim2) => SurveyDialog(
          surveyId: id,
          surveyUrl: url,
          title: title,
          description: description,
        ),
        transitionBuilder: (context, anim1, anim2, child) {
          final curvedAnim = CurvedAnimation(
            parent: anim1,
            curve: Curves.easeOutBack,
          );
          return ScaleTransition(
            scale: curvedAnim,
            child: FadeTransition(
              opacity: anim1,
              child: child,
            ),
          );
        },
      );
    } catch (e) {
      debugPrint('SurveyDialog error: $e');
    }
  }

  // ─── UI ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Center(
      child: Container(
        width: size.width * 0.88,
        constraints: const BoxConstraints(maxWidth: 400),
        child: Material(
          color: Colors.transparent,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.15),
                      blurRadius: 30,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Üst Gradient Header ──
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 28),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF43A047),
                            Color(0xFF66BB6A),
                            Color(0xFF81C784),
                          ],
                        ),
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(28),
                        ),
                      ),
                      child: Column(
                        children: [
                          // Anket ikonu – animasyonlu container
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.assignment_outlined,
                              size: 38,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            title,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.heading2.copyWith(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── İçerik ──
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                      child: Column(
                        children: [
                          // Bilgilendirme Kartı
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.primarySurface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.primary.withOpacity(0.15),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.emoji_events_rounded,
                                    color: AppColors.primary,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    description != null && description!.isNotEmpty
                                        ? description!
                                        : 'Kısa anketimizi tamamlayarak Seydi Rehber\'i daha iyi hale getirmemize yardımcı olabilirsiniz.',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.textPrimary,
                                      height: 1.4,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Bilgi İkonları
                          Row(
                            children: [
                              _buildInfoChip(Icons.timer_outlined, '~2 dakika'),
                              const SizedBox(width: 8),
                              _buildInfoChip(Icons.lock_outline, 'Anonim'),
                              const SizedBox(width: 8),
                              _buildInfoChip(Icons.favorite_border, 'Gönüllü'),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // ── "Ankete Başla" Butonu ──
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: ElevatedButton(
                              onPressed: () => _onStartSurvey(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.open_in_new_rounded, size: 20),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Ankete Başla',
                                    style: AppTextStyles.button.copyWith(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 8),

                          // ── "Sonra Hatırlat" Butonu ──
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: TextButton(
                              onPressed: () => _onSkip(context),
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.textLight,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Text(
                                'Sonra Hatırlat',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.textLight,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Buton Aksiyonları ─────────────────────────────────────────

  Future<void> _onStartSurvey(BuildContext context) async {
    HapticService.medium();

    // URL şemasını kontrol et ve gerekirse https:// ekle
    String link = surveyUrl;
    if (!link.startsWith('http')) {
      link = 'https://$link';
    }

    final url = Uri.parse(link);
    try {
      final launched = await launchUrl(url, mode: LaunchMode.externalApplication);
      if (launched) {
        // Sadece başarılı şekilde açıldıysa tamamlandı olarak işaretle → bir daha gösterilmeyecek
        await markSurveyCompleted(surveyId);
      } else {
        throw Exception('Could not launch URL');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Anket bağlantısı açılamadı.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }

    // Dialog'u kapat
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  void _onSkip(BuildContext context) {
    HapticService.selection();
    // Sadece kapat – SharedPreferences'a kaydetmiyoruz
    // Bir sonraki açılışta tekrar gösterilecek
    Navigator.of(context, rootNavigator: true).pop();
  }

  // ── Yardımcı Widgetlar ────────────────────────────────────────

  Widget _buildInfoChip(IconData icon, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border.withOpacity(0.5)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: AppColors.primary),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                  color: AppColors.textSecondary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
