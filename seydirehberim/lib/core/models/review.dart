import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewReply {
  final String text;
  final DateTime createdAt;

  ReviewReply({
    required this.text,
    required this.createdAt,
  });

  factory ReviewReply.fromMap(Map<String, dynamic> map) {
    return ReviewReply(
      text: map['text'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

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
  final bool isEdited;
  final DateTime? updatedAt;
  final ReviewReply? reply;

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
    this.isEdited = false,
    this.updatedAt,
    this.reply,
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
      isEdited: data['isEdited'] ?? false,
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      reply: data['reply'] != null ? ReviewReply.fromMap(data['reply'] as Map<String, dynamic>) : null,
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
      'isEdited': isEdited,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'reply': reply?.toMap(),
    };
  }
}
