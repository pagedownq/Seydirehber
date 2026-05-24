import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../models/forum_post.dart';
import '../models/forum_reply.dart';

class ForumEditSheet {
  static void showPostEdit(
      BuildContext context, ForumPost post, dynamic service) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EditPostSheet(post: post, service: service),
    );
  }

  static void showReplyEdit(
      BuildContext context, ForumReply reply, dynamic service) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EditReplySheet(reply: reply, service: service),
    );
  }
}

class _EditPostSheet extends StatefulWidget {
  final ForumPost post;
  final dynamic service;

  const _EditPostSheet({required this.post, required this.service});

  @override
  State<_EditPostSheet> createState() => _EditPostSheetState();
}

class _EditPostSheetState extends State<_EditPostSheet> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late String _selectedCategory;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.post.title);
    _contentController = TextEditingController(text: widget.post.content);
    _selectedCategory = widget.post.category;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty || content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Başlık ve içerik boş bırakılamaz.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await widget.service.editOwnPost(
        postId: widget.post.id,
        newTitle: title,
        newContent: content,
        newCategory: _selectedCategory,
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gönderi güncellendi.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 20),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 10,
        bottom: bottomInset > 0 ? bottomInset + 20 : 30,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
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
              'Gönderiyi Düzenle',
              style: AppTextStyles.heading3,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Kategori
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              items: ForumCategory.values
                  .where((c) => c != ForumCategory.all)
                  .map((c) => DropdownMenuItem(
                        value: c.value,
                        child: Text('${c.emoji} ${c.label}'),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v != null) {
                  setState(() => _selectedCategory = v);
                }
              },
              decoration: _inputDecoration('Kategori'),
              icon: const Icon(Icons.keyboard_arrow_down_rounded),
            ),
            const SizedBox(height: 16),

            // Başlık
            TextField(
              controller: _titleController,
              decoration: _inputDecoration('Başlık'),
              style: AppTextStyles.bodyMedium,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),

            // İçerik
            TextField(
              controller: _contentController,
              decoration: _inputDecoration('İçerik'),
              style: AppTextStyles.bodyMedium,
              maxLines: 5,
              minLines: 3,
            ),
            const SizedBox(height: 24),

            // Butonlar
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: const BorderSide(color: AppColors.border),
                    ),
                    child: Text(
                      'İptal',
                      style: AppTextStyles.bodyMedium
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Kaydet',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.textLight),
      filled: true,
      fillColor: AppColors.background,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.transparent),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
  }
}

class _EditReplySheet extends StatefulWidget {
  final ForumReply reply;
  final dynamic service;

  const _EditReplySheet({required this.reply, required this.service});

  @override
  State<_EditReplySheet> createState() => _EditReplySheetState();
}

class _EditReplySheetState extends State<_EditReplySheet> {
  late TextEditingController _contentController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _contentController = TextEditingController(text: widget.reply.content);
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final content = _contentController.text.trim();

    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('İçerik boş bırakılamaz.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await widget.service.editOwnReply(
        replyId: widget.reply.id,
        newContent: content,
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Yanıt güncellendi.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 20),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 10,
        bottom: bottomInset > 0 ? bottomInset + 20 : 30,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
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
              'Yanıtı Düzenle',
              style: AppTextStyles.heading3,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // İçerik
            TextField(
              controller: _contentController,
              decoration: _inputDecoration('İçerik'),
              style: AppTextStyles.bodyMedium,
              maxLines: 5,
              minLines: 3,
            ),
            const SizedBox(height: 24),

            // Butonlar
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: const BorderSide(color: AppColors.border),
                    ),
                    child: Text(
                      'İptal',
                      style: AppTextStyles.bodyMedium
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Kaydet',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.textLight),
      filled: true,
      fillColor: AppColors.background,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.transparent),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
  }
}
