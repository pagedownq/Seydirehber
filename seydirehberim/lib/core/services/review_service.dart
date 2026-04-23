import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/review.dart';
import '../utils/profanity_filter.dart';

final reviewServiceProvider = Provider((ref) => ReviewService());

final reviewsProvider = StreamProvider.autoDispose.family<List<Review>, String>((ref, targetId) {
  return ref.watch(reviewServiceProvider).getReviews(targetId);
});

final averageRatingProvider = StreamProvider.autoDispose.family<double, String>((ref, targetId) {
  return ref.watch(reviewServiceProvider).getAverageRating(targetId);
});

class ReviewService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<List<Review>> getReviews(String targetId) {
    return _firestore
        .collection('reviews')
        .where('targetId', isEqualTo: targetId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Review.fromFirestore(doc)).toList());
  }

  Stream<double> getAverageRating(String targetId) {
    return _firestore
        .collection('reviews')
        .where('targetId', isEqualTo: targetId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return 0.0;
      double totalRating = 0;
      for (var doc in snapshot.docs) {
        totalRating += (doc.data()['rating'] as num?)?.toDouble() ?? 0.0;
      }
      return totalRating / snapshot.docs.length;
    });
  }

  Future<void> addReview({
    required String targetId,
    required String targetType,
    required double rating,
    required String comment,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Yorum yapmak için giriş yapmalısınız.');

    // Kötü kelime kontrolü
    if (ProfanityFilter.hasProfanity(comment)) {
      throw 'PROFANITY_DETECTED';
    }

    final review = Review(
      id: '',
      targetId: targetId,
      targetType: targetType,
      userId: user.uid,
      userName: user.displayName ?? 'Misafir',
      userImageUrl: user.photoURL,
      rating: rating,
      comment: comment,
      createdAt: DateTime.now(),
    );

    // Add to reviews collection
    await _firestore.collection('reviews').add(review.toFirestore());

    // Update target document (place/company) with average rating and count (denormalization)
    // For now, we'll keep it simple and just add the review. 
    // In a production app, we would use a Cloud Function or a transaction to update the average.
  }

  Future<bool> hasUserReviewed(String targetId) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final snapshot = await _firestore
        .collection('reviews')
        .where('targetId', isEqualTo: targetId)
        .where('userId', isEqualTo: user.uid)
        .get();

    return snapshot.docs.isNotEmpty;
  }

  Future<void> updateReview({
    required String reviewId,
    required double rating,
    required String comment,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Yorum düzenlemek için giriş yapmalısınız.');

    // Kötü kelime kontrolü
    if (ProfanityFilter.hasProfanity(comment)) {
      throw 'PROFANITY_DETECTED';
    }

    await _firestore.collection('reviews').doc(reviewId).update({
      'rating': rating,
      'comment': comment,
      'isEdited': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteReview(String reviewId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Yorum silmek için giriş yapmalısınız.');
    
    // Safety check: Firestore rules will also handle this
    await _firestore.collection('reviews').doc(reviewId).delete();
  }

  Future<void> reportReview(Review review) async {
    if (review.id.isEmpty) {
      throw 'ERROR_INVALID_REVIEW_ID';
    }

    final user = _auth.currentUser;
    final reporterId = user?.uid ?? 'guest';

    // Misafir değilse mükerrer kontrolü yap
    if (reporterId != 'guest') {
      try {
        final existing = await _firestore
            .collection('sikayetler')
            .where('reviewId', isEqualTo: review.id)
            .where('reporterId', isEqualTo: reporterId)
            .limit(1)
            .get();

        if (existing.docs.isNotEmpty) {
          throw 'ALREADY_REPORTED';
        }
      } catch (e) {
        // Eğer zaten raporlandı hatasıysa fırlat, değilse (örn: yetki hatası) devam et
        if (e == 'ALREADY_REPORTED') rethrow;
        // ignore: avoid_print
        print('Şikayet kontrolünde hata (devam ediliyor): $e');
      }
    }

    await _firestore.collection('sikayetler').add({
      'reviewId': review.id,
      'reporterId': reporterId,
      'targetId': review.targetId,
      'targetType': review.targetType,
      'content': review.comment,
      'userName': review.userName,
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'pending',
    });
  }
}
