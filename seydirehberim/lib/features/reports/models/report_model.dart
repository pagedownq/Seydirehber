import 'package:cloud_firestore/cloud_firestore.dart';

enum ReportCategory {
  roadFault('yol_arizasi', 'Altyapı/Yol Arızası', '🛠️'),
  roadClosed('yol_kapali', 'Kapalı Yol', '🚫'),
  accident('kaza', 'Trafik Kazası', '💥'),
  waterCut('su_kesintisi', 'Su Kesintisi', '💧'),
  other('diger', 'Diğer', '⚠️');

  final String value;
  final String label;
  final String emoji;

  const ReportCategory(this.value, this.label, this.emoji);

  static ReportCategory fromValue(String value) {
    return ReportCategory.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ReportCategory.other,
    );
  }
}

class TrafficReport {
  final String id;
  final String userId;
  final String displayName;
  final String category; // 'yol_arizasi' | 'yol_kapali' | 'kaza' | 'diger'
  final String address;
  final String description;
  final DateTime dateTime;
  final List<String> confirmedUserIds;
  final List<String> unconfirmedUserIds;
  final DateTime createdAt;

  const TrafficReport({
    required this.id,
    required this.userId,
    required this.displayName,
    required this.category,
    required this.address,
    required this.description,
    required this.dateTime,
    required this.confirmedUserIds,
    required this.unconfirmedUserIds,
    required this.createdAt,
  });

  ReportCategory get reportCategory => ReportCategory.fromValue(category);

  factory TrafficReport.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TrafficReport(
      id: doc.id,
      userId: data['user_id'] as String? ?? '',
      displayName: data['display_name'] as String? ?? 'Kullanıcı',
      category: data['category'] as String? ?? 'diger',
      address: data['address'] as String? ?? '',
      description: data['description'] as String? ?? '',
      dateTime: (data['date_time'] as Timestamp?)?.toDate() ?? DateTime.now(),
      confirmedUserIds: List<String>.from(data['confirmed_user_ids'] as List? ?? []),
      unconfirmedUserIds: List<String>.from(data['unconfirmed_user_ids'] as List? ?? []),
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'display_name': displayName,
      'category': category,
      'address': address,
      'description': description,
      'date_time': Timestamp.fromDate(dateTime),
      'confirmed_user_ids': confirmedUserIds,
      'unconfirmed_user_ids': unconfirmedUserIds,
      'created_at': FieldValue.serverTimestamp(),
    };
  }
}
