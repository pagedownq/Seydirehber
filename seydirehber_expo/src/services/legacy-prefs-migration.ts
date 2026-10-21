import AsyncStorage from '@react-native-async-storage/async-storage';

import { getFlutterPrefs } from '../../modules/flutter-prefs';
import { setItems } from '@/services/storage';

const MIGRATED_KEY = '__flutter_prefs_migrated';

// Önbellekler Firestore'dan yeniden dolar; haftalık bildirimler Expo'da yeniden planlanmalı.
const SKIPPED_KEYS = new Set(['weekly_notif_scheduled_v2']);
const isSkipped = (key: string) => key.endsWith('_cache') || SKIPPED_KEYS.has(key);

/**
 * Mağazadan güncelleme alan kullanıcının Flutter sürümünde kalan ayarlarını
 * (favoriler, arama geçmişi, bildirim tercihleri...) bir kez AsyncStorage'a taşır.
 */
export async function migrateLegacyPrefs(): Promise<void> {
  if ((await AsyncStorage.getItem(MIGRATED_KEY)) != null) return;

  try {
    const legacy = getFlutterPrefs();
    const entries = Object.entries(legacy).filter(([key]) => !isSkipped(key));
    if (entries.length > 0) await setItems(entries);
  } catch (error) {
    // Göç başarısız olursa uygulama varsayılanlarla açılır; tekrar denenmez ki her açılışta takılmasın.
    console.warn('Flutter ayarları taşınamadı', error);
  }

  await AsyncStorage.setItem(MIGRATED_KEY, new Date().toISOString());
}
