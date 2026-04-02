import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:http/http.dart' as http;
import 'dart:convert';

class AdminSupportScreen extends StatefulWidget {
  const AdminSupportScreen({super.key});

  @override
  State<AdminSupportScreen> createState() => _AdminSupportScreenState();
}

class _AdminSupportScreenState extends State<AdminSupportScreen> {
  // Service Account JSON for FCM
  final Map<String, dynamic> _serviceAccount = {
    "type": "service_account",
    "project_id": "seydirehber1",
    "private_key_id": "07e4f1a26e1f495331a8defe20f0902522646795",
    "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQDGKjw0dZlwIubk\nUsNgLWIuVkOGAM+FrkOwSDEGJkqtfA23yGXc5Jt+Z6ErrLo3RdOLr9csvdE0awbX\nII1qg5r+yS6g3UKozkHkMji34rm1bzjR656u6b3Le9IqZ1lJlvN0EgW6tFI3b8YW\nou3UkhY3BvIW3BMCzw2srEeyBtDM3XXuzlIXGM7sfgpwQuwJ1bFGb5n7yqbeXIlt\nGLUzIIlJu2HHwRbe9cA6Z+pDoMp7K4BPqhYjVG53DEyEVbghy11M0OnBibmSDpaJ\nauZD4FNhj190S4f2/E0+dBTexuvDNOEozNIpAsfCXrQsfx1ySGaCFfGW5ZwqgNWQ\ntKLwCr25AgMBAAECggEAWUf4Hg6J1frzmhUrz25DGOtmur4swWb1OjwcUk/4P1dv\n+siAFFivMfFQrRPCRlrgZ8QOpyrSUdKSn2QcMswejgJoTrPBb7qV91ElOrwcvYDh\n0bpdoSLQjxg3ZUFw+fXXtAjWqfrKPA3Q6qv3iVlURvCLK/91VUOiPpTULIJjmpi0\nVuzdArOGJ+TtSAsw5WErwMeRtnYGksae8kmZi2BfhSBwHdRcGD/6+RLZ2rKKZju2\n4lTr9wRWaWQxn9XZKFJizTcLJG8mNTgo58mViOH3A6dfUtLv2p+2Yce5wg0v1QRf\nHv5uFdM8G/pfck7u40RlNmQ9IElGUZtTcDNyvm69PQKBgQD8uR+0y2uZuU1V+srD\nmhAVsl1ELiEVFB9U67USMwKqOpJ1CyeIwoVKLqQL1VSRn/E6rT25v0FBJQs9/7qG\nPvjG4/6M38jU6cy7KujVFYSJM5DtXCWxDyqGvVUY+Znp7B6Xdv/1hZN8TD4X1Gxr\nVoZQUmlR4HypcBmo9Xk2Vme8IwKBgQDIvAOHfofFmH+0aDeruND7Tf0tEAii1kV6\njSiLEkW+5dJPHP01iGOi3pq9JohQMHqjJiYUPUzG6YrXOGR+5oLmdGOOhbW861e/\nZm2hCfLiHvTtGl+uF0HGWkuzBonfdjTUyOAFnpOmFmFLTKJLtrBr8X9jSVrWNqOT\n9Q38LUh+cwKBgA8lqVjUuGZGTPRSS8TdfwlN33kuqpzwz8/vMLMei5JYYF7ThFMW\nFZcUpJBxANiZlYPGzmRLqkWVSs80fKF/NLn3AFLBNvBL8xFkyP+8gm0WwiD33Op3\n1jytLGSK0UbL+Clr4Ht+vhA9IZucB8OHNBWsWtOleNNO/Lq7u8Ad/amxAoGBAKI7\nAYcyBbz2gM9nIwcP+SYBY8pVmQUxszlWeBvdiqy7xPrXbPUk45Gv4tNYHvbgF11f\n6YqV+EUSXnmOQ/ojhkuGaSe4fKbQdTxlJdju13NUnZI6rHVgqnIKa/+mGyuUtyH5\nrsQb4yxqDfvzVX9niLHUnaW6lUVnJ1DezoyudFZtAoGANhfTDAa1WAbPo485NlZ9\nJcOZPME6MbSa0mL915CWJBiPxUlOtOeHK1BOy5rSfiJyNlW6u9+K6+qFut/+Kaf+\nuQhJBMlrQi4Xm2tCLHGE7SUbVwPijnrptQo8yLR34WnBcEmlSaAhULH3rKGLdVVO\neL1KMmQ4hTLu8dg0SWYKPvo=\n-----END PRIVATE KEY-----\n",
    "client_email": "firebase-adminsdk-fbsvc@seydirehber1.iam.gserviceaccount.com",
    "client_id": "114421894276322709926",
    "auth_uri": "https://accounts.google.com/o/oauth2/auth",
    "token_uri": "https://oauth2.googleapis.com/token",
    "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
    "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-fbsvc%40seydirehber1.iam.gserviceaccount.com",
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
