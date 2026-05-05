import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final firestoreProvider = Provider((ref) => FirebaseFirestore.instance);

// Typed alias for the list of documents we'll be using everywhere
typedef FirestoreDocs = List<QueryDocumentSnapshot<Map<String, dynamic>>>;

// Events - last 5 (now sorted by actual event date, and filtered for expired events)
final latestEventsProvider = StreamProvider<FirestoreDocs>((ref) {
  return ref
      .watch(allEventsProvider.stream)
      .map((docs) => docs.take(5).toList());
});

// All events - Sorted by event date and auto-cleans expired ones
final allEventsProvider = StreamProvider<FirestoreDocs>((ref) {
  return ref
      .watch(firestoreProvider)
      .collection('etkinlikler')
      .snapshots()
      .map((snapshot) {
    final now = DateTime.now();
    // Silme sınırı: Bugünün başlangıcı (00:00). 
    // Böylece dünü tamamlamış tüm etkinlikler temizlenir.
    final cleanupThreshold = DateTime(now.year, now.month, now.day);

    final docs = snapshot.docs.where((doc) {
      final data = doc.data();
      // Use end date if exists, otherwise use start date
      final expiry = data['bitis_tarihi_str'] ?? data['baslangic_tarihi_str'];

      if (expiry is Timestamp) {
        final expiryDate = expiry.toDate();
        // Eğer bitiş tarihi, bugünün başlangıcından (00:00) önceyse silme işlemini yap
        if (expiryDate.isBefore(cleanupThreshold)) {
          // EXPIRED! 
          // Attempt to delete from DB (only works if user is Admin)
          doc.reference.delete().catchError((_) {}); 
          return false;
        }
      }
      return true;
    }).toList();

    // Sort by event start date (closest to now first)
    docs.sort((a, b) {
      final aData = a.data();
      final bData = b.data();
      final aDate = aData['baslangic_tarihi_str'] ?? aData['baslangic_tarihi'];
      final bDate = bData['baslangic_tarihi_str'] ?? bData['baslangic_tarihi'];

      if (aDate is Timestamp && bDate is Timestamp) {
        return aDate.compareTo(bDate);
      }
      return 0;
    });

    return docs;
  });
});

// Places - last 5
final latestPlacesProvider = StreamProvider<FirestoreDocs>((ref) {
  return ref
      .watch(allPlacesProvider.stream)
      .map((docs) => docs.take(5).toList());
});

// All places
final allPlacesProvider = StreamProvider<FirestoreDocs>((ref) {
  return ref
      .watch(firestoreProvider)
      .collection('gezilecek_yerler')
      .snapshots()
      .map((snapshot) {
    final docs = snapshot.docs.toList();
    docs.sort((a, b) {
      final aData = a.data();
      final bData = b.data();
      final aOrderVal = aData['order'];
      final bOrderVal = bData['order'];
      final num aOrder = num.tryParse(aOrderVal?.toString() ?? '') ?? 999999;
      final num bOrder = num.tryParse(bOrderVal?.toString() ?? '') ?? 999999;
      
      final int orderComparison = aOrder.compareTo(bOrder);
      if (orderComparison != 0) return orderComparison;
      
      final String aName = (aData['ad'] ?? '').toString().toLowerCase();
      final String bName = (bData['ad'] ?? '').toString().toLowerCase();
      return aName.compareTo(bName);
    });
    return docs;
  });
});

// Companies - added in last 30 days (limit 10 for home)
final latestCompaniesProvider = StreamProvider<FirestoreDocs>((ref) {
  final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
  return ref
      .watch(firestoreProvider)
      .collection('firmalar')
      .where('created_at', isGreaterThanOrEqualTo: Timestamp.fromDate(thirtyDaysAgo))
      .orderBy('created_at', descending: true)
      .limit(10)
      .snapshots()
      .map((s) => s.docs);
});

// All New Companies - added in last 30 days (no limit)
final allLatestCompaniesProvider = StreamProvider<FirestoreDocs>((ref) {
  final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
  return ref
      .watch(firestoreProvider)
      .collection('firmalar')
      .where('created_at', isGreaterThanOrEqualTo: Timestamp.fromDate(thirtyDaysAgo))
      .orderBy('created_at', descending: true)
      .snapshots()
      .map((s) => s.docs);
});

// All companies - locally sorted to handle missing 'order' fields gracefully
final alphabeticalCompaniesProvider = StreamProvider<FirestoreDocs>((ref) {
  return ref
      .watch(firestoreProvider)
      .collection('firmalar')
      .snapshots()
      .map((snapshot) {
    final docs = snapshot.docs.toList();
    docs.sort((a, b) {
      final aData = a.data();
      final bData = b.data();
      final aOrderVal = aData['order'];
      final bOrderVal = bData['order'];
      final num aOrder = num.tryParse(aOrderVal?.toString() ?? '') ?? 999999;
      final num bOrder = num.tryParse(bOrderVal?.toString() ?? '') ?? 999999;
      
      final int orderComparison = aOrder.compareTo(bOrder);
      if (orderComparison != 0) return orderComparison;
      
      final String aName = (aData['ad'] ?? '').toString().toLowerCase();
      final String bName = (bData['ad'] ?? '').toString().toLowerCase();
      return aName.compareTo(bName);
    });
    return docs;
  });
});

// Top 5 companies for home screen - locally sorted
final topFiveCompaniesProvider = StreamProvider<FirestoreDocs>((ref) {
  return ref
    .watch(alphabeticalCompaniesProvider.stream)
    .map((docs) => docs.take(5).toList());
});

// All companies - using the same provider logic
final allCompaniesProvider = alphabeticalCompaniesProvider;

// Popular Companies - sorted by view count (limit 10 for home)
final popularCompaniesProvider = StreamProvider<FirestoreDocs>((ref) {
  return ref
      .watch(firestoreProvider)
      .collection('firmalar')
      .orderBy('goruntulenme', descending: true)
      .limit(10)
      .snapshots()
      .map((s) => s.docs);
});

// All Popular Companies - sorted by view count (no limit)
final allPopularCompaniesProvider = StreamProvider<FirestoreDocs>((ref) {
  return ref
      .watch(firestoreProvider)
      .collection('firmalar')
      .orderBy('goruntulenme', descending: true)
      .snapshots()
      .map((s) => s.docs);
});

// Top Rated Companies - sorted by review count (limit 10 for home)
final topRatedCompaniesProvider = StreamProvider<FirestoreDocs>((ref) {
  return ref
      .watch(firestoreProvider)
      .collection('firmalar')
      .where('yorum_sayisi', isGreaterThan: 0)
      .orderBy('yorum_sayisi', descending: true)
      .limit(10)
      .snapshots()
      .map((s) => s.docs);
});

// All Top Rated Companies - sorted by review count (no limit)
final allTopRatedCompaniesProvider = StreamProvider<FirestoreDocs>((ref) {
  return ref
      .watch(firestoreProvider)
      .collection('firmalar')
      .where('yorum_sayisi', isGreaterThan: 0)
      .orderBy('yorum_sayisi', descending: true)
      .snapshots()
      .map((s) => s.docs);
});

// Noterler
final noterlerProvider = StreamProvider<FirestoreDocs>((ref) {
  return ref
      .watch(firestoreProvider)
      .collection('noterler')
      .snapshots()
      .map((s) => s.docs);
});

// Pazarlar
final pazarlarProvider = StreamProvider<FirestoreDocs>((ref) {
  return ref
      .watch(firestoreProvider)
      .collection('pazarlar')
      .snapshots()
      .map((s) => s.docs);
});

// Otobüs Saatleri
final otobusSaatleriProvider = StreamProvider<FirestoreDocs>((ref) {
  return ref
      .watch(firestoreProvider)
      .collection('otobus_saatleri')
      .snapshots()
      .map((snapshot) {
    final docs = snapshot.docs.toList();
    docs.sort((a, b) {
      final aData = a.data();
      final bData = b.data();
      final aOrderVal = aData['order'];
      final bOrderVal = bData['order'];
      final num aOrder = num.tryParse(aOrderVal?.toString() ?? '') ?? 999999;
      final num bOrder = num.tryParse(bOrderVal?.toString() ?? '') ?? 999999;
      
      final int orderComparison = aOrder.compareTo(bOrder);
      if (orderComparison != 0) return orderComparison;
      
      final String aName = (aData['guzergah'] ?? '').toString().toLowerCase();
      final String bName = (bData['guzergah'] ?? '').toString().toLowerCase();
      return aName.compareTo(bName);
    });
    return docs;
  });
});

// Banners from Supabase (stored as Firestore docs pointing to Supabase URLs)
final bannersProvider = StreamProvider<FirestoreDocs>((ref) {
  return ref
    .watch(firestoreProvider)
    .collection('banners')
    .snapshots(includeMetadataChanges: true)
    .map((snapshot) {
      final docs = snapshot.docs.toList();
      docs.sort((a, b) {
        final aOrderVal = (a.data())['order'];
        final bOrderVal = (b.data())['order'];
        final num aOrder = num.tryParse(aOrderVal?.toString() ?? '') ?? 999999;
        final num bOrder = num.tryParse(bOrderVal?.toString() ?? '') ?? 999999;
        return aOrder.compareTo(bOrder);
      });
      return docs;
    });
});

// Coupons - last 5
final latestCouponsProvider = StreamProvider<FirestoreDocs>((ref) {
  return ref
      .watch(firestoreProvider)
      .collection('coupons')
      .snapshots()
      .map((s) => s.docs);
});

// All Coupons
final allCouponsProvider = StreamProvider<FirestoreDocs>((ref) {
  return ref
      .watch(firestoreProvider)
      .collection('coupons')
      .snapshots()
      .map((s) => s.docs);
});
