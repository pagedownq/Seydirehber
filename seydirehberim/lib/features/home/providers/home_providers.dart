import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final firestoreProvider = Provider((ref) => FirebaseFirestore.instance);

// Events - last 5
final latestEventsProvider = StreamProvider((ref) {
  return ref
      .watch(firestoreProvider)
      .collection('etkinlikler')
      .orderBy('created_at', descending: true)
      .limit(5)
      .snapshots();
});

// All events
final allEventsProvider = StreamProvider((ref) {
  return ref
      .watch(firestoreProvider)
      .collection('etkinlikler')
      .orderBy('created_at', descending: true)
      .snapshots();
});

// Places - last 5
final latestPlacesProvider = StreamProvider((ref) {
  return ref
      .watch(firestoreProvider)
      .collection('gezilecek_yerler')
      .orderBy('created_at', descending: true)
      .limit(5)
      .snapshots();
});

// All places
final allPlacesProvider = StreamProvider((ref) {
  return ref
      .watch(firestoreProvider)
      .collection('gezilecek_yerler')
      .orderBy('created_at', descending: true)
      .snapshots();
});

// Companies - added in last 30 days (limit 10 for home)
final latestCompaniesProvider = StreamProvider((ref) {
  final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
  return ref
      .watch(firestoreProvider)
      .collection('firmalar')
      .where('created_at', isGreaterThanOrEqualTo: Timestamp.fromDate(thirtyDaysAgo))
      .orderBy('created_at', descending: true)
      .limit(10)
      .snapshots();
});

// All New Companies - added in last 30 days (no limit)
final allLatestCompaniesProvider = StreamProvider((ref) {
  final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
  return ref
      .watch(firestoreProvider)
      .collection('firmalar')
      .where('created_at', isGreaterThanOrEqualTo: Timestamp.fromDate(thirtyDaysAgo))
      .orderBy('created_at', descending: true)
      .snapshots();
});

// All companies - sorted alphabetically
final alphabeticalCompaniesProvider = StreamProvider((ref) {
  return ref
      .watch(firestoreProvider)
      .collection('firmalar')
      .orderBy('ad')
      .snapshots();
});

// All companies - sorted alphabetically
final allCompaniesProvider = StreamProvider((ref) {
  return ref
      .watch(firestoreProvider)
      .collection('firmalar')
      .orderBy('ad')
      .snapshots();
});

// Popular Companies - sorted by view count (limit 10 for home)
final popularCompaniesProvider = StreamProvider((ref) {
  return ref
      .watch(firestoreProvider)
      .collection('firmalar')
      .orderBy('goruntulenme', descending: true)
      .limit(10)
      .snapshots();
});

// All Popular Companies - sorted by view count (no limit)
final allPopularCompaniesProvider = StreamProvider((ref) {
  return ref
      .watch(firestoreProvider)
      .collection('firmalar')
      .orderBy('goruntulenme', descending: true)
      .snapshots();
});

// Noterler
final noterlerProvider = StreamProvider((ref) {
  return ref
      .watch(firestoreProvider)
      .collection('noterler')
      .snapshots();
});

// Pazarlar
final pazarlarProvider = StreamProvider((ref) {
  return ref
      .watch(firestoreProvider)
      .collection('pazarlar')
      .snapshots();
});

// Otobüs Saatleri
final otobusSaatleriProvider = StreamProvider((ref) {
  return ref
      .watch(firestoreProvider)
      .collection('otobus_saatleri')
      .snapshots();
});

// Banners from Supabase (stored as Firestore docs pointing to Supabase URLs)
final bannersProvider = StreamProvider((ref) {
  return ref
      .watch(firestoreProvider)
      .collection('banners')
      .orderBy('order')
      .snapshots();
});
