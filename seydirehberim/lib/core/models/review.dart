import 'package:cloud_firestore/cloud_firestore.dart';

class Review {
  final String id;
  final String targetId;
  final String targetType; // 'place' or 'company'
  final String userId;
  final String userName;
  final String? userImageUrl;
  final double rating;
  final String comment;
  final DateTime createdAt;

  Review({
    required this.id,
    required this.targetId,
    required this.targetType,
    required this.userId,
    required this.userName,
    this.userImageUrl,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory Review.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Review(
      id: doc.id,
      targetId: data['targetId'] ?? '',
      targetType: data['targetType'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'İsimsiz Kullanıcı',
      userImageUrl: data['userImageUrl'],
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      comment: data['comment'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'targetId': targetId,
      'targetType': targetType,
      'userId': userId,
      'userName': userName,
      'userImageUrl': userImageUrl,
      'rating': rating,
      'comment': comment,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
