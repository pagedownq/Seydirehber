import { signInAnonymously } from '@react-native-firebase/auth';

import { initAuthListener } from '@/features/auth/auth-store';
import { loadOnboardingState } from '@/features/auth/onboarding-store';
import { loadBlockedUsers } from '@/features/block/block-service';
import { loadFavorites } from '@/features/favorites/favorites-store';
import { loadSearchHistory } from '@/features/search/search-store';
import { analyticsService } from '@/services/analytics';
import { auth } from '@/services/firebase';
import { initHaptics } from '@/services/haptics';
import { migrateLegacyPrefs } from '@/services/legacy-prefs-migration';
import { initNotifications, scheduleDailyNotifications } from '@/services/notifications';
import { updatePresence } from '@/services/presence';

// Flutter main.dart StartupWrapper._initApp karşılığı. Açılış ekranı bu bitene kadar kalır.
export async function initApp(): Promise<void> {
  await migrateLegacyPrefs();
  const [, onboardingCompleted, user] = await Promise.all([
    initHaptics(),
    loadOnboardingState(),
    initAuthListener(),
    loadFavorites(),
    loadSearchHistory(),
    loadBlockedUsers(),
  ]);

  // Flutter AuthNotifier: kayıtlı oturum varsa analytics kullanıcı kimliği
  if (user != null) analyticsService.setUserId(user.uid);

  // Hazır olduğunda bildirimleri arkadan başlat
  initNotifications().catch((error) => console.warn('Bildirim başlatma hatası:', error));

  // Eski misafir kullanıcıları (oturumsuz ama onboarding'i bitmiş) anonim girişe geçir.
  if (user == null && onboardingCompleted) {
    signInAnonymously(auth)
      .then(() => updatePresence())
      .catch((error) => console.warn('Legacy guest migration failed:', error));
  } else {
    updatePresence();
  }

  // Haftalık hatırlatmaları planla
  scheduleDailyNotifications().catch((error) => console.warn('DailyNotif init error:', error));
}
