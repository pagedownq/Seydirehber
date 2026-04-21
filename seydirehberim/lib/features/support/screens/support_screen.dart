import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/services/haptic_service.dart';
import '../../../core/services/notification_service.dart';

class SupportScreen extends ConsumerStatefulWidget {
  const SupportScreen({super.key});

  @override
  ConsumerState<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends ConsumerState<SupportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
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
        if (user != null) {
          if (user.displayName != null && _nameController.text.isEmpty) {
            _nameController.text = user.displayName!;
          }
          if (user.email != null && _emailController.text.isEmpty) {
            _emailController.text = user.email!;
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();

    if (email.isEmpty && phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen size ulaşabileceğimiz bir e-posta veya telefon numarası girin.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      final user = ref.read(authStateProvider).value;
      // Get FCM token for targeted notifications
      String? fcmToken;
      try {
        fcmToken = await FirebaseMessaging.instance.getToken();
        debugPrint('Support FCM Token: $fcmToken');
      } catch (e) {
        debugPrint('FCM Token get error: $e');
      }
      
      await FirebaseFirestore.instance.collection('yardim_destek').add({
        'ad_soyad': _nameController.text.trim(),
        'email': email,
        'telefon': phone,
        'kategori': _selectedCategory,
        'mesaj': _messageController.text.trim(),
        'uid': user?.uid ?? 'guest',
        'is_guest': user == null || ref.read(isGuestProvider),
        'tarih': FieldValue.serverTimestamp(),
        'durum': 'Bekliyor', // Default status for new messages
        'fcm_token': fcmToken ?? '',
      });

      if (mounted) {
        // Show success notification to the user
        NotificationService().showTestNotification(
          title: 'Destek Talebi Alındı 📩',
          body: 'Yardım & Destek talebiniz gönderilmiştir. En kısa zamanda dönüş yapılacaktır. Teşekkürler!',
        );

        // Go to home
        context.go('/');
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
                validator: (value) => value == null || value.trim().isEmpty ? 'Lütfen adınızı girin' : null,
              ),
              const SizedBox(height: 18),

              // Email Field (Only for guests)
              if (ref.watch(isGuestProvider)) ...[
                Text('E-posta Adresi', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    hintText: 'E-posta adresiniz',
                    prefixIcon: Icon(Icons.email_outlined, size: 20),
                  ),
                ),
                const SizedBox(height: 18),
              ],

              // Phone Field
              Text('Telefon Numarası', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  hintText: 'Telefon numaranız',
                  prefixIcon: Icon(Icons.phone_outlined, size: 20),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Size ulaşabilmemiz için e-posta veya telefon numaranızdan en az birini doldurmalısınız.',
                style: AppTextStyles.bodySmall.copyWith(fontSize: 12, color: Colors.grey[600]),
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
                  HapticService.selection();
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
              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isSending ? null : () {
                    HapticService.selection();
                    _submitForm();
                  },
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
