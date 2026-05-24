import 'package:cloud_firestore/cloud_firestore.dart';

class ForumPost {
  final String id;
  final String userId;
  final String displayName;
  final String? photoUrl;
  final bool isAnonymous;
  final String title;
  final String content;
  final String category; // 'soru' | 'tavsiye' | 'etkinlik' | 'genel'
  final int replyCount;
  final int reportCount;
  final bool isHidden;
  final List<String> reporterIds;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isEdited;
  final List<String> helpfulVoterIds;
  final List<String> unhelpfulVoterIds;

  const ForumPost({
    required this.id,
    required this.userId,
    required this.displayName,
    this.photoUrl,
    required this.isAnonymous,
    required this.title,
    required this.content,
    required this.category,
    required this.replyCount,
    required this.reportCount,
    required this.isHidden,
    required this.reporterIds,
    required this.createdAt,
    required this.updatedAt,
    this.isEdited = false,
    this.helpfulVoterIds = const [],
    this.unhelpfulVoterIds = const [],
  });

  /// Kullanıcı arayüzünde gösterilecek isim
  /// Anonim ise "Anonim Kullanıcı", değilse gerçek isim
  String get publicDisplayName =>
      isAnonymous ? 'Anonim Kullanıcı' : displayName;

  factory ForumPost.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ForumPost(
      id: doc.id,
      userId: data['user_id'] as String? ?? '',
      displayName: data['display_name'] as String? ?? 'Kullanıcı',
      photoUrl: data['photo_url'] as String?,
      isAnonymous: data['is_anonymous'] as bool? ?? false,
      title: data['title'] as String? ?? '',
      content: data['content'] as String? ?? '',
      category: data['category'] as String? ?? 'genel',
      replyCount: (data['reply_count'] as num?)?.toInt() ?? 0,
      reportCount: (data['report_count'] as num?)?.toInt() ?? 0,
      isHidden: data['is_hidden'] as bool? ?? false,
      reporterIds: List<String>.from(data['reporter_ids'] as List? ?? []),
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updated_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isEdited: data['is_edited'] as bool? ?? false,
      helpfulVoterIds: List<String>.from(data['helpful_voter_ids'] as List? ?? []),
      unhelpfulVoterIds: List<String>.from(data['unhelpful_voter_ids'] as List? ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'display_name': displayName,
      'photo_url': photoUrl,
      'is_anonymous': isAnonymous,
      'title': title,
      'content': content,
      'category': category,
      'reply_count': replyCount,
      'report_count': reportCount,
      'is_hidden': isHidden,
      'reporter_ids': reporterIds,
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
      'is_edited': isEdited,
      'helpful_voter_ids': helpfulVoterIds,
      'unhelpful_voter_ids': unhelpfulVoterIds,
    };
  }
}

/// Forum kategorileri
enum ForumCategory {
  all('tumu', 'Tümü', '📋'),
  genel('genel', 'Genel', '💬'),
  soru('soru', 'Soru', '❓'),
  tavsiye('tavsiye', 'Tavsiye', '💡'),
  etkinlik('etkinlik', 'Etkinlik', '📅');

  final String value;
  final String label;
  final String emoji;

  const ForumCategory(this.value, this.label, this.emoji);
}
