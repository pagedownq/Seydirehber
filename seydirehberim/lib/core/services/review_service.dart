import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
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
    final collection = targetType == 'company' ? 'firmalar' : 'gezilecek_yerler';
    final targetDoc = _firestore.collection(collection).doc(targetId);
    
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(targetDoc);
      if (snapshot.exists) {
        final data = snapshot.data()!;
        final double currentRating = (data['ortalama_puan'] as num?)?.toDouble() ?? 0.0;
        final int currentCount = (data['yorum_sayisi'] as num?)?.toInt() ?? 0;
        
        final int newCount = currentCount + 1;
        // Simple average calculation
        final double newRating = ((currentRating * currentCount) + rating) / newCount;
        
        transaction.update(targetDoc, {
          'ortalama_puan': newRating,
          'yorum_sayisi': newCount,
        });
      }
    }).catchError((e, stack) {
      debugPrint('Denormalization error: $e');
      return null;
    });
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
    
    // Get review data before deleting to update target stats
    final reviewDoc = await _firestore.collection('reviews').doc(reviewId).get();
    if (!reviewDoc.exists) return;
    
    final reviewData = reviewDoc.data()!;
    final String targetId = reviewData['targetId'];
    final String targetType = reviewData['targetType'];
    final double rating = (reviewData['rating'] as num).toDouble();

    // Delete the review
    await _firestore.collection('reviews').doc(reviewId).delete();

    // Update target document (denormalization)
    final collection = targetType == 'company' ? 'firmalar' : 'gezilecek_yerler';
    final targetDoc = _firestore.collection(collection).doc(targetId);
    
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(targetDoc);
      if (snapshot.exists) {
        final data = snapshot.data()!;
        final double currentRating = (data['ortalama_puan'] as num?)?.toDouble() ?? 0.0;
        final int currentCount = (data['yorum_sayisi'] as num?)?.toInt() ?? 0;
        
        if (currentCount > 1) {
          final int newCount = currentCount - 1;
          final double newRating = ((currentRating * currentCount) - rating) / newCount;
          transaction.update(targetDoc, {
            'ortalama_puan': newRating,
            'yorum_sayisi': newCount,
          });
        } else {
          transaction.update(targetDoc, {
            'ortalama_puan': 0.0,
            'yorum_sayisi': 0,
          });
        }
      }
    }).catchError((e, stack) {
      debugPrint('Denormalization delete error: $e');
      return null;
    });
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

  Future<void> syncAllReviewStats() async {
    final companies = await _firestore.collection('firmalar').get();
    final places = await _firestore.collection('gezilecek_yerler').get();
    
    final allTargets = [
      ...companies.docs.map((d) => {'id': d.id, 'collection': 'firmalar'}),
      ...places.docs.map((d) => {'id': d.id, 'collection': 'gezilecek_yerler'}),
    ];
    
    for (var target in allTargets) {
      final reviews = await _firestore
          .collection('reviews')
          .where('targetId', isEqualTo: target['id'])
          .get();
          
      if (reviews.docs.isNotEmpty) {
        double totalRating = 0;
        for (var doc in reviews.docs) {
          totalRating += (doc.data()['rating'] as num?)?.toDouble() ?? 0.0;
        }
        final double avg = totalRating / reviews.docs.length;
        
        await _firestore.collection(target['collection']! as String).doc(target['id']! as String).update({
          'ortalama_puan': avg,
          'yorum_sayisi': reviews.docs.length,
        });
      } else {
        await _firestore.collection(target['collection']! as String).doc(target['id']! as String).update({
          'ortalama_puan': 0.0,
          'yorum_sayisi': 0,
        });
      }
    }
  }
}
