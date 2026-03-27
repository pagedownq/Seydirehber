import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Admin emails
const List<String> adminEmails = [
  'mehmetirem305@gmail.com',
  'bilgimgverse@gmail.com'
];

// Auth state provider
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

// Onboarding completed check
final onboardingCompletedProvider = FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('onboarding_completed') ?? false;
});

// Is Admin check
final isAdminProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.whenOrNull(
        data: (user) => adminEmails.contains(user?.email),
      ) ??
      false;
});

// Is Guest check
final isGuestProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.whenOrNull(
        data: (user) => user == null,
      ) ??
      true;
});

// Auth Notifier
final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<User?>>((ref) {
  return AuthNotifier();
});

class AuthNotifier extends StateNotifier<AsyncValue<User?>> {
  AuthNotifier() : super(AsyncValue.data(FirebaseAuth.instance.currentUser));

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
      state = AsyncValue.data(userCredential.user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> continueAsGuest() async {
    // Guest: no Firebase auth, user stays null
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    state = const AsyncValue.data(null);
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
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
        // We attempt to delete the user from Firebase Auth
        await user.delete();
        // Also sign out from Google if applicable
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
}

Future<void> completeOnboarding() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('onboarding_completed', true);
}
