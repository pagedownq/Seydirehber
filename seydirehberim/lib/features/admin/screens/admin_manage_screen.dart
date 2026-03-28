import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/cached_image_widget.dart';

class AdminManageScreen extends ConsumerStatefulWidget {
  final String collection;
  final String title;
  final String? bucket;

  const AdminManageScreen({
    super.key,
    required this.collection,
    required this.title,
    this.bucket,
  });

  @override
  ConsumerState<AdminManageScreen> createState() => _AdminManageScreenState();
}

class _AdminManageScreenState extends ConsumerState<AdminManageScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.title, style: AppTextStyles.appBarTitle),
        backgroundColor: AppColors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditDialog(),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Ekle'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection(widget.collection)
            .orderBy('created_at', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Henüz veri yok'));
          }

          final docs = snapshot.data!.docs;
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final name = data['ad'] as String? ??
                  data['name'] as String? ??
                  data['guzergah'] as String? ??
                  'İsimsiz';
              final imageUrl =
                  data['image_url'] as String? ?? data['gorsel'] as String? ?? '';

              return Container(
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ListTile(
                  leading: CachedImageWidget(
                    imageUrl: imageUrl,
                    width: 50,
                    height: 50,
                    borderRadius: 8,
                  ),
                  title: Text(name,
                      style: AppTextStyles.bodyMedium
                          .copyWith(fontWeight: FontWeight.w600)),
                  trailing: PopupMenuButton(
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(value: 'edit', child: Text('Düzenle')),
                      const PopupMenuItem(value: 'delete', child: Text('Sil')),
                    ],
                    onSelected: (value) {
                      if (value == 'edit') {
                        _showAddEditDialog(docId: doc.id, existingData: data);
                      } else if (value == 'delete') {
                        _deleteDocument(doc.id, data);
                      }
                    },
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Fields config based on collection type
  List<_FieldConfig> _getFields() {
    switch (widget.collection) {
      case 'banners':
        return [
          _FieldConfig('ad', 'Banner Adı', required: true),
          _FieldConfig('url', 'Banner Linki (Opsiyonel)'),
          _FieldConfig('order', 'Sıra (0, 1, 2...)', isNumber: true),
        ];
      case 'etkinlikler':
        return [
          _FieldConfig('ad', 'Etkinlik Adı', required: true),
          _FieldConfig('hakkinda', 'Hakkında', multiline: true),
          _FieldConfig('baslangic_tarihi_str', 'Başlangıç Tarihi',
              isDate: true, required: true),
          _FieldConfig('bitis_tarihi_str', 'Bitiş Tarihi', isDate: true),
          _FieldConfig('saat', 'Saat', isTime: true),
          _FieldConfig('konum', 'Konum (Adres veya Harita Linki)'),
        ];
      case 'noterler':
        return [
          _FieldConfig('ad', 'Noter Adı', required: true),
          _FieldConfig('gunler', 'Açık Günler'),
          _FieldConfig('telefon', 'Telefon'),
          _FieldConfig('konum', 'Konum (Adres veya Harita Linki)'),
        ];
      case 'pazarlar':
        return [
          _FieldConfig('ad', 'Pazar Adı', required: true),
          _FieldConfig('gunler', 'Açık Günler'),
          _FieldConfig('konum', 'Konum (Adres veya Harita Linki)'),
        ];
      case 'otobus_saatleri':
        return [
          _FieldConfig('guzergah', 'Güzergah', required: true),
          _FieldConfig('saatler', 'Sefer Saatleri (Seçmeli)', multiline: true),
          _FieldConfig('duraklar', 'Duraklar', multiline: true),
        ];
      case 'gezilecek_yerler':
        return [
          _FieldConfig('ad', 'Yer Adı', required: true),
          _FieldConfig('hakkinda', 'Hakkında', multiline: true),
          _FieldConfig('tarihce', 'Tarihçe', multiline: true),
          _FieldConfig('konum', 'Konum (Adres veya Harita Linki)'),
        ];
      case 'firmalar':
        return [
          _FieldConfig('ad', 'Firma Adı', required: true),
          _FieldConfig('yetkili_kisi', 'Yetkili Kişi'),
          _FieldConfig('hakkinda', 'Hakkında', multiline: true),
          _FieldConfig('iletisim', 'İletişim (Telefon)', isPhone: true),
          _FieldConfig('konum', 'Konum (Adres veya Harita Linki)'),
          _FieldConfig('website', 'Web Sitesi'),
          _FieldConfig('instagram', 'Instagram (Kullanıcı adı veya Link)'),
        ];
      default:
        return [_FieldConfig('ad', 'Ad', required: true)];
    }
  }

  void _showAddEditDialog({String? docId, Map<String, dynamic>? existingData}) {
    final fields = _getFields();
    final controllers = <String, TextEditingController>{};
    File? selectedImage;
    bool isLoading = false;

    for (final field in fields) {
      controllers[field.key] = TextEditingController(
        text: existingData?[field.key]?.toString() ?? '',
      );
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              20,
              20,
              MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    docId == null ? 'Yeni Ekle' : 'Düzenle',
                    style: AppTextStyles.heading3,
                  ),
                  const SizedBox(height: 16),

                  // Image picker (if bucket exists)
                  if (widget.bucket != null) ...[
                    GestureDetector(
                      onTap: () async {
                        final picker = ImagePicker();
                        final image = await picker.pickImage(
                          source: ImageSource.gallery,
                          maxWidth: 1200,
                        );
                        if (image != null) {
                          setModalState(() => selectedImage = File(image.path));
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        height: 120,
                        decoration: BoxDecoration(
                          color: AppColors.primarySurface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: selectedImage != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(selectedImage!, fit: BoxFit.cover),
                              )
                            : CachedImageWidget(
                                imageUrl: existingData?['image_url'] ?? '',
                                borderRadius: 12,
                                width: double.infinity,
                                height: 120,
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Dynamic fields
                  ...fields.map((field) {
                    final isInteractionField = field.isDate || field.isTime;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: TextField(
                        controller: controllers[field.key],
                        readOnly: isInteractionField,
                        maxLines: field.multiline ? 4 : 1,
                        onTap: isInteractionField
                            ? () async {
                                if (field.isDate) {
                                  final date = await showDatePicker(
                                    context: context,
                                    initialDate: DateTime.now(),
                                    firstDate: DateTime(2024),
                                    lastDate: DateTime(2030),
                                  );
                                  if (date != null) {
                                    final formatted =
                                        "${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}";
                                    controllers[field.key]?.text = formatted;
                                  }
                                } else if (field.isTime) {
                                  final time = await showTimePicker(
                                    context: context,
                                    initialTime: TimeOfDay.now(),
                                  );
                                  if (time != null) {
                                    controllers[field.key]?.text =
                                        "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
                                  }
                                }
                              }
                            : null,
                        keyboardType: field.isNumber || field.isPhone
                            ? TextInputType.number
                            : TextInputType.text,
                        decoration: InputDecoration(
                          labelText: field.label,
                          hintText: field.label,
                          alignLabelWithHint: field.multiline,
                          suffixIcon: field.isDate
                              ? const Icon(Icons.calendar_today, size: 20)
                              : field.isTime
                                  ? const Icon(Icons.access_time, size: 20)
                                  : null,
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLoading
                          ? null
                          : () async {
                              // Validate required fields
                              for (final field in fields) {
                                if (field.required &&
                                    (controllers[field.key]?.text.isEmpty ??
                                        true)) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text('${field.label} zorunlu')),
                                  );
                                  return;
                                }
                              }

                              setModalState(() => isLoading = true);

                              try {
                                String? imageUrl =
                                    existingData?['image_url'] as String?;

                                // Upload image to Supabase if selected
                                if (selectedImage != null &&
                                    widget.bucket != null) {
                                  final fileName =
                                      '${DateTime.now().millisecondsSinceEpoch}.jpg';
                                  await Supabase.instance.client.storage
                                      .from(widget.bucket!)
                                      .upload(fileName, selectedImage!);
                                  imageUrl = Supabase.instance.client.storage
                                      .from(widget.bucket!)
                                      .getPublicUrl(fileName);
                                }

                                // Build document data
                                final docData = <String, dynamic>{};
                                  for (final field in fields) {
                                    final value =
                                        controllers[field.key]?.text.trim() ??
                                            '';
                                    if (value.isNotEmpty) {
                                      if (field.isNumber) {
                                        docData[field.key] =
                                            int.tryParse(value) ?? 0;
                                      } else if (field.key == 'instagram') {
                                        // Auto-prefix instagram username
                                        if (!value.startsWith('http')) {
                                          docData[field.key] =
                                              'https://www.instagram.com/$value';
                                        } else {
                                          docData[field.key] = value;
                                        }
                                      } else {
                                        docData[field.key] = value;
                                      }
                                    }
                                  }

                                if (imageUrl != null && imageUrl.isNotEmpty) {
                                  docData['image_url'] = imageUrl;
                                } else {
                                  // Use empty string to trigger the 'fotoyok.png' default in the UI
                                  docData['image_url'] = '';
                                }

                                if (docId == null) {
                                  docData['created_at'] =
                                      FieldValue.serverTimestamp();
                                  await FirebaseFirestore.instance
                                      .collection(widget.collection)
                                      .add(docData);
                                } else {
                                  await FirebaseFirestore.instance
                                      .collection(widget.collection)
                                      .doc(docId)
                                      .update(docData);
                                }

                                if (ctx.mounted) Navigator.pop(ctx);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(docId == null
                                          ? 'Başarıyla eklendi!'
                                          : 'Başarıyla güncellendi!'),
                                      backgroundColor: AppColors.success,
                                    ),
                                  );
                                }
                              } catch (e) {
                                setModalState(() => isLoading = false);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Hata: $e'),
                                      backgroundColor: AppColors.error,
                                    ),
                                  );
                                }
                              }
                            },
                      child: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : Text(docId == null ? 'Ekle' : 'Güncelle'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _deleteDocument(String docId, Map<String, dynamic> data) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Silme Onayı'),
        content: const Text('Bu veriyi silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // Get image URL from multiple possible keys
      final imageUrl = data['image_url'] as String? ?? data['gorsel'] as String?;

      // Delete image from Supabase Storage if it exists and a bucket is assigned
      if (widget.bucket != null && imageUrl != null && imageUrl.isNotEmpty) {
        try {
          final uri = Uri.parse(imageUrl);
          final fileName = uri.pathSegments.last;
          
          await Supabase.instance.client.storage
              .from(widget.bucket!)
              .remove([fileName]);
          
          debugPrint('Storage item deleted: $fileName');
        } catch (storageError) {
          debugPrint('Storage delete error: $storageError');
          // We continue to delete the document even if storage delete fails
        }
      }

      // Delete document from Firestore
      await FirebaseFirestore.instance
          .collection(widget.collection)
          .doc(docId)
          .delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Başarıyla silindi!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Silme hatası: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}

class _FieldConfig {
  final String key;
  final String label;
  final bool required;
  final bool multiline;
  final bool isNumber;
  final bool isDate;
  final bool isTime;
  final bool isPhone;

  _FieldConfig(
    this.key,
    this.label, {
    this.required = false,
    this.multiline = false,
    this.isNumber = false,
    this.isDate = false,
    this.isTime = false,
    this.isPhone = false,
  });
}
