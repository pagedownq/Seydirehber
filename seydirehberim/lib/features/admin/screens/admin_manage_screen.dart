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
            .handleError((error) {
              debugPrint('Ordered query failed for ${widget.collection}: $error');
            }),
        builder: (context, snapshot) {
          // If the ordered query errors out (missing index), try unordered
          if (snapshot.hasError) {
            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection(widget.collection)
                  .snapshots(),
              builder: (context, fallbackSnapshot) {
                if (fallbackSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!fallbackSnapshot.hasData || fallbackSnapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('Henüz veri yok'));
                }
                return _buildDocList(List<DocumentSnapshot>.from(fallbackSnapshot.data!.docs));
              },
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Henüz veri yok'));
          }

          final docs = List<DocumentSnapshot>.from(snapshot.data!.docs);
          return _buildDocList(docs);
        },
      ),
    );
  }

  Widget _buildDocList(List<DocumentSnapshot> docs) {
    // Perform sorting once per data update
    _sortDocs(docs);

    final isReorderable = widget.collection == 'firmalar' || 
                          widget.collection == 'banners' || 
                          widget.collection == 'gezilecek_yerler' || 
                          widget.collection == 'otobus_saatleri';

    if (isReorderable) {
      return ReorderableListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: docs.length,
        onReorder: (oldIndex, newIndex) async {
          if (newIndex > oldIndex) newIndex -= 1;
          final movedItem = docs.removeAt(oldIndex);
          docs.insert(newIndex, movedItem);

          final batch = FirebaseFirestore.instance.batch();
          for (int i = 0; i < docs.length; i++) {
            batch.update(
              FirebaseFirestore.instance.collection(widget.collection).doc(docs[i].id),
              {'order': i},
            );
          }
          await batch.commit();
        },
        proxyDecorator: (child, index, animation) => Material(
          elevation: 8,
          color: Colors.transparent,
          child: child,
        ),
        itemBuilder: (context, index) {
          final doc = docs[index];
          return _AdminListItem(
            key: ValueKey(doc.id),
            doc: doc,
            index: index,
            collection: widget.collection,
            isReorderable: isReorderable,
            onEdit: (id, data) => _showAddEditDialog(docId: id, existingData: data),
            onDelete: (id, data) => _deleteDocument(id, data),
            subtitleBuilder: _buildListSubtitle,
          );
        },
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: docs.length,
      itemBuilder: (context, index) {
        final doc = docs[index];
        return _AdminListItem(
          key: ValueKey(doc.id),
          doc: doc,
          index: index,
          collection: widget.collection,
          isReorderable: false,
          onEdit: (id, data) => _showAddEditDialog(docId: id, existingData: data),
          onDelete: (id, data) => _deleteDocument(id, data),
          subtitleBuilder: _buildListSubtitle,
        );
      },
    );
  }

  void _sortDocs(List<DocumentSnapshot> docs) {
    if (widget.collection == 'firmalar' || widget.collection == 'gezilecek_yerler' || widget.collection == 'otobus_saatleri') {
      docs.sort((a, b) {
        final aData = a.data() as Map<String, dynamic>;
        final bData = b.data() as Map<String, dynamic>;
        final aOrder = num.tryParse(aData['order']?.toString() ?? '') ?? 999999;
        final bOrder = num.tryParse(bData['order']?.toString() ?? '') ?? 999999;
        if (aOrder != bOrder) return aOrder.compareTo(bOrder);
        final aName = (aData['ad'] ?? aData['guzergah'] ?? '').toString().toLowerCase();
        final bName = (bData['ad'] ?? bData['guzergah'] ?? '').toString().toLowerCase();
        return aName.compareTo(bName);
      });
    } else if (widget.collection == 'banners') {
      docs.sort((a, b) {
        final aData = a.data() as Map<String, dynamic>;
        final bData = b.data() as Map<String, dynamic>;
        final aOrder = num.tryParse(aData['order']?.toString() ?? '') ?? 999999;
        final bOrder = num.tryParse(bData['order']?.toString() ?? '') ?? 999999;
        return aOrder.compareTo(bOrder);
      });
    }
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
        final companyId = data['companyId'] as String? ?? '';
        final companyName = data['companyName'] as String? ?? '';
        return Text(
          'Firma: ${companyName.isNotEmpty ? companyName : (companyId.isNotEmpty ? companyId : 'Bağlı değil')}',
          style: const TextStyle(fontSize: 12),
        );
      case 'coupons':
        final isActive = data['isActive'] as bool? ?? false;
        final companyName = data['companyName'] as String? ?? '';
        final expiry = data['expiry_date'] as Timestamp?;
        final totalLimit = data['total_limit'] as int?;
        final usedCount = data['used_count'] as int? ?? 0;

        String sub = 'Firma: ${companyName.isNotEmpty ? companyName : 'Bilinmiyor'} • ${isActive ? '✅ Aktif' : '❌ Pasif'}';
        if (expiry != null) {
          final date = expiry.toDate();
          sub += '\nBitiş: ${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
        }
        if (totalLimit != null) {
          sub += ' • Limit: $usedCount/$totalLimit';
        }

        return Text(
          sub,
          style: TextStyle(
            fontSize: 12,
            color: isActive ? Colors.green[700] : Colors.red,
          ),
        );
      case 'otobus_saatleri':
        final hergun = data['saatler_hergun'] as String? ?? '';
        final haftaici = data['saatler_haftaici'] as String? ?? '';
        final cumartesi = data['saatler_cumartesi'] as String? ?? '';
        final pazar = data['saatler_pazar'] as String? ?? '';

        Widget buildGroup(String label, String times, Color color) {
          if (times.isEmpty) return const SizedBox.shrink();
          final list = times.split(',').where((e) => e.isNotEmpty).toList()..sort();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 4),
                child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
              ),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: list.map((t) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: color.withOpacity(0.3)),
                  ),
                  child: Text(t, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
                )).toList(),
              ),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hergun.isNotEmpty)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.2)),
                ),
                child: buildGroup('HER GÜN', hergun, Colors.blue[800]!),
              ),
            buildGroup('HAFTA İÇİ', haftaici, Colors.grey[700]!),
            buildGroup('CUMARTESİ', cumartesi, Colors.orange[800]!),
            buildGroup('PAZAR', pazar, Colors.red[800]!),
          ],
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
          _FieldConfig('aktif', 'Aktif mi?', isBoolean: true, defaultValue: true),
        ];
      case 'etkinlikler':
        return [
          _FieldConfig('ad', 'Etkinlik Adı', required: true),
          _FieldConfig('hakkinda', 'Hakkında', multiline: true),
          _FieldConfig('baslangic_tarihi_str', 'Başlangıç Tarihi', isDate: true),
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
          _FieldConfig('saatler_hergun', 'Her Gün Sefer Saatleri (Ortak)', isTimeList: true),
          _FieldConfig('saatler_haftaici', 'Hafta İçi (Pzt-Cum)', isTimeList: true),
          _FieldConfig('saatler_cumartesi', 'Cumartesi', isTimeList: true),
          _FieldConfig('saatler_pazar', 'Pazar', isTimeList: true),
          _FieldConfig('duraklar', 'Duraklar (Opsiyonel)', multiline: true),
          _FieldConfig('order', 'Sıra', isNumber: true),
        ];
      case 'gezilecek_yerler':
        return [
          _FieldConfig('ad', 'Yer Adı', required: true),
          _FieldConfig('hakkinda', 'Hakkında', multiline: true),
          _FieldConfig('tarihce', 'Tarihçe', multiline: true),
          _FieldConfig('adres', 'Görünecek Adres'),
          _FieldConfig('konum', 'Harita Konumu (Link, Koordinat veya DMS)'),
          _FieldConfig('order', 'Sıra (Görünüm Sırası)', isNumber: true),
        ];
      case 'firmalar':
        return [
          _FieldConfig('ad', 'Firma Adı', required: true),
          _FieldConfig('kategori', 'Kategori (Örn: Restoran, Kafe, Market)'),
          _FieldConfig('yetkili_kisi', 'Yetkili Kişi'),
          _FieldConfig('hakkinda', 'Hakkında', multiline: true),
          _FieldConfig('iletisim', 'İletişim (Telefon)', isPhone: true),
          _FieldConfig('adres', 'Görünecek Adres'),
          _FieldConfig('konum', 'Harita Konumu (Link, Koordinat veya DMS)'),
          _FieldConfig('website', 'Web Sitesi'),
          _FieldConfig('instagram', 'Instagram (Kullanıcı adı veya Link)'),
          _FieldConfig('menu_url', 'Dijital Bağlantı (Mağaza, Menü, Katalog vb.)'),
          _FieldConfig('expiry_date', 'Firma Bitiş Tarihi', isDate: true),
          _FieldConfig('order', 'Sıra (Görünüm Sırası)', isNumber: true),
        ];
      case 'esnaf_users':
        return [
          _FieldConfig('username', 'Kullanıcı Adı', required: true),
          _FieldConfig('password', 'Şifre', required: true),
          _FieldConfig('companyId', 'Bağlı Olduğu Firma', isCompanyPicker: true, required: true),
          _FieldConfig('companyName', 'Firma Adı', required: true),
        ];
      case 'coupons':
        return [
          _FieldConfig('title', 'Kupon Başlığı (Örn: %20 İndirim)', required: true),
          _FieldConfig('description', 'Kupon Detayı', multiline: true),
          _FieldConfig('companyId', 'Firma Seç', isCompanyPicker: true, required: true),
          _FieldConfig('companyName', 'Firma Adı (Otomatik dolar)', readOnly: true),
          _FieldConfig('discountPercentage', 'İndirim Yüzdesi (Örn: 20)', isNumber: true),
          _FieldConfig('expiry_date', 'Bitiş Tarihi (Opsiyonel)', isDate: true),
          _FieldConfig('total_limit', 'Toplam Kupon Sayısı (Opsiyonel)', isNumber: true),
          _FieldConfig('isActive', 'Aktif Mi?', isBoolean: true, defaultValue: true),
        ];
      case 'admins':
        return [
          _FieldConfig('email', 'Admin Email', required: true),
          _FieldConfig('ad_soyad', 'Ad Soyad', required: true),
          _FieldConfig('isActive', 'Aktif Mi?', isBoolean: true, defaultValue: true),
          _FieldConfig('canManageBanners', 'Banner Yönetimi', isBoolean: true, defaultValue: false),
          _FieldConfig('canManageEvents', 'Etkinlik Yönetimi', isBoolean: true, defaultValue: false),
          _FieldConfig('canManageNotaries', 'Noter Yönetimi', isBoolean: true, defaultValue: false),
          _FieldConfig('canManageMarkets', 'Pazar Yönetimi', isBoolean: true, defaultValue: false),
          _FieldConfig('canManageBuses', 'Ulaşım Yönetimi', isBoolean: true, defaultValue: false),
          _FieldConfig('canManagePlaces', 'Mekan Yönetimi', isBoolean: true, defaultValue: false),
          _FieldConfig('canManageCompanies', 'Firma Yönetimi', isBoolean: true, defaultValue: false),
          _FieldConfig('canManageSupport', 'Destek Yönetimi', isBoolean: true, defaultValue: false),
          _FieldConfig('canManageReviews', 'Yorum Yönetimi', isBoolean: true, defaultValue: false),
          _FieldConfig('canManageReports', 'Şikayet Yönetimi', isBoolean: true, defaultValue: false),
          _FieldConfig('canManageNotifications', 'Bildirim Yönetimi', isBoolean: true, defaultValue: false),
          _FieldConfig('canManageEsnaf', 'Esnaf Yönetimi', isBoolean: true, defaultValue: false),
          _FieldConfig('canManageCoupons', 'Kupon Yönetimi', isBoolean: true, defaultValue: false),
          _FieldConfig('canManageAdmins', 'Admin Yönetimi', isBoolean: true, defaultValue: false),
        ];
      default:
        return [_FieldConfig('ad', 'Ad', required: true)];
    }
  }

  void _showAddEditDialog({String? docId, Map<String, dynamic>? existingData}) {
    final fields = _getFields();
    final controllers = <String, TextEditingController>{};
    List<File> selectedImages = [];
    List<String> existingImages = (existingData?['images'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
    if (existingImages.isEmpty && existingData?['image_url'] != null) {
      existingImages.add(existingData!['image_url']);
    }
    List<String> imagesToDelete = [];
    bool isLoading = false;

    final boolValues = <String, bool>{};
    for (final field in fields) {
      if (field.isBoolean) {
        boolValues[field.key] = existingData?[field.key] ?? field.defaultValue;
        continue;
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

                  // MULTI-IMAGE PICKER (Firms Only)
                  if (widget.bucket != null) ...[
                    const Text('Fotoğraflar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          // ADD BUTTON
                          GestureDetector(
                            onTap: () async {
                              final picker = ImagePicker();
                              final images = await picker.pickMultiImage(
                                maxWidth: 1000, // Boyutu optimize ettik
                                imageQuality: 70, // Sıkıştırma oranını artırdık (hız için)
                              );
                              if (images.isNotEmpty) {
                                setModalState(() {
                                  selectedImages.addAll(images.map((e) => File(e.path)));
                                });
                              }
                            },
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: AppColors.primarySurface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: const Icon(Icons.add_a_photo, color: AppColors.primary),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // EXISTING IMAGES (From URLs)
                          ...existingImages.map((url) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Stack(
                              clipBehavior: Clip.none, // Butonun dışarı taşmasına izin ver
                              children: [
                                CachedImageWidget(
                                  imageUrl: url,
                                  width: 80,
                                  height: 80,
                                  borderRadius: 12,
                                ),
                                Positioned(
                                  top: -8,
                                  right: -8,
                                  child: GestureDetector(
                                    onTap: () => setModalState(() {
                                      existingImages.remove(url);
                                      imagesToDelete.add(url);
                                    }),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4)
                                        ],
                                      ),
                                      child: const Icon(Icons.close, size: 16, color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )),
                          // NEWLY SELECTED IMAGES (From Files)
                          ...selectedImages.map((file) => Padding(
                            padding: const EdgeInsets.only(right: 12, top: 8), // Boşlukları artırdık
                            child: Stack(
                              clipBehavior: Clip.none, // Butonun dışarı taşmasına izin ver
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.file(file, width: 80, height: 80, fit: BoxFit.cover),
                                ),
                                Positioned(
                                  top: -8,
                                  right: -8,
                                  child: GestureDetector(
                                    onTap: () => setModalState(() => selectedImages.remove(file)),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.black,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4)
                                        ],
                                      ),
                                      child: const Icon(Icons.close, size: 16, color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )),
                        ],
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
                        if (field.isTimeList)
                          _buildTimeListPicker(field, controllers, setModalState),
                        if (!field.isTimeList && (!isExpiryField || !isUnlimited))
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
                                      _showCompanyPicker(context, (data, id) {
                                        final name = data['ad'] ?? 'İsimsiz';
                                        final category = data['kategori'] ?? '';
                                        setModalState(() {
                                          controllers[field.key]?.text = "$name | $id";
                                          // Auto-fill companyName and category if applicable
                                          if (controllers.containsKey('companyName')) {
                                            controllers['companyName']?.text = name;
                                          }
                                          // Store category in a temporary state or just ensure it gets saved
                                          existingData?['companyCategory'] = category;
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
                                List<String> allImageUrls = [...existingImages];

                                // Upload new images to Supabase in PARALLEL
                                if (selectedImages.isNotEmpty && widget.bucket != null) {
                                  final List<String> newUrls = await Future.wait(
                                    selectedImages.map((file) async {
                                      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${selectedImages.indexOf(file)}_${file.path.split('/').last}';
                                      await Supabase.instance.client.storage
                                          .from(widget.bucket!)
                                          .upload(fileName, file);
                                      return Supabase.instance.client.storage
                                          .from(widget.bucket!)
                                          .getPublicUrl(fileName);
                                    }),
                                  );
                                  allImageUrls.addAll(newUrls);
                                }

                                // Delete removed images from Supabase
                                for (var url in imagesToDelete) {
                                  try {
                                    final fileName = url.split('/').last;
                                    await Supabase.instance.client.storage.from(widget.bucket!).remove([fileName]);
                                  } catch (e) {
                                    debugPrint('Error deleting image: $e');
                                  }
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
                                      if (existingData?['companyCategory'] != null) {
                                        docData['companyCategory'] = existingData!['companyCategory'];
                                      }
                                    } else {
                                      docData[field.key] = value;
                                    }
                                  } else {
                                    docData[field.key] = null;
                                  }
                                }

                                // Update images list
                                docData['images'] = allImageUrls;
                                // Fallback for single image_url
                                docData['image_url'] = allImageUrls.isNotEmpty ? allImageUrls.first : '';

                                  if (docId == null) {
                                    docData['created_at'] =
                                        FieldValue.serverTimestamp();
                                    
                                    // Automatic order assignment for reorderable collections
                                    if (widget.collection == 'firmalar' || widget.collection == 'banners' || widget.collection == 'gezilecek_yerler' || widget.collection == 'otobus_saatleri') {
                                      final query = await FirebaseFirestore.instance
                                          .collection(widget.collection)
                                          .orderBy('order', descending: true)
                                          .limit(1)
                                          .get();
                                      
                                      int nextOrder = 0;
                                      if (query.docs.isNotEmpty) {
                                        final lastOrder = query.docs.first.data()['order'];
                                        if (lastOrder is num) {
                                          nextOrder = lastOrder.toInt() + 1;
                                        }
                                      } else {
                                        // Fallback if no order field exists yet
                                        final allDocs = await FirebaseFirestore.instance.collection(widget.collection).get();
                                        for (var doc in allDocs.docs) {
                                          final order = (doc.data() as Map)['order'] ?? -1;
                                          if (order is num && order >= nextOrder) nextOrder = order.toInt() + 1;
                                        }
                                      }
                                      docData['order'] = nextOrder;
                                    }

                                    if (widget.collection == 'admins') {
                                      final email = docData['email']?.toString().toLowerCase().trim() ?? '';
                                      if (email.isEmpty) throw 'Email gereklidir';
                                      await FirebaseFirestore.instance
                                          .collection(widget.collection)
                                          .doc(email)
                                          .set(docData);
                                    } else {
                                      await FirebaseFirestore.instance
                                          .collection(widget.collection)
                                          .add(docData);
                                    }
                                  } else {
                                    await FirebaseFirestore.instance
                                        .collection(widget.collection)
                                        .doc(docId)
                                        .set(docData, SetOptions(merge: true));
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
                          : Text(docId == null 
                              ? (selectedImages.isNotEmpty ? 'Fotoğraflar Yükleniyor...' : 'Ekle') 
                              : (selectedImages.isNotEmpty ? 'Fotoğraflar Yükleniyor...' : 'Güncelle')),
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
      // Get all images to delete from Storage
      final List<String> images = (data['images'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
      if (images.isEmpty && (data['image_url'] as String?) != null) {
        images.add(data['image_url']);
      }

      // Delete images from Supabase Storage if they exist and a bucket is assigned
      if (widget.bucket != null && images.isNotEmpty) {
        try {
          final List<String> fileNames = images.map((url) => url.split('/').last).toList();
          await Supabase.instance.client.storage.from(widget.bucket!).remove(fileNames);
          debugPrint('Storage items deleted: $fileNames');
        } catch (storageError) {
          debugPrint('Storage delete error: $storageError');
        }
      }

      // 1. Delete associated data (Cascading Delete)
      final batch = FirebaseFirestore.instance.batch();
      bool hasBatchWork = false;

      if (widget.collection == 'firmalar') {
        // Delete coupons of this company
        final coupons = await FirebaseFirestore.instance
            .collection('coupons')
            .where('companyId', isEqualTo: docId)
            .get();
        for (var doc in coupons.docs) {
          batch.delete(doc.reference);
          hasBatchWork = true;
        }

        // Delete esnaf users of this company
        final esnafUsers = await FirebaseFirestore.instance
            .collection('esnaf_users')
            .where('companyId', isEqualTo: docId)
            .get();
        for (var doc in esnafUsers.docs) {
          batch.delete(doc.reference);
          hasBatchWork = true;
        }

        // Delete reviews of this company
        final reviews = await FirebaseFirestore.instance
            .collection('reviews')
            .where('targetId', isEqualTo: docId)
            .where('targetType', isEqualTo: 'company')
            .get();
        for (var doc in reviews.docs) {
          batch.delete(doc.reference);
          hasBatchWork = true;
        }
      } else if (widget.collection == 'gezilecek_yerler') {
        // Delete reviews of this place
        final reviews = await FirebaseFirestore.instance
            .collection('reviews')
            .where('targetId', isEqualTo: docId)
            .where('targetType', isEqualTo: 'place')
            .get();
        for (var doc in reviews.docs) {
          batch.delete(doc.reference);
          hasBatchWork = true;
        }
      }

      // Commit batch if there are related items to delete
      if (hasBatchWork) {
        await batch.commit();
        debugPrint('Cascading deletes completed for $docId');
      }

      // 2. Delete the document itself from Firestore
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
      BuildContext context, Function(Map<String, dynamic> companyData, String id) onSelect) {
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
                            onSelect(data, id);
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

  Widget _buildTimeListPicker(
      _FieldConfig field,
      Map<String, TextEditingController> allControllers,
      StateSetter setModalState) {
    final controller = allControllers[field.key]!;
    final times =
        controller.text.split(',').where((e) => e.trim().isNotEmpty).toList();
    times.sort();

    final inputController = TextEditingController();
    final focusNode = FocusNode();

    void addTime(String val) {
      if (val.isEmpty) return;
      
      // Basic validation and formatting (e.g. 8.30 -> 08:30)
      String formatted = val.replaceAll('.', ':').trim();
      if (formatted.contains(':')) {
        final parts = formatted.split(':');
        final h = parts[0].padLeft(2, '0');
        final m = parts.length > 1 ? parts[1].padLeft(2, '0') : '00';
        formatted = "$h:$m";
      } else if (formatted.length <= 2) {
        formatted = "${formatted.padLeft(2, '0')}:00";
      }

      if (!times.contains(formatted)) {
        setModalState(() {
          times.add(formatted);
          times.sort();
          controller.text = times.join(',');
        });
      }
      inputController.clear();
      focusNode.requestFocus();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(field.label,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            ),
            if (field.key == 'saatler_hergun')
              TextButton.icon(
                onPressed: () {
                  setModalState(() {
                    allControllers['saatler_haftaici']?.text = controller.text;
                    allControllers['saatler_cumartesi']?.text = controller.text;
                    allControllers['saatler_pazar']?.text = controller.text;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Tüm günlere kopyalandı')),
                  );
                },
                icon: const Icon(Icons.copy_all, size: 16),
                label: const Text('Tüm Günlere Kopyala', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (times.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('Henüz saat eklenmedi',
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                )
              else
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: times
                      .map((time) => Chip(
                            label: Text(time,
                                style: const TextStyle(
                                    fontSize: 11, fontWeight: FontWeight.w600)),
                            backgroundColor: AppColors.white,
                            padding: EdgeInsets.zero,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            deleteIcon: const Icon(Icons.close, size: 12),
                            onDeleted: () {
                              setModalState(() {
                                times.remove(time);
                                controller.text = times.join(',');
                              });
                            },
                          ))
                      .toList(),
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: inputController,
                      focusNode: focusNode,
                      decoration: InputDecoration(
                        hintText: 'Saat gir (Örn: 08:30 veya 08)',
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      keyboardType: TextInputType.datetime,
                      onSubmitted: (val) => addTime(val),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: () => addTime(inputController.text),
                    icon: const Icon(Icons.add),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.only(top: 4, left: 4),
                child: Text('Enter tuşu ile hızlıca ekleyebilirsiniz',
                    style: TextStyle(fontSize: 10, color: Colors.grey)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _AdminListItem extends StatelessWidget {
  final DocumentSnapshot doc;
  final int index;
  final String collection;
  final bool isReorderable;
  final Function(String, Map<String, dynamic>) onEdit;
  final Function(String, Map<String, dynamic>) onDelete;
  final Widget? Function(Map<String, dynamic>) subtitleBuilder;

  const _AdminListItem({
    super.key,
    required this.doc,
    required this.index,
    required this.collection,
    required this.isReorderable,
    required this.onEdit,
    required this.onDelete,
    required this.subtitleBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final data = doc.data() as Map<String, dynamic>;
    final name = data['ad'] as String? ??
        data['title'] as String? ??
        data['baslik'] as String? ??
        data['ad_soyad'] as String? ??
        data['companyName'] as String? ??
        data['userName'] as String? ??
        data['name'] as String? ??
        data['guzergah'] as String? ??
        'İsimsiz';
    
    final imageUrl = data['image_url'] as String? ?? data['gorsel'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: CachedImageWidget(
          imageUrl: imageUrl,
          width: 50,
          height: 50,
          borderRadius: 10,
        ),
        title: Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: subtitleBuilder(data),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.grey),
              onSelected: (value) {
                if (value == 'edit') onEdit(doc.id, data);
                else if (value == 'delete') onDelete(doc.id, data);
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Text('Düzenle')),
                const PopupMenuItem(value: 'delete', child: Text('Sil')),
              ],
            ),
            if (isReorderable)
              ReorderableDragStartListener(
                index: index,
                child: const Icon(Icons.drag_indicator, color: Colors.grey),
              ),
          ],
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
  final bool isTimeList;
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
    this.isTimeList = false,
    this.isBoolean = false,
    this.readOnly = false,
    this.defaultValue,
  });
}
