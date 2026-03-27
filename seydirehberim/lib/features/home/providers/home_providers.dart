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

// Companies - last 5
final latestCompaniesProvider = StreamProvider((ref) {
  return ref
      .watch(firestoreProvider)
      .collection('firmalar')
      .orderBy('created_at', descending: true)
      .limit(5)
      .snapshots();
});

// All companies
final allCompaniesProvider = StreamProvider((ref) {
  return ref
      .watch(firestoreProvider)
      .collection('firmalar')
      .orderBy('created_at', descending: true)
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
