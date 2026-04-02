import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/app_notification.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class AdminNotificationsScreen extends StatefulWidget {
  const AdminNotificationsScreen({super.key});

  @override
  State<AdminNotificationsScreen> createState() => _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState extends State<AdminNotificationsScreen> {
  final _firestore = FirebaseFirestore.instance;
  bool _isSending = false;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }


  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  // Service Account JSON
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

  Future<void> _sendFCMBroadcast(String baslik, String icerik) async {
    setState(() => _isSending = true);
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
            'topic': 'all',
            'notification': {
              'title': baslik,
              'body': icerik,
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
              'id': '1',
              'status': 'done',
            },
          },
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('FCM Error ${response.statusCode}: ${response.body}');
      }
    } finally {
      setState(() => _isSending = false);
    }
  }

  void _showAddNotificationDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            top: 24,
            left: 24,
            right: 24,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
              const SizedBox(height: 24),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.send_rounded, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Yeni Bildirim Gönder',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Bildirim Başlığı',
                  hintText: 'Örn: Yeni Etkinlik Duyurusu',
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey[200]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey[200]!),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _bodyController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Bildirim İçeriği',
                  hintText: 'Bildirim metnini buraya yazın...',
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey[200]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey[200]!),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isSending ? null : () async {
                  if (_titleController.text.isEmpty || _bodyController.text.isEmpty) {
                    AppNotification.error(context, 'Lütfen tüm alanları doldurun!');
                    return;
                  }

                  try {
                    // 1. Send via FCM API
                    await _sendFCMBroadcast(_titleController.text, _bodyController.text);

                    // 2. Save to history
                    await _firestore.collection('duyurular').add({
                      'baslik': _titleController.text,
                      'icerik': _bodyController.text,
                      'tarih': FieldValue.serverTimestamp(),
                    });

                    if (context.mounted) {
                      _titleController.clear();
                      _bodyController.clear();
                      Navigator.pop(context);
                      AppNotification.success(context, 'Bildirim başarıyla tüm kullanıcılara gönderildi!');
                    }
                  } catch (e) {
                    if (context.mounted) {
                      AppNotification.error(context, 'Hata oluştu: $e');
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isSending 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Şimdi Tüm Cihazlara Gönder', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Bildirim Yönetimi'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('duyurular')
            .orderBy('tarih', descending: true)
            .limit(20)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Hata: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final notifications = snapshot.data?.docs ?? [];

          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Henüz gönderilmiş bildirim yok.',
                    style: TextStyle(color: Colors.grey[500], fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(Icons.history, size: 18, color: Colors.amber[700]),
                    const SizedBox(width: 8),
                    Text(
                      'Bildirim Geçmişi (Son 20)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final doc = notifications[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final tarih = (data['tarih'] as Timestamp?)?.toDate();

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Theme(
                          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                          child: ExpansionTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.amber[50],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(Icons.notifications_active_outlined, color: Colors.amber[700], size: 20),
                            ),
                            title: Text(
                              data['baslik'] ?? 'Başlıksız',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            subtitle: tarih != null 
                              ? Text(
                                  DateFormat('dd.MM.yyyy HH:mm').format(tarih),
                                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                                )
                              : null,
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 22),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Sil?'),
                                    content: const Text('Bu bildirim kaydını geçmişten silmek istediğinize emin misiniz?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, false),
                                        child: const Text('İptal'),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, true),
                                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                                        child: const Text('Sil'),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirm == true) {
                                  await doc.reference.delete();
                                }
                              },
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    data['icerik'] ?? '',
                                    style: TextStyle(color: Colors.grey[800], height: 1.5),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddNotificationDialog,
        backgroundColor: AppColors.primary,
        elevation: 4,
        icon: const Icon(Icons.send_rounded, color: Colors.white),
        label: const Text(
          'Yeni Gönder', 
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
        ),
      ),
    );
  }
}
