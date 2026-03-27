import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../auth/providers/auth_provider.dart';

class SupportScreen extends ConsumerStatefulWidget {
  const SupportScreen({super.key});

  @override
  ConsumerState<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends ConsumerState<SupportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _messageController = TextEditingController();
  String _selectedCategory = 'Öneri';
  bool _isSending = false;

  final List<String> _categories = [
    'Öneri',
    'Şikayet',
    'Hata Bildirimi',
    'İş Birliği',
    'Diğer',
  ];

  @override
  void initState() {
    super.initState();
    // Pre-fill name if user is logged in
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = ref.read(authStateProvider);
      authState.whenData((user) {
        if (user != null && user.displayName != null) {
          _nameController.text = user.displayName!;
        }
      });
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSending = true);

    try {
      final user = ref.read(authStateProvider).value;
      
      await FirebaseFirestore.instance.collection('yardim_destek').add({
        'ad_soyad': _nameController.text.trim(),
        'kategori': _selectedCategory,
        'mesaj': _messageController.text.trim(),
        'email': user?.email ?? 'anonymous',
        'uid': user?.uid ?? 'guest',
        'tarih': FieldValue.serverTimestamp(),
        'durum': 'Bekliyor', // Default status for new messages
      });

      if (mounted) {
        // Go to home and show success message
        context.go('/');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mesajınız başarıyla gönderilmiştir! En kısa sürede size dönüş yapacağız.'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata oluştu: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Yardım & Destek', style: AppTextStyles.appBarTitle),
        backgroundColor: AppColors.white,
        surfaceTintColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Size nasıl yardımcı olabiliriz?',
                style: AppTextStyles.heading2,
              ),
              const SizedBox(height: 8),
              Text(
                'Görüşleriniz bizim için çok değerli. Lütfen formu eksiksiz doldurun.',
                style: AppTextStyles.bodySmall,
              ),
              const SizedBox(height: 24),

              // Name Field
              Text('Ad Soyad', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'Adınızı ve soyadınızı girin',
                  prefixIcon: const Icon(Icons.person_outline, size: 20),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Lütfen adınızı girin' : null,
              ),
              const SizedBox(height: 18),

              // Category Field
              Text('Kategori', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                items: _categories.map((cat) => DropdownMenuItem(
                  value: cat,
                  child: Text(cat),
                )).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCategory = val);
                },
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.category_outlined, size: 20),
                ),
              ),
              const SizedBox(height: 18),

              // Message Field
              Text('Mesajınız', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _messageController,
                maxLines: 6,
                decoration: const InputDecoration(
                  hintText: 'Düşüncelerinizi veya sorununuzu buraya yazın...',
                  alignLabelWithHint: true,
                ),
                validator: (value) => value == null || value.length < 5 ? 'Lütfen en az 5 karakterlik bir mesaj yazın' : null,
              ),
              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isSending ? null : _submitForm,
                  child: _isSending 
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Gönder'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
