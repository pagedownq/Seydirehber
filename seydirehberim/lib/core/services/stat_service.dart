import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppStats {
  final int totalCount;
  final int activeToday;
  final int activeNow;
  final int guestCount;
  final int registeredCount;

  AppStats({
    required this.totalCount,
    required this.activeToday,
    required this.activeNow,
    required this.guestCount,
    required this.registeredCount,
  });
}

final statServiceProvider = Provider((ref) => StatService());

final appStatsProvider = StreamProvider<AppStats>((ref) {
  final service = ref.watch(statServiceProvider);
  return service.getStatsStream();
});

class StatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<AppStats> getStatsStream() {
    // We'll use snapshots of user_presence to get real-time updates of counts
    // This is more reliable as every user (even anonymous) has a record here.
    return _firestore.collection('user_presence').snapshots().map((snapshot) {
      final now = DateTime.now();
      final todayThreshold = now.subtract(const Duration(hours: 24));
      final onlineThreshold = now.subtract(const Duration(minutes: 5));

      int total = snapshot.docs.length;
      int today = 0;
      int online = 0;
      int guests = 0;
      int registered = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final lastSeen = (data['lastSeen'] as Timestamp?)?.toDate();
        final isAnon = data['isAnonymous'] as bool? ?? true;

        if (isAnon) {
          guests++;
        } else {
          registered++;
        }
        
        if (lastSeen != null) {
          if (lastSeen.isAfter(todayThreshold)) {
            today++;
          }
          if (lastSeen.isAfter(onlineThreshold)) {
            online++;
          }
        }
      }

      return AppStats(
        totalCount: total,
        activeToday: today,
        activeNow: online,
        guestCount: guests,
        registeredCount: registered,
      );
    });
  }

  Future<int> purgeInactiveTokens() async {
    final now = DateTime.now();
    final threshold = now.subtract(const Duration(days: 30));
    
    final snapshot = await _firestore.collection('user_tokens')
        .where('lastSeen', isLessThan: threshold)
        .get();
    
    int count = 0;
    final batch = _firestore.batch();
    
    for (var doc in snapshot.docs) {
      batch.delete(doc.reference);
      count++;
    }
    
    if (count > 0) {
      await batch.commit();
    }
    
    return count;
  }
}
