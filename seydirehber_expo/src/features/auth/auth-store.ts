import { onAuthStateChanged, type User } from '@react-native-firebase/auth';
import { create } from 'zustand';

import { auth } from '@/services/firebase';

// Flutter authStateProvider (userChanges) karşılığı. onAuthStateChanged profil
// güncellemelerinde tetiklenmediği için isim değişince refreshUser() çağrılır.
type AuthState = {
  user: User | null;
  initialized: boolean;
  /** Profil alanları değişince artar; aynı User nesnesine bağlı bileşenler yeniden çizilsin diye. */
  version: number;
};

export const useAuthStore = create<AuthState>(() => ({
  user: auth.currentUser,
  initialized: false,
  version: 0,
}));

let unsubscribe: (() => void) | null = null;
let firstEvent: Promise<User | null> | null = null;

/** Dinleyiciyi başlatır; Firebase kayıtlı oturumu geri yükleyince (ilk olay) çözülür. */
export function initAuthListener(): Promise<User | null> {
  if (firstEvent) return firstEvent;
  firstEvent = new Promise((resolve) => {
    unsubscribe = onAuthStateChanged(auth, (user) => {
      useAuthStore.setState((state) => ({ user, initialized: true, version: state.version + 1 }));
      resolve(user);
    });
  });
  return firstEvent;
}

export function stopAuthListener() {
  unsubscribe?.();
  unsubscribe = null;
  firstEvent = null;
}

export function refreshUser() {
  useAuthStore.setState((state) => ({ user: auth.currentUser, version: state.version + 1 }));
}

export const useUser = () => useAuthStore((state) => state.user);

/** Flutter isGuestProvider: oturum yoksa ya da anonimse misafir. */
export const useIsGuest = () => useAuthStore((state) => state.user == null || state.user.isAnonymous);
