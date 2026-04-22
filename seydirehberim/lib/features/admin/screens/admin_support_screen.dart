import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AdminSupportScreen extends StatefulWidget {
  const AdminSupportScreen({super.key});

  @override
  State<AdminSupportScreen> createState() => _AdminSupportScreenState();
}

class _AdminSupportScreenState extends State<AdminSupportScreen> {
  // Service Account JSON - Loaded from .env for security
  Map<String, dynamic> get _serviceAccount => {
    "type": "service_account",
    "project_id": dotenv.env['FIREBASE_PROJECT_ID'],
    "private_key_id": dotenv.env['FIREBASE_PRIVATE_KEY_ID'],
    "private_key": (dotenv.env['FIREBASE_PRIVATE_KEY'] ?? "").replaceAll("\\n", "\n"),
    "client_email": dotenv.env['FIREBASE_CLIENT_EMAIL'],
    "client_id": dotenv.env['FIREBASE_CLIENT_ID'],
    "auth_uri": "https://accounts.google.com/o/oauth2/auth",
    "token_uri": "https://oauth2.googleapis.com/token",
    "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
    "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/${dotenv.env['FIREBASE_CLIENT_EMAIL']?.replaceAll("@", "%40")}",
    "universe_domain": "googleapis.com"
  };

  Future<String> _getAccessToken() async {
    final account = auth.ServiceAccountCredentials.fromJson(_serviceAccount);
    final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];
    final client = await auth.clientViaServiceAccount(account, scopes);
    final credentials = client.credentials;
    return credentials.accessToken.data;
  }

  Future<void> _sendTargetedFCM(String token, String title, String body) async {
    try {
      final accessToken = await _getAccessToken();
      final projectId = _serviceAccount['project_id'];
      final url = 'https://fcm.googleapis.com/v1/projects/$projectId/messages:send';

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({
          'message': {
            'token': token,
            'notification': {
              'title': title,
              'body': body,
            },
            'android': {
              'priority': 'high',
              'notification': {
                'channel_id': 'seydirehberim_notifications',
                'icon': 'ic_stat_s',
                'click_action': 'FLUTTER_NOTIFICATION_CLICK',
              },
            },
            'apns': {
              'headers': {
                'apns-priority': '10',
                'apns-push-type': 'alert',
              },
              'payload': {
                'aps': {
                  'sound': 'default',
                  'badge': 1,
                  'content-available': 1,
                  'mutable-content': 1,
                },
              },
            },
            'data': {
              'click_action': 'FLUTTER_NOTIFICATION_CLICK',
              'status': 'done',
            },
          },
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('FCM Hatası: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('FCM Targeted Error: $e');
    }
  }

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
                          if (data['telefon'] != null && (data['telefon'] as String).isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.phone, size: 18, color: AppColors.textLight),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(data['telefon'] as String, style: AppTextStyles.bodySmall),
                                ),
                              ],
                            ),
                          ],
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
                                  try {
                                    await FirebaseFirestore.instance
                                        .collection('yardim_destek')
                                        .doc(id)
                                        .update({'durum': value ? 'Çözüldü' : 'Bekliyor'});

                                    if (value && context.mounted) {
                                      final token = data['fcm_token'];
                                      if (token != null && token.toString().isNotEmpty) {
                                        await _sendTargetedFCM(
                                          token.toString(),
                                          'Destek Talebiniz Çözüldü ✅',
                                          '${data['kategori']} konulu destek talebiniz başarıyla çözülmüştür. Teşekkürler!',
                                        );
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Kullanıcıya bildirim gönderildi.'), backgroundColor: Colors.green),
                                          );
                                        }
                                      } else {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Bu mesajın bildirim anahtarı (Token) bulunamadı. (Eski bir kayıt olabilir)'), backgroundColor: Colors.orange),
                                          );
                                        }
                                      }
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
                                      );
                                    }
                                  }
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
