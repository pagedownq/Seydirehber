import {
  AppleAuthProvider,
  deleteUser,
  getAdditionalUserInfo,
  GoogleAuthProvider,
  reload,
  signInAnonymously,
  signInWithCredential,
  signOut as firebaseSignOut,
  updateProfile,
  type User,
} from '@react-native-firebase/auth';
import { collection, getDocs, query, where, writeBatch } from '@react-native-firebase/firestore';
import { GoogleSignin, isSuccessResponse } from '@react-native-google-signin/google-signin';
import * as AppleAuthentication from 'expo-apple-authentication';
import * as Crypto from 'expo-crypto';
import { create } from 'zustand';

import { refreshUser } from '@/features/auth/auth-store';
import { completeOnboarding } from '@/features/auth/onboarding-store';
import { analyticsService } from '@/services/analytics';
import { auth, db } from '@/services/firebase';

// Flutter lib/features/auth/providers/auth_provider.dart (AuthNotifier) karşılığı.

GoogleSignin.configure({
  webClientId: process.env.EXPO_PUBLIC_GOOGLE_WEB_CLIENT_ID,
});

/** Giriş işlemi sürerken butonlar "Giriş yapılıyor..." gösterir (Flutter authNotifierProvider.isLoading). */
export const useAuthLoading = create<{ loading: boolean }>(() => ({ loading: false }));

async function withLoading<T>(task: () => Promise<T>): Promise<T> {
  useAuthLoading.setState({ loading: true });
  try {
    return await task();
  } finally {
    useAuthLoading.setState({ loading: false });
  }
}

export async function signInWithGoogle(): Promise<void> {
  await withLoading(async () => {
    try {
      await GoogleSignin.hasPlayServices({ showPlayServicesUpdateDialog: true });
      const response = await GoogleSignin.signIn();
      if (!isSuccessResponse(response)) return; // kullanıcı vazgeçti

      const credential = GoogleAuthProvider.credential(response.data.idToken);
      const userCredential = await signInWithCredential(auth, credential);

      analyticsService.logLogin('google');
      analyticsService.setUserId(userCredential.user.uid);

      if (getAdditionalUserInfo(userCredential)?.isNewUser) {
        analyticsService.logSignUp('google');
        sendWelcomeEmail(userCredential.user);
      }
    } catch (error) {
      console.warn('Google Sign-In Hatası', error);
    }
  });
}

export async function signInWithApple(): Promise<void> {
  await withLoading(async () => {
    try {
      // Firebase, Apple'a giden nonce'un SHA-256'sını, credential'da ise ham halini bekler.
      const rawNonce = Crypto.randomUUID();
      const hashedNonce = await Crypto.digestStringAsync(Crypto.CryptoDigestAlgorithm.SHA256, rawNonce);

      const appleCredential = await AppleAuthentication.signInAsync({
        requestedScopes: [
          AppleAuthentication.AppleAuthenticationScope.EMAIL,
          AppleAuthentication.AppleAuthenticationScope.FULL_NAME,
        ],
        nonce: hashedNonce,
      });
      if (!appleCredential.identityToken) return;

      const credential = AppleAuthProvider.credential(appleCredential.identityToken, rawNonce);
      const userCredential = await signInWithCredential(auth, credential);
      const user = userCredential.user;

      // Apple adı sadece ilk girişte verir; varsa ve profilde ad yoksa kaydedilir.
      const fullName = [appleCredential.fullName?.givenName, appleCredential.fullName?.familyName]
        .filter(Boolean)
        .join(' ')
        .trim();
      if (fullName && !user.displayName) {
        await updateProfile(user, { displayName: fullName });
        await reload(user);
        refreshUser();
      }

      if (getAdditionalUserInfo(userCredential)?.isNewUser) {
        analyticsService.logSignUp('apple');
        sendWelcomeEmail(auth.currentUser);
      }

      analyticsService.logLogin('apple');
      analyticsService.setUserId(user.uid);
    } catch (error) {
      // Kullanıcı pencereyi kapattıysa hata gösterilmez.
      if ((error as { code?: string }).code === 'ERR_REQUEST_CANCELED') return;
      console.warn('Apple Sign-In Hatası', error);
    }
  });
}

export async function updateDisplayName(fullName: string): Promise<void> {
  try {
    const user = auth.currentUser;
    if (user) {
      await updateProfile(user, { displayName: fullName });
      await reload(user);
      refreshUser();
    }
  } catch (error) {
    console.warn('Ad güncelleme hatası:', error);
  }
}

export async function continueAsGuest(): Promise<void> {
  await withLoading(async () => {
    try {
      const userCredential = await signInAnonymously(auth);
      await completeOnboarding();
      analyticsService.logLogin('guest');
      analyticsService.setUserId(userCredential.user.uid);
    } catch (error) {
      console.warn('Misafir girişi hatası', error);
    }
  });
}

export async function signOut(): Promise<void> {
  try {
    await GoogleSignin.signOut().catch(() => {});
    await firebaseSignOut(auth);
    analyticsService.setUserId(null);
  } catch (error) {
    console.warn('Çıkış hatası', error);
  }
}

/** Kullanıcının yorumlarını siler, sonra hesabı siler. Hata mesajını döner (yoksa null). */
export async function deleteAccount(): Promise<string | null> {
  return withLoading(async () => {
    const user = auth.currentUser;
    if (!user) return null;
    try {
      const reviews = await getDocs(query(collection(db, 'reviews'), where('userId', '==', user.uid)));
      if (!reviews.empty) {
        const batch = writeBatch(db);
        reviews.docs.forEach((doc) => batch.delete(doc.ref));
        await batch.commit();
      }
      await deleteUser(user);
      await GoogleSignin.signOut().catch(() => {});
      return null;
    } catch (error) {
      if ((error as { code?: string }).code === 'auth/requires-recent-login') {
        return 'Güvenlik nedeniyle bu işlem için yeniden giriş yapmanız gerekiyor.';
      }
      return String(error);
    }
  });
}

// Flutter'daki EmailJS hoş geldin e-postası (anahtarlar Flutter'daki ile aynı).
async function sendWelcomeEmail(user: User | null) {
  if (!user?.email) return;
  try {
    await fetch('https://api.emailjs.com/api/v1.0/email/send', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', origin: 'http://localhost' },
      body: JSON.stringify({
        service_id: 'service_vrsbgqi',
        template_id: 'template_ja4qclo',
        user_id: 'KyxKESmsRL3buWkNm',
        accessToken: 'ezCvn0Sv6B0mZhyqzPzBj',
        template_params: {
          user_name: user.displayName ?? 'Yeni Üyemiz',
          user_email: user.email,
          to_name: user.displayName ?? 'Yeni Üyemiz',
        },
      }),
    });
  } catch (error) {
    console.warn('Failed to call EmailJS:', error);
  }
}
