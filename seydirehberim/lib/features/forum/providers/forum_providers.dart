import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/forum_post.dart';
import '../models/forum_reply.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/utils/profanity_filter.dart';
import '../../../core/services/block_service.dart';

final _firestore = FirebaseFirestore.instance;

// ─── Gönderi Listesi (Kategoriye göre filtre) ───────────────────────────────

/// Seçili kategori state'i (tümü dahil)
final forumCategoryProvider = StateProvider<ForumCategory>((ref) {
  return ForumCategory.all;
});

/// Arama sorgusu
final forumSearchQueryProvider = StateProvider<String>((ref) => '');

/// Engellenen Kullanıcılar ID listesi (Anında UI güncellenmesi için notifier)
class BlockedUsersNotifier extends StateNotifier<List<String>> {
  BlockedUsersNotifier() : super([]) {
    _load();
  }

  Future<void> _load() async {
    final list = await BlockService.getBlockedUsersList();
    state = list.map((u) => u.uid).toList();
  }

  Future<void> blockUser(String uid, String name, String? photoUrl) async {
    await BlockService.blockUser(uid, name: name, imageUrl: photoUrl);
    await _load();
  }

  Future<void> unblockUser(String uid) async {
    await BlockService.unblockUser(uid);
    await _load();
  }
}

final blockedUsersProvider = StateNotifierProvider<BlockedUsersNotifier, List<String>>((ref) {
  return BlockedUsersNotifier();
});

/// Tüm görünür gönderiler (is_hidden: false)
final forumPostsProvider = StreamProvider.autoDispose<List<ForumPost>>((ref) {
  final category = ref.watch(forumCategoryProvider);
  final searchQuery = ref.watch(forumSearchQueryProvider).trim().toLowerCase();

  Query<Map<String, dynamic>> query = _firestore
      .collection('forum_posts')
      .where('is_hidden', isEqualTo: false)
      .orderBy('created_at', descending: true);

  if (category != ForumCategory.all) {
    query = query.where('category', isEqualTo: category.value);
  }

  return query.snapshots().map(
        (snap) {
          final blockedIds = ref.watch(blockedUsersProvider);
          var posts = snap.docs.map(ForumPost.fromDoc).toList();
          
          // Engellenen kullanıcıların gönderilerini gizle
          if (blockedIds.isNotEmpty) {
            posts = posts.where((p) => !blockedIds.contains(p.userId)).toList();
          }

          if (searchQuery.isEmpty) return posts;
          
          return posts.where((post) {
            return post.title.toLowerCase().contains(searchQuery) ||
                   post.content.toLowerCase().contains(searchQuery);
          }).toList();
        },
      );
});

// ─── Gönderi Detayı ──────────────────────────────────────────────────────────

/// Tek bir gönderi
final forumPostProvider =
    StreamProvider.autoDispose.family<ForumPost?, String>((ref, postId) {
  return _firestore
      .collection('forum_posts')
      .doc(postId)
      .snapshots()
      .map((doc) => doc.exists ? ForumPost.fromDoc(doc) : null);
});

/// Kullanıcının Kendi Gönderileri
final myForumPostsProvider = StreamProvider.autoDispose<List<ForumPost>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value([]);

  return _firestore
      .collection('forum_posts')
      .where('user_id', isEqualTo: user.uid)
      .orderBy('created_at', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map(ForumPost.fromDoc).toList());
});

/// Gönderiye ait yanıtlar
final forumRepliesProvider =
    StreamProvider.autoDispose.family<List<ForumReply>, String>((ref, postId) {
  return _firestore
      .collection('forum_replies')
      .where('post_id', isEqualTo: postId)
      .where('is_hidden', isEqualTo: false)
      .orderBy('created_at', descending: false)
      .snapshots()
      .map((snap) {
        final blockedIds = ref.watch(blockedUsersProvider);
        var replies = snap.docs.map(ForumReply.fromDoc).toList();
        if (blockedIds.isNotEmpty) {
          replies = replies.where((r) => !blockedIds.contains(r.userId)).toList();
        }
        return replies;
      });
});

// ─── Admin Moderasyon ─────────────────────────────────────────────────────────

/// Admin: Gizlenmiş gönderiler (is_hidden: true, inceleme kuyruğu)
final hiddenForumPostsProvider =
    StreamProvider.autoDispose<List<ForumPost>>((ref) {
  return _firestore
      .collection('forum_posts')
      .where('is_hidden', isEqualTo: true)
      .orderBy('report_count', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map(ForumPost.fromDoc).toList());
});

/// Admin: Gizlenmiş yanıtlar
final hiddenForumRepliesProvider =
    StreamProvider.autoDispose<List<ForumReply>>((ref) {
  return _firestore
      .collection('forum_replies')
      .where('is_hidden', isEqualTo: true)
      .orderBy('report_count', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map(ForumReply.fromDoc).toList());
});

// ─── Forum Servisi ────────────────────────────────────────────────────────────

final forumServiceProvider = Provider<ForumService>((ref) => ForumService());

class ForumService {
  final _posts = _firestore.collection('forum_posts');
  final _replies = _firestore.collection('forum_replies');

  // ── Gönderi oluştur ──────────────────────────────────────────────────────

  Future<String> createPost({
    required String userId,
    required String displayName,
    String? photoUrl,
    required bool isAnonymous,
    required String title,
    required String content,
    required String category,
  }) async {
    final badWords = {
      ...ProfanityFilter.findProfanity(title),
      ...ProfanityFilter.findProfanity(content),
    }.toList();
    if (badWords.isNotEmpty) {
      throw 'Uygunsuz kelimeler tespit edildi: ${badWords.join(", ")}';
    }

    final docRef = await _posts.add({
      'user_id': userId,
      'display_name': displayName,
      'photo_url': photoUrl,
      'is_anonymous': isAnonymous,
      'title': title.trim(),
      'content': content.trim(),
      'category': category,
      'reply_count': 0,
      'report_count': 0,
      'is_hidden': false,
      'reporter_ids': [],
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  // ── Yanıt oluştur ────────────────────────────────────────────────────────

  Future<void> createReply({
    required String postId,
    required String userId,
    required String displayName,
    String? photoUrl,
    required bool isAnonymous,
    required String content,
  }) async {
    final badWords = ProfanityFilter.findProfanity(content);
    if (badWords.isNotEmpty) {
      throw 'Uygunsuz kelimeler tespit edildi: ${badWords.join(", ")}';
    }

    final batch = _firestore.batch();

    final replyRef = _replies.doc();
    batch.set(replyRef, {
      'post_id': postId,
      'user_id': userId,
      'display_name': displayName,
      'photo_url': photoUrl,
      'is_anonymous': isAnonymous,
      'content': content.trim(),
      'report_count': 0,
      'is_hidden': false,
      'reporter_ids': [],
      'created_at': FieldValue.serverTimestamp(),
    });

    // reply_count artır
    batch.update(_posts.doc(postId), {
      'reply_count': FieldValue.increment(1),
      'updated_at': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  // ── Gönderi Raporla ──────────────────────────────────────────────────────

  /// Returns true if report was accepted, false if already reported.
  Future<bool> reportPost({
    required String postId,
    required String reporterId,
  }) async {
    return _firestore.runTransaction<bool>((tx) async {
      final docRef = _posts.doc(postId);
      final snap = await tx.get(docRef);
      if (!snap.exists) return false;

      final data = snap.data()!;
      final reporterIds = List<String>.from(data['reporter_ids'] as List? ?? []);

      // Aynı kişi 2 kez raporlayamaz
      if (reporterIds.contains(reporterId)) return false;

      reporterIds.add(reporterId);
      final newCount = (data['report_count'] as num? ?? 0).toInt() + 1;
      final shouldHide = newCount >= 3;

      tx.update(docRef, {
        'reporter_ids': reporterIds,
        'report_count': newCount,
        if (shouldHide) 'is_hidden': true,
        'updated_at': FieldValue.serverTimestamp(),
      });
      return true;
    });
  }

  // ── Yanıt Raporla ────────────────────────────────────────────────────────

  Future<bool> reportReply({
    required String replyId,
    required String reporterId,
  }) async {
    return _firestore.runTransaction<bool>((tx) async {
      final docRef = _replies.doc(replyId);
      final snap = await tx.get(docRef);
      if (!snap.exists) return false;

      final data = snap.data()!;
      final reporterIds = List<String>.from(data['reporter_ids'] as List? ?? []);

      if (reporterIds.contains(reporterId)) return false;

      reporterIds.add(reporterId);
      final newCount = (data['report_count'] as num? ?? 0).toInt() + 1;
      final shouldHide = newCount >= 3;

      tx.update(docRef, {
        'reporter_ids': reporterIds,
        'report_count': newCount,
        if (shouldHide) 'is_hidden': true,
      });
      return true;
    });
  }

  // ── Admin: Gönderiyi Onayla (Geri Görünür Yap) ──────────────────────────

  Future<void> approvePost(String postId) async {
    await _posts.doc(postId).update({
      'is_hidden': false,
      'report_count': 0,
      'reporter_ids': [],
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  // ── Admin: Yanıtı Onayla ─────────────────────────────────────────────────

  Future<void> approveReply(String replyId) async {
    await _replies.doc(replyId).update({
      'is_hidden': false,
      'report_count': 0,
      'reporter_ids': [],
    });
  }

  // ── Admin: Gönderiyi Kalıcı Sil ─────────────────────────────────────────

  Future<void> deletePost(String postId) async {
    final batch = _firestore.batch();
    
    // Yanıtları da sil
    final replies = await _replies
        .where('post_id', isEqualTo: postId)
        .get();
    for (final doc in replies.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_posts.doc(postId));
    await batch.commit();
  }

  // ── Admin: Yanıtı Kalıcı Sil ─────────────────────────────────────────────

  Future<void> deleteReply({
    required String replyId,
    required String postId,
  }) async {
    final batch = _firestore.batch();
    batch.delete(_replies.doc(replyId));
    batch.update(_posts.doc(postId), {
      'reply_count': FieldValue.increment(-1),
    });
    await batch.commit();
  }

  // Kendi gönderisini silme
  Future<void> deleteOwnPost(String postId) async {
    await _posts.doc(postId).delete();
  }

  // Kendi yanıtını silme
  Future<void> deleteOwnReply(String replyId, String postId) async {
    final batch = _firestore.batch();
    batch.delete(_replies.doc(replyId));
    batch.update(_posts.doc(postId), {
      'reply_count': FieldValue.increment(-1),
    });
    await batch.commit();
  }

  // Kendi gönderisini düzenleme
  Future<void> editOwnPost({
    required String postId,
    required String newTitle,
    required String newContent,
    required String newCategory,
  }) async {
    final badWords = {
      ...ProfanityFilter.findProfanity(newTitle),
      ...ProfanityFilter.findProfanity(newContent),
    }.toList();
    if (badWords.isNotEmpty) {
      throw 'Uygunsuz kelimeler tespit edildi: ${badWords.join(", ")}';
    }

    await _posts.doc(postId).update({
      'title': newTitle.trim(),
      'content': newContent.trim(),
      'category': newCategory,
      'is_edited': true,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  // Kendi yanıtını düzenleme
  Future<void> editOwnReply({
    required String replyId,
    required String newContent,
  }) async {
    final badWords = ProfanityFilter.findProfanity(newContent);
    if (badWords.isNotEmpty) {
      throw 'Uygunsuz kelimeler tespit edildi: ${badWords.join(", ")}';
    }

    await _replies.doc(replyId).update({
      'content': newContent.trim(),
      'is_edited': true,
    });
  }

  // Gönderi değerlendirme (helpful/unhelpful)
  Future<void> votePost({
    required String postId,
    required String userId,
    required bool isHelpful,
  }) async {
    final docRef = _posts.doc(postId);
    
    // İşlem için transaction da kullanılabilir ama arrayUnion/Remove yeterli
    if (isHelpful) {
      await docRef.update({
        'helpful_voter_ids': FieldValue.arrayUnion([userId]),
        'unhelpful_voter_ids': FieldValue.arrayRemove([userId]),
      });
    } else {
      await docRef.update({
        'unhelpful_voter_ids': FieldValue.arrayUnion([userId]),
        'helpful_voter_ids': FieldValue.arrayRemove([userId]),
      });
    }
  }

  // Yanıt beğenme/beğeniyi geri alma
  Future<void> toggleLikeReply({
    required String replyId,
    required String userId,
    required bool isLiked,
  }) async {
    final docRef = _replies.doc(replyId);
    if (isLiked) {
      await docRef.update({
        'liked_user_ids': FieldValue.arrayRemove([userId]),
      });
    } else {
      await docRef.update({
        'liked_user_ids': FieldValue.arrayUnion([userId]),
      });
    }
  }
}
