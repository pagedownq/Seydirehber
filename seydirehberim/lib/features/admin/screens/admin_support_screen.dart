import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

class AdminSupportScreen extends StatelessWidget {
  const AdminSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Yardım ve Destek Mesajları', style: AppTextStyles.appBarTitle),
        backgroundColor: AppColors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('yardim_destek')
            .orderBy('tarih', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Henüz mesaj yok'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final id = doc.id;
              
              final name = data['ad_soyad'] as String? ?? 'İsimsiz';
              final category = data['kategori'] as String? ?? 'Genel';
              final message = data['mesaj'] as String? ?? '';
              final email = data['email'] as String? ?? '';
              final status = data['durum'] as String? ?? 'Bekliyor';
              final timestamp = data['tarih'] as Timestamp?;
              
              final dateStr = timestamp != null 
                  ? DateFormat('dd.MM.yyyy HH:mm').format(timestamp.toDate())
                  : '';

              final isSolved = status == 'Çözüldü';

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                clipBehavior: Clip.antiAlias,
                elevation: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      color: isSolved ? AppColors.success.withOpacity(0.1) : AppColors.primary.withOpacity(0.1),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isSolved ? AppColors.success : AppColors.primary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              category.toUpperCase(),
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const Spacer(),
                          Text(dateStr, style: AppTextStyles.caption),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.person, size: 18, color: AppColors.textLight),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(name, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.email, size: 18, color: AppColors.textLight),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(email, style: AppTextStyles.bodySmall),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          Text(
                            message,
                            style: AppTextStyles.bodyMedium,
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Durum: $status',
                                style: TextStyle(
                                  color: isSolved ? AppColors.success : AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Switch.adaptive(
                                value: isSolved,
                                activeColor: AppColors.success,
                                onChanged: (value) async {
                                  await FirebaseFirestore.instance
                                      .collection('yardim_destek')
                                      .doc(id)
                                      .update({'durum': value ? 'Çözüldü' : 'Bekliyor'});
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
