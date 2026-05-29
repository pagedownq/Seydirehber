import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../core/services/log_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:crypto/crypto.dart';
import 'dart:math';
import 'dart:io';
import '../../../core/services/analytics_service.dart';

// Admin emails
const List<String> adminEmails = [
  'mehmetirem305@gmail.com',
  'bilgimgverse@gmail.com',
  'seydirehber@gmail.com'
];

// Auth state provider
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.userChanges();
});

// Onboarding completed check
final onboardingCompletedProvider = FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('onboarding_completed') ?? false;
});

// Is Admin check
final isAdminProvider = StreamProvider<bool>((ref) {
  return ref.watch(adminPermissionsProvider.stream).map((perms) => perms.isNotEmpty);
});

// Detailed Admin Permissions Provider
final adminPermissionsProvider = StreamProvider<Map<String, bool>>((ref) {
  final authState = ref.watch(authStateProvider).value;
  if (authState == null || authState.email == null || authState.email!.isEmpty) {
    return Stream.value({});
  }
  
  final email = authState.email!.toLowerCase();

  // 1. Check Hardcoded Super Admins
  if (adminEmails.contains(email)) {
    return Stream.value({
      'canManageBanners': true,
      'canManageEvents': true,
      'canManageNotaries': true,
      'canManageMarkets': true,
      'canManageBuses': true,
      'canManagePlaces': true,
      'canManageCompanies': true,
      'canManageSupport': true,
      'canManageReviews': true,
      'canManageReports': true,
      'canManageNotifications': true,
      'canManageEsnaf': true,
      'canManageCoupons': true,
      'canManageAdmins': true,
      'canManageForum': true,
      'canManageSurveys': true,
    });
  }

  // 2. Check Database Admins
  return FirebaseFirestore.instance
      .collection('admins')
      .doc(email)
      .snapshots()
      .map((doc) {
        if (!doc.exists || !(doc.data()?['isActive'] ?? false)) {
          return {};
        }
        
        final data = doc.data()!;
        return {
          'canManageBanners': data['canManageBanners'] ?? false,
          'canManageEvents': data['canManageEvents'] ?? false,
          'canManageNotaries': data['canManageNotaries'] ?? false,
          'canManageMarkets': data['canManageMarkets'] ?? false,
          'canManageBuses': data['canManageBuses'] ?? false,
          'canManagePlaces': data['canManagePlaces'] ?? false,
          'canManageCompanies': data['canManageCompanies'] ?? false,
          'canManageSupport': data['canManageSupport'] ?? false,
          'canManageReviews': data['canManageReviews'] ?? false,
          'canManageReports': data['canManageReports'] ?? false,
          'canManageNotifications': data['canManageNotifications'] ?? false,
          'canManageEsnaf': data['canManageEsnaf'] ?? false,
          'canManageCoupons': data['canManageCoupons'] ?? false,
          'canManageAdmins': data['canManageAdmins'] ?? false,
          'canManageForum': data['canManageForum'] ?? false,
          'canManageSurveys': data['canManageSurveys'] ?? false,
        };
      });
});

// Is Guest check
final isGuestProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.whenOrNull(
        data: (user) => user == null || user.isAnonymous,
      ) ??
      true;
});

// Auth Notifier
final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<User?>>((ref) {
  return AuthNotifier(ref);
});

class AuthNotifier extends StateNotifier<AsyncValue<User?>> {
  AuthNotifier(this.ref) : super(AsyncValue.data(FirebaseAuth.instance.currentUser)) {
    // Set initial user id if already logged in
    final user = _auth.currentUser;
    if (user != null) {
      ref.read(analyticsServiceProvider).setUserId(user.uid);
    }
  }

  final Ref ref;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<void> signInWithGoogle() async {
    try {
      state = const AsyncValue.loading();

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        state = const AsyncValue.data(null);
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      
      // Analytics
      ref.read(analyticsServiceProvider).logLogin('google');
      ref.read(analyticsServiceProvider).setUserId(userCredential.user?.uid);

      // Send welcome email if new user
      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        ref.read(analyticsServiceProvider).logSignUp('google');
        _sendWelcomeEmail(userCredential.user);
      }

      state = AsyncValue.data(userCredential.user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signInWithApple() async {
    try {
      state = const AsyncValue.loading();

      // Firebase Native Provider akışını kullanıyoruz.
      // Bu yöntem hem iOS hem Android'de (ve Web'de) en kararlı yöntemdir.
      LogService().log('Apple Sign-In süreci başlatıldı', type: LogType.info);
      final appleProvider = AppleAuthProvider();
      appleProvider.addScope('email');
      appleProvider.addScope('name');
      
      final UserCredential userCredential = await _auth.signInWithProvider(appleProvider);
      final User? user = userCredential.user;

      if (user != null) {
        LogService().log('Apple Sign-In başarılı: ${user.uid}', type: LogType.success);
        
        // İlk girişte isim bilgisini yakalamaya çalış
        final appleProfile = userCredential.additionalUserInfo?.profile;
        if (appleProfile != null) {
          LogService().log('Apple Profil verisi alındı, isim kontrol ediliyor...', type: LogType.info);
          
          final nameObj = appleProfile['name'] as Map<String, dynamic>?;
          if (nameObj != null) {
            final firstName = nameObj['firstName'] as String? ?? '';
            final lastName = nameObj['lastName'] as String? ?? '';
            final fullName = '$firstName $lastName'.trim();
            
            if (fullName.isNotEmpty && (user.displayName == null || user.displayName!.isEmpty)) {
              await user.updateDisplayName(fullName);
              await user.reload();
              LogService().log('Kullanıcı adı kaydedildi: $fullName', type: LogType.success);
            }
          }
        } else {
          LogService().log('Apple Profil verisi bu seferlik boş (Muhtemelen ilk giriş değil)', type: LogType.warning);
        }
        
        // Hoşgeldin maili (Yeni kullanıcıysa)
        if (userCredential.additionalUserInfo?.isNewUser ?? false) {
          ref.read(analyticsServiceProvider).logSignUp('apple');
          _sendWelcomeEmail(_auth.currentUser);
        }
        
        ref.read(analyticsServiceProvider).logLogin('apple');
        ref.read(analyticsServiceProvider).setUserId(user?.uid);
        
        state = AsyncValue.data(_auth.currentUser);
      }
    } catch (e, stack) {
      LogService().log('Apple Sign-In Hatası', type: LogType.error, error: e);
      
      final errorStr = e.toString().toLowerCase();
      
      // Kullanıcı işlemi iptal ettiyse veya pencereyi kapattıyse hata gösterme
      if (errorStr.contains('canceled') || 
          errorStr.contains('cancelled') || 
          errorStr.contains('user-cancelled') ||
          errorStr.contains('error 1001')) {
        state = AsyncValue.data(_auth.currentUser);
        return;
      }
      
      state = AsyncValue.error(e, stack);
    }
  }

  String _generateNonce([int length = 32]) {
    const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz.-_';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<void> updateDisplayName(String fullName) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.updateDisplayName(fullName);
        await user.reload();
        state = AsyncValue.data(_auth.currentUser);
      }
    } catch (e) {
      debugPrint('Ad güncelleme hatası: $e');
    }
  }

  Future<void> signInWithEmail(String email, String password) async {
    try {
      state = const AsyncValue.loading();
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      state = AsyncValue.data(userCredential.user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> continueAsGuest() async {
    try {
      state = const AsyncValue.loading();
      final userCredential = await _auth.signInAnonymously();
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_completed', true);
      
      ref.read(analyticsServiceProvider).logLogin('guest');
      ref.read(analyticsServiceProvider).setUserId(userCredential.user?.uid);
      
      state = AsyncValue.data(userCredential.user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
      ref.read(analyticsServiceProvider).setUserId(null);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteAccount() async {
    try {
      state = const AsyncValue.loading();
      final user = _auth.currentUser;
      if (user != null) {
        final userId = user.uid;

        // 1. Delete user's reviews from Firestore
        final reviews = await FirebaseFirestore.instance
            .collection('reviews')
            .where('userId', isEqualTo: userId)
            .get();
        
        if (reviews.docs.isNotEmpty) {
          final batch = FirebaseFirestore.instance.batch();
          for (var doc in reviews.docs) {
            batch.delete(doc.reference);
          }
          await batch.commit();
          debugPrint('Deleted ${reviews.docs.length} reviews for user $userId');
        }

        // 2. Delete the user from Firebase Auth
        await user.delete();
        // 3. Also sign out from Google if applicable
        await _googleSignIn.signOut();
      }
      state = const AsyncValue.data(null);
    } on FirebaseAuthException catch (e, st) {
      if (e.code == 'requires-recent-login') {
        state = AsyncValue.error(
          'Güvenlik nedeniyle bu işlem için yeniden giriş yapmanız gerekiyor.',
          st,
        );
      } else {
        state = AsyncValue.error(e, st);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> _sendWelcomeEmail(User? user) async {
    if (user == null || user.email == null) return;

    try {
      const String serviceId = 'service_vrsbgqi';
      const String templateId = 'template_ja4qclo';
      const String publicKey = 'KyxKESmsRL3buWkNm';
      const String accessToken = 'ezCvn0Sv6B0mZhyqzPzBj';

      final response = await http.post(
        Uri.parse('https://api.emailjs.com/api/v1.0/email/send'),
        headers: {
          'Content-Type': 'application/json',
          'origin': 'http://localhost',
        },
        body: json.encode({
          'service_id': serviceId,
          'template_id': templateId,
          'user_id': publicKey,
          'accessToken': accessToken,
          'template_params': {
            'user_name': user.displayName ?? 'Yeni Üyemiz',
            'user_email': user.email,
            'to_name': user.displayName ?? 'Yeni Üyemiz',
          },
        }),
      );

      if (response.statusCode == 200) {
        print('Welcome email sent successfully to ${user.email}');
      } else {
        print('Error sending welcome email (Code: ${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      print('Failed to call EmailJS: $e');
    }
  }
}

Future<void> completeOnboarding() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('onboarding_completed', true);
}
