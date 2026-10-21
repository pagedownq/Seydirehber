import AsyncStorage from '@react-native-async-storage/async-storage';

// Flutter shared_preferences karşılığı. Anahtar adları Flutter'dakiyle aynı;
// değerler tipleri korunsun diye JSON olarak saklanır.
export const StorageKeys = {
  onboardingCompleted: 'onboarding_completed',
  favoritesList: 'favorites_list',
  blockedUserDetailsJson: 'blocked_user_details_json',
  blockedUserUids: 'blocked_user_uids',
  searchHistory: 'search_history',
  forumRulesAccepted: 'forum_rules_accepted',
  notificationsEnabled: 'notifications_enabled',
  vefatNotificationsEnabled: 'vefat_notifications_enabled',
  dailyNotifEnabled: 'daily_notif_enabled',
  hapticsEnabled: 'haptics_enabled',
  installationDate: 'installationDate',
  lastRegisteredFcmToken: 'last_registered_fcm_token',
  // Expo'ya özgü (Flutter'da yok): açılışı tetikleyen bildirim bir kez işlensin.
  lastHandledNotificationId: 'last_handled_notification_id',
  // Expo'ya özgü: Diyanet namaz vakitleri (features/prayer/prayer-times.ts).
  prayerTimesCache: 'prayer_times_cache_v1',
} as const;

export const viewedCompanyKey = (companyId: string) => `is_viewed_${companyId}`;
export const surveyCompletedKey = (surveyId: string) => `survey_completed_${surveyId}`;

export async function getItem<T>(key: string): Promise<T | null> {
  const raw = await AsyncStorage.getItem(key);
  if (raw == null) return null;
  try {
    return JSON.parse(raw) as T;
  } catch {
    return null;
  }
}

export async function setItem<T>(key: string, value: T): Promise<void> {
  await AsyncStorage.setItem(key, JSON.stringify(value));
}

export async function setItems(entries: [string, unknown][]): Promise<void> {
  await AsyncStorage.multiSet(entries.map(([key, value]) => [key, JSON.stringify(value)]));
}

export async function removeItem(key: string): Promise<void> {
  await AsyncStorage.removeItem(key);
}
