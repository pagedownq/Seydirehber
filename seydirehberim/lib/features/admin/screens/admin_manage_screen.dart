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
            .snapshots()
            .handleError((_) {
              // If index or field missing, fall back to unordered
              return FirebaseFirestore.instance
                  .collection(widget.collection)
                  .snapshots();
            }),
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
                  data['title'] as String? ??
                  data['username'] as String? ??
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
                  subtitle: _buildListSubtitle(data),
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

  Widget? _buildListSubtitle(Map<String, dynamic> data) {
    switch (widget.collection) {
      case 'firmalar':
        if (data['expiry_date'] == null) {
          return Text(
            'Bitiş: Sınırsız',
            style: TextStyle(fontSize: 12, color: Colors.green[600], fontWeight: FontWeight.w600),
          );
        }
        final expiry = (data['expiry_date'] as Timestamp).toDate();
        final isExpired = expiry.isBefore(DateTime.now());
        return Text(
          'Bitiş: ${expiry.day.toString().padLeft(2, '0')}.${expiry.month.toString().padLeft(2, '0')}.${expiry.year}',
          style: TextStyle(
            fontSize: 12,
            color: isExpired ? Colors.red : Colors.grey[600],
            fontWeight: isExpired ? FontWeight.bold : FontWeight.normal,
          ),
        );
      case 'esnaf_users':
        final companyId = data['company_id'] as String? ?? '';
        return Text(
          'Firma ID: ${companyId.isNotEmpty ? companyId : 'Bağlı değil'}',
          style: const TextStyle(fontSize: 12),
        );
      case 'coupons':
        final isActive = data['isActive'] as bool? ?? false;
        final companyName = data['companyName'] as String? ?? '';
        return Text(
          '${companyName.isNotEmpty ? companyName : 'Firma yok'} • ${isActive ? '✅ Aktif' : '❌ Pasif'}',
          style: TextStyle(
            fontSize: 12,
            color: isActive ? Colors.green[700] : Colors.red,
          ),
        );
      default:
        return null;
    }
  }

  // Fields config based on collection type
  List<_FieldConfig> _getFields() {
    switch (widget.collection) {
      case 'banners':
        return [
          _FieldConfig('ad', 'Banner Adı', required: true),
          _FieldConfig('url', 'Dış Bağlantı (Opsiyonel)'),
          _FieldConfig('company_id', 'Firma Yönlendirme (Opsiyonel)', isCompanyPicker: true),
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
          _FieldConfig('adres', 'Görünecek Adres (Örn: Aşağı Hisar...)'),
          _FieldConfig('konum', 'Harita Konumu (Link, Koordinat veya DMS)'),
        ];
      case 'noterler':
        return [
          _FieldConfig('ad', 'Noter Adı', required: true),
          _FieldConfig('gunler', 'Açık Günler'),
          _FieldConfig('telefon', 'Telefon'),
          _FieldConfig('adres', 'Görünecek Adres'),
          _FieldConfig('konum', 'Harita Konumu (Link, Koordinat veya DMS)'),
        ];
      case 'pazarlar':
        return [
          _FieldConfig('ad', 'Pazar Adı', required: true),
          _FieldConfig('gunler', 'Açık Günler'),
          _FieldConfig('adres', 'Görünecek Adres'),
          _FieldConfig('konum', 'Harita Konumu (Link, Koordinat veya DMS)'),
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
          _FieldConfig('adres', 'Görünecek Adres'),
          _FieldConfig('konum', 'Harita Konumu (Link, Koordinat veya DMS)'),
        ];
      case 'firmalar':
        return [
          _FieldConfig('ad', 'Firma Adı', required: true),
          _FieldConfig('yetkili_kisi', 'Yetkili Kişi'),
          _FieldConfig('hakkinda', 'Hakkında', multiline: true),
          _FieldConfig('iletisim', 'İletişim (Telefon)', isPhone: true),
          _FieldConfig('adres', 'Görünecek Adres'),
          _FieldConfig('konum', 'Harita Konumu (Link, Koordinat veya DMS)'),
          _FieldConfig('website', 'Web Sitesi'),
          _FieldConfig('instagram', 'Instagram (Kullanıcı adı veya Link)'),
          _FieldConfig('expiry_date', 'Firma Bitiş Tarihi', isDate: true),
        ];
      case 'esnaf_users':
        return [
          _FieldConfig('username', 'Kullanıcı Adı', required: true),
          _FieldConfig('password', 'Şifre', required: true),
          _FieldConfig('company_id', 'Bağlı Olduğu Firma', isCompanyPicker: true, required: true),
        ];
      case 'coupons':
        return [
          _FieldConfig('title', 'Kupon Başlığı (Örn: %20 İndirim)', required: true),
          _FieldConfig('description', 'Kupon Detayı', multiline: true, required: true),
          _FieldConfig('companyId', 'Firma Seç', isCompanyPicker: true, required: true),
          _FieldConfig('companyName', 'Firma Adı (Otomatik dolar)', readOnly: true),
          _FieldConfig('discountPercentage', 'İndirim Yüzdesi (Örn: 20)', isNumber: true),
          _FieldConfig('isActive', 'Aktif Mi?', isBoolean: true, defaultValue: true),
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

    final boolValues = <String, bool>{};
    for (final field in fields) {
      if (field.isBoolean) {
        boolValues[field.key] = existingData?[field.key] ?? field.defaultValue;
        continue; // Booleans don't need controllers
      }
      String initialValue = '';
      final val = existingData?[field.key];
      
      if (val != null) {
        if (val is Timestamp) {
          final date = val.toDate();
          if (field.isDateTime) {
            initialValue = "${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
          } else {
            initialValue = "${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}";
          }
        } else {
          initialValue = val.toString();
        }
      } else if (field.defaultValue != null) {
        initialValue = field.defaultValue.toString();
      }
      
      controllers[field.key] = TextEditingController(text: initialValue);
    }

    bool isUnlimited = widget.collection == 'firmalar' && 
                       (existingData?['expiry_date'] == null && (docId != null || controllers['expiry_date']?.text.isEmpty != false));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          // Sync with controller locally if needed, but allow toggle
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

                  ...fields.expand((field) {
                    final isInteractionField = field.isDate || field.isTime || field.isDateTime || field.isCompanyPicker;
                    final isExpiryField = field.key == 'expiry_date';

                    return [
                      if (isExpiryField)
                        CheckboxListTile(
                          value: isUnlimited,
                          onChanged: (val) {
                            setModalState(() {
                              isUnlimited = val ?? false;
                              if (isUnlimited) {
                                controllers[field.key]?.clear();
                              }
                            });
                          },
                          title: const Text('Sınırsız Gösterim', style: TextStyle(fontSize: 14)),
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        ),
                      if (field.isBoolean)
                        SwitchListTile(
                          value: boolValues[field.key] ?? false,
                          onChanged: (val) => setModalState(() => boolValues[field.key] = val),
                          title: Text(field.label, style: const TextStyle(fontSize: 14)),
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        ),
                      if (!isExpiryField || !isUnlimited)
                        if (!field.isBoolean)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: TextField(
                            controller: controllers[field.key],
                            readOnly: isInteractionField || field.readOnly,
                            maxLines: field.multiline ? 4 : 1,
                            onTap: (isInteractionField && !field.readOnly)
                                ? () async {
                                    if (field.isDate || field.isDateTime) {
                                      final date = await showDatePicker(
                                        context: context,
                                        initialDate: DateTime.now(),
                                        firstDate: DateTime(2024),
                                        lastDate: DateTime(2030),
                                      );
                                      if (date != null) {
                                        if (field.isDateTime) {
                                          final time = await showTimePicker(
                                            context: context,
                                            initialTime: TimeOfDay.now(),
                                          );
                                          if (time != null) {
                                            final dateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                                            controllers[field.key]?.text = 
                                              "${dateTime.day.toString().padLeft(2, '0')}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
                                          }
                                        } else {
                                          final formatted =
                                              "${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}";
                                          controllers[field.key]?.text = formatted;
                                        }
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
                                    } else if (field.isCompanyPicker) {
                                      _showCompanyPicker(context, (id, name) {
                                        setModalState(() {
                                          controllers[field.key]?.text = "$name | $id";
                                          // Auto-fill companyName if it exists in fields
                                          if (controllers.containsKey('companyName')) {
                                            controllers['companyName']?.text = name;
                                          }
                                        });
                                      });
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
                              suffixIcon: field.isDate || field.isDateTime
                                  ? const Icon(Icons.calendar_today, size: 20)
                                  : field.isTime
                                      ? const Icon(Icons.access_time, size: 20)
                                      : field.isCompanyPicker
                                          ? IconButton(
                                              icon: controllers[field.key]!.text.isNotEmpty 
                                                  ? const Icon(Icons.clear, size: 20)
                                                  : const Icon(Icons.business, size: 20),
                                              onPressed: controllers[field.key]!.text.isNotEmpty 
                                                  ? () => setModalState(() => controllers[field.key]?.clear())
                                                  : null,
                                            )
                                          : null,
                            ),
                          ),
                        ),
                    ];
                  }).toList(),
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
                                String? imageUrl = existingData?['image_url'] as String?;

                                // Upload image to Supabase if selected
                                if (selectedImage != null && widget.bucket != null) {
                                  final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
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
                                  if (field.isBoolean) {
                                    docData[field.key] = boolValues[field.key] ?? false;
                                    continue;
                                  }
                                  final value = controllers[field.key]?.text.trim() ?? '';
                                  if (value.isNotEmpty) {
                                    if (field.isNumber) {
                                      docData[field.key] = int.tryParse(value) ?? 0;
                                    } else if (field.key == 'expiry_date' || field.isDate) {
                                      try {
                                        final parts = value.split(' ');
                                        final dateParts = parts[0].split('.');
                                        int year = int.parse(dateParts[2]);
                                        int month = int.parse(dateParts[1]);
                                        int day = int.parse(dateParts[0]);
                                        int hour = 0;
                                        int minute = 0;

                                        if (parts.length > 1) {
                                          final timeParts = parts[1].split(':');
                                          hour = int.parse(timeParts[0]);
                                          minute = int.parse(timeParts[1]);
                                        }

                                        final date = DateTime(year, month, day, hour, minute);
                                        docData[field.key] = Timestamp.fromDate(date);
                                      } catch (e) {
                                        debugPrint('Date parse error: $e');
                                      }
                                    } else if (field.key == 'instagram') {
                                      if (!value.startsWith('http')) {
                                        docData[field.key] = 'https://www.instagram.com/$value';
                                      } else {
                                        docData[field.key] = value;
                                      }
                                    } else if (field.isCompanyPicker) {
                                      final parts = value.split(' | ');
                                      docData[field.key] = parts.last;
                                    } else {
                                      docData[field.key] = value;
                                    }
                                  } else {
                                    docData[field.key] = null;
                                  }
                                }

                                if (imageUrl != null && imageUrl.isNotEmpty) {
                                  docData['image_url'] = imageUrl;
                                } else if (docId == null) {
                                  // For NEW documents, if no image uploaded, default to empty string
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

  void _showCompanyPicker(
      BuildContext context, Function(String id, String name) onSelect) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Firma Seç'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(
                  hintText: 'Firma ara...',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (val) {
                  // Basic filtering logic could go here
                },
              ),
              const SizedBox(height: 16),
              Flexible(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('firmalar')
                      .orderBy('ad')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final companies = snapshot.data!.docs;
                    return ListView.builder(
                      shrinkWrap: true,
                      itemCount: companies.length,
                      itemBuilder: (context, index) {
                        final data =
                            companies[index].data() as Map<String, dynamic>;
                        final name = data['ad'] ?? 'İsimsiz';
                        final id = companies[index].id;

                        return ListTile(
                          title: Text(name),
                          onTap: () {
                            onSelect(id, name);
                            Navigator.pop(context);
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
  final bool isDateTime;
  final bool isPhone;
  final bool isCompanyPicker;
  final bool isBoolean;
  final bool readOnly;
  final dynamic defaultValue;

  _FieldConfig(
    this.key,
    this.label, {
    this.required = false,
    this.multiline = false,
    this.isNumber = false,
    this.isDate = false,
    this.isTime = false,
    this.isDateTime = false,
    this.isPhone = false,
    this.isCompanyPicker = false,
    this.isBoolean = false,
    this.readOnly = false,
    this.defaultValue,
  });
}
