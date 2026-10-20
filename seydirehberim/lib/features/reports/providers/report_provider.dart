import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/report_model.dart';
import '../../auth/providers/auth_provider.dart';

final activeReportsProvider = StreamProvider<List<TrafficReport>>((ref) {
  return FirebaseFirestore.instance
      .collection('traffic_reports')
      .snapshots()
      .map((snapshot) {
        final now = DateTime.now();
        final threshold = now.subtract(const Duration(hours: 24));
        
        final reports = snapshot.docs
            .map((doc) => TrafficReport.fromDoc(doc))
            .where((report) => report.createdAt.isAfter(threshold))
            .toList();
            
        // Sort descending by createdAt
        reports.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return reports;
      });
});

final reportOperationsProvider = Provider((ref) => ReportOperations(ref));

class ReportOperations {
  final Ref ref;

  ReportOperations(this.ref);

  Future<void> createReport({
    required String category,
    required String address,
    required String description,
    required DateTime dateTime,
  }) async {
    final user = ref.read(authStateProvider).value;
    if (user == null) throw Exception('Giriş yapmanız gerekmektedir.');

    final report = {
      'user_id': user.uid,
      'display_name': user.displayName ?? 'Kullanıcı',
      'category': category,
      'address': address,
      'description': description,
      'date_time': Timestamp.fromDate(dateTime),
      'confirmed_user_ids': <String>[],
      'unconfirmed_user_ids': <String>[],
      'created_at': FieldValue.serverTimestamp(),
    };

    await FirebaseFirestore.instance.collection('traffic_reports').add(report);
  }

  Future<void> toggleConfirmReport(String reportId) async {
    final user = ref.read(authStateProvider).value;
    if (user == null) throw Exception('Doğrulamak için giriş yapmanız gerekmektedir.');

    final docRef = FirebaseFirestore.instance.collection('traffic_reports').doc(reportId);
    
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) return;

      final data = snapshot.data() as Map<String, dynamic>;
      final confirmedIds = List<String>.from(data['confirmed_user_ids'] as List? ?? []);
      final unconfirmedIds = List<String>.from(data['unconfirmed_user_ids'] as List? ?? []);

      if (confirmedIds.contains(user.uid)) {
        confirmedIds.remove(user.uid);
      } else {
        confirmedIds.add(user.uid);
        unconfirmedIds.remove(user.uid); // Mutually exclusive
      }

      transaction.update(docRef, {
        'confirmed_user_ids': confirmedIds,
        'unconfirmed_user_ids': unconfirmedIds,
      });
    });
  }

  Future<void> toggleUnconfirmReport(String reportId) async {
    final user = ref.read(authStateProvider).value;
    if (user == null) throw Exception('Doğrulamak için giriş yapmanız gerekmektedir.');

    final docRef = FirebaseFirestore.instance.collection('traffic_reports').doc(reportId);
    
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) return;

      final data = snapshot.data() as Map<String, dynamic>;
      final confirmedIds = List<String>.from(data['confirmed_user_ids'] as List? ?? []);
      final unconfirmedIds = List<String>.from(data['unconfirmed_user_ids'] as List? ?? []);

      if (unconfirmedIds.contains(user.uid)) {
        unconfirmedIds.remove(user.uid);
      } else {
        unconfirmedIds.add(user.uid);
        confirmedIds.remove(user.uid); // Mutually exclusive
      }

      transaction.update(docRef, {
        'confirmed_user_ids': confirmedIds,
        'unconfirmed_user_ids': unconfirmedIds,
      });
    });
  }

  Future<void> deleteReport(String reportId) async {
    final user = ref.read(authStateProvider).value;
    if (user == null) throw Exception('Giriş yapmanız gerekmektedir.');

    await FirebaseFirestore.instance.collection('traffic_reports').doc(reportId).delete();
  }
}
