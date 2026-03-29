import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/review.dart';

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

  Future<void> deleteReview(String reviewId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Yorum silmek için giriş yapmalısınız.');
    
    // Safety check: Firestore rules will also handle this
    await _firestore.collection('reviews').doc(reviewId).delete();
  }
}
