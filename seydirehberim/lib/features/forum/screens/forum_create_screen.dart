import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/services/haptic_service.dart';
import '../models/forum_post.dart';
import '../providers/forum_providers.dart';
import '../../auth/providers/auth_provider.dart';

class ForumCreateScreen extends ConsumerStatefulWidget {
  const ForumCreateScreen({super.key});

  @override
  ConsumerState<ForumCreateScreen> createState() => _ForumCreateScreenState();
}

class _ForumCreateScreenState extends ConsumerState<ForumCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  String _selectedCategory = ForumCategory.genel.value;
  bool _isAnonymous = false;
  bool _submitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    setState(() => _submitting = true);
    try {
      await ref.read(forumServiceProvider).createPost(
            userId: user.uid,
            displayName: user.displayName ?? 'Kullanıcı',
            photoUrl: user.photoURL,
            isAnonymous: _isAnonymous,
            title: _titleController.text.trim(),
            content: _contentController.text.trim(),
            category: _selectedCategory,
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Gönderiniz paylaşıldı! 🎉'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gönderi paylaşılamadı: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text('Yeni Gönderi', style: AppTextStyles.appBarTitle.copyWith(fontSize: 18, fontWeight: FontWeight.w800)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Kategori seçimi
                      Text('Kategori Seçin', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: ForumCategory.values
                            .where((c) => c != ForumCategory.all)
                            .map((cat) {
                          final isSelected = _selectedCategory == cat.value;
                          return GestureDetector(
                            onTap: () {
                              HapticService.selection();
                              setState(() => _selectedCategory = cat.value);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.primary : Colors.grey[100],
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: isSelected ? [
                                  BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))
                                ] : [],
                              ),
                              child: Text(
                                '${cat.emoji} ${cat.label}',
                                style: TextStyle(
                                  color: isSelected ? Colors.white : AppColors.textSecondary,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
        
                      const SizedBox(height: 28),
        
                      // Başlık
                      Text('Başlık',
                          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _titleController,
                        maxLength: 200,
                        textInputAction: TextInputAction.next,
                        style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                        decoration: _inputDecoration('Konuyu kısaca özetleyin...'),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Başlık boş bırakılamaz.';
                          }
                          if (v.trim().length < 5) {
                            return 'Başlık en az 5 karakter olmalıdır.';
                          }
                          return null;
                        },
                      ),
        
                      const SizedBox(height: 20),
        
                      // İçerik
                      Text('İçerik',
                          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _contentController,
                        maxLines: 8,
                        maxLength: 2000,
                        textInputAction: TextInputAction.newline,
                        style: AppTextStyles.bodyMedium.copyWith(height: 1.5),
                        decoration: _inputDecoration(
                            'Sorunuzu veya paylaşmak istediğiniz bilgiyi detaylıca yazın...'),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'İçerik boş bırakılamaz.';
                          }
                          if (v.trim().length < 20) {
                            return 'İçerik en az 20 karakter olmalıdır.';
                          }
                          return null;
                        },
                      ),
        
                      const SizedBox(height: 20),
        
                      // Anonim paylaş seçeneği
                      GestureDetector(
                        onTap: () {
                          HapticService.selection();
                          setState(() => _isAnonymous = !_isAnonymous);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _isAnonymous ? AppColors.primary.withValues(alpha: 0.08) : Colors.grey[50],
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _isAnonymous ? AppColors.primary.withValues(alpha: 0.5) : Colors.grey.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: _isAnonymous ? AppColors.primary.withValues(alpha: 0.2) : Colors.grey[200],
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _isAnonymous ? Icons.person_off_rounded : Icons.person_rounded,
                                  color: _isAnonymous ? AppColors.primary : Colors.grey[600],
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Anonim Olarak Paylaş',
                                      style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Gönderide isminiz gizlenir',
                                      style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: _isAnonymous,
                                onChanged: (v) {
                                  HapticService.selection();
                                  setState(() => _isAnonymous = v);
                                },
                                activeColor: Colors.white,
                                activeTrackColor: AppColors.primary,
                              ),
                            ],
                          ),
                        ),
                      ),
        
                      const SizedBox(height: 16),
        
                      // Kural hatırlatması
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFDE7).withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFFBC02D).withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.info_rounded,
                                color: Color(0xFFF57F17), size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Topluluk kurallarına uygun paylaşım yapmanız önemlidir. İhlaller içerik gizlenmesine yol açabilir.',
                                style: AppTextStyles.caption.copyWith(
                                  color: const Color(0xFFF57F17),
                                  height: 1.4,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
        
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
            
            // Bottom Button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, -4)),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _submitting ? null : () {
                    HapticService.selection();
                    _submit();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
                    elevation: _submitting ? 0 : 4,
                    shadowColor: AppColors.primary.withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : Text(
                          'Gönderiyi Paylaş',
                          style: AppTextStyles.button.copyWith(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.textLight, fontWeight: FontWeight.normal),
      filled: true,
      fillColor: const Color(0xFFF8F9FA),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.error, width: 1),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
    );
  }
}
