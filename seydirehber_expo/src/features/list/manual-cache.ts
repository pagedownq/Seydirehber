import AsyncStorage from '@react-native-async-storage/async-storage';
import { Timestamp } from '@react-native-firebase/firestore';

import type { FirestoreData } from '@/features/firestore/live-query';
import { isTimestamp } from '@/utils/firestore-values';

// Flutter LocalCacheService.saveList / getList karşılığı: liste ekranları son başarılı veriyi saklar,
// bağlantı yoksa "ÖNBELLEK" rozetiyle onu gösterir. Timestamp'ler ISO metin olarak saklanıp geri çevrilir.
const ISO_8601 = /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/;

export type CachedItem = FirestoreData & { id: string };

export async function saveList(key: string, items: CachedItem[]) {
  const encoded = JSON.stringify(items, function replacer(this: Record<string, unknown>, name, value) {
    const original = this[name];
    return isTimestamp(original) ? original.toDate().toISOString() : value;
  });
  await AsyncStorage.setItem(key, encoded).catch(() => {});
}

function restoreTimestamps(value: unknown): unknown {
  if (Array.isArray(value)) return value.map(restoreTimestamps);
  if (value && typeof value === 'object') {
    return Object.fromEntries(Object.entries(value).map(([k, v]) => [k, restoreTimestamps(v)]));
  }
  if (typeof value === 'string' && value.length >= 19 && ISO_8601.test(value)) {
    const date = new Date(value);
    if (!Number.isNaN(date.getTime())) return Timestamp.fromDate(date);
  }
  return value;
}

export async function getList(key: string): Promise<CachedItem[] | null> {
  try {
    const encoded = await AsyncStorage.getItem(key);
    if (!encoded) return null;
    const decoded = JSON.parse(encoded);
    return Array.isArray(decoded) ? (decoded.map(restoreTimestamps) as CachedItem[]) : null;
  } catch {
    return null;
  }
}
