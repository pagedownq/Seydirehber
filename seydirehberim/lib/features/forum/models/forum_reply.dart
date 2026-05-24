import 'package:cloud_firestore/cloud_firestore.dart';

class ForumReply {
  final String id;
  final String postId;
  final String userId;
  final String displayName;
  final String? photoUrl;
  final bool isAnonymous;
  final String content;
  final int reportCount;
  final bool isHidden;
  final List<String> reporterIds;
  final DateTime createdAt;
  final bool isEdited;

  const ForumReply({
    required this.id,
    required this.postId,
    required this.userId,
    required this.displayName,
    this.photoUrl,
    required this.isAnonymous,
    required this.content,
    required this.reportCount,
    required this.isHidden,
    required this.reporterIds,
    required this.createdAt,
    this.isEdited = false,
  });

  /// Kullanıcı arayüzünde gösterilecek isim
  String get publicDisplayName =>
      isAnonymous ? 'Anonim Kullanıcı' : displayName;

  factory ForumReply.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ForumReply(
      id: doc.id,
      postId: data['post_id'] as String? ?? '',
      userId: data['user_id'] as String? ?? '',
      displayName: data['display_name'] as String? ?? 'Kullanıcı',
      photoUrl: data['photo_url'] as String?,
      isAnonymous: data['is_anonymous'] as bool? ?? false,
      content: data['content'] as String? ?? '',
      reportCount: (data['report_count'] as num?)?.toInt() ?? 0,
      isHidden: data['is_hidden'] as bool? ?? false,
      reporterIds: List<String>.from(data['reporter_ids'] as List? ?? []),
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isEdited: data['is_edited'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'post_id': postId,
      'user_id': userId,
      'display_name': displayName,
      'photo_url': photoUrl,
      'is_anonymous': isAnonymous,
      'content': content,
      'report_count': reportCount,
      'is_hidden': isHidden,
      'reporter_ids': reporterIds,
      'created_at': FieldValue.serverTimestamp(),
      'is_edited': isEdited,
    };
  }
}
