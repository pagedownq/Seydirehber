import {
  collection,
  doc,
  getDocs,
  onSnapshot,
  query,
  Timestamp,
  updateDoc,
  where,
  writeBatch,
} from '@react-native-firebase/firestore';
import { useEffect, useState } from 'react';

import { db } from '@/services/firebase';
import { isTimestamp } from '@/utils/firestore-values';

// Flutter lib/core/services/stat_service.dart + review_service.syncAllReviewStats karşılığı.

export type AppStats = {
  totalCount: number;
  activeToday: number;
  activeNow: number;
  guestCount: number;
  registeredCount: number;
};

export type StatsState =
  | { status: 'loading' }
  | { status: 'error'; error: Error }
  | { status: 'success'; stats: AppStats };

/** user_presence üzerinden canlı istatistikler (herkesin, anonimlerin de kaydı var). */
export function useAppStats(): StatsState {
  const [state, setState] = useState<StatsState>({ status: 'loading' });

  useEffect(
    () =>
      onSnapshot(
        collection(db, 'user_presence'),
        (snapshot) => {
          const now = Date.now();
          const todayThreshold = now - 24 * 60 * 60 * 1000;
          const onlineThreshold = now - 5 * 60 * 1000;
          const stats: AppStats = {
            totalCount: snapshot.docs.length,
            activeToday: 0,
            activeNow: 0,
            guestCount: 0,
            registeredCount: 0,
          };
          for (const presence of snapshot.docs) {
            const data = presence.data();
            const isAnon = typeof data.isAnonymous === 'boolean' ? data.isAnonymous : true;
            if (isAnon) stats.guestCount++;
            else stats.registeredCount++;
            if (isTimestamp(data.lastSeen)) {
              const lastSeen = data.lastSeen.toDate().getTime();
              if (lastSeen > todayThreshold) stats.activeToday++;
              if (lastSeen > onlineThreshold) stats.activeNow++;
            }
          }
          setState({ status: 'success', stats });
        },
        (error) => setState({ status: 'error', error }),
      ),
    [],
  );

  return state;
}

/** Son 30 gündür görülmeyen user_tokens kayıtlarını siler; silinen sayıyı döner. */
export async function purgeInactiveTokens(): Promise<number> {
  const threshold = Timestamp.fromDate(new Date(Date.now() - 30 * 24 * 60 * 60 * 1000));
  const snapshot = await getDocs(query(collection(db, 'user_tokens'), where('lastSeen', '<', threshold)));
  if (snapshot.empty) return 0;
  const batch = writeBatch(db);
  snapshot.docs.forEach((d) => batch.delete(d.ref));
  await batch.commit();
  return snapshot.docs.length;
}

/** Tüm firma ve yerlerin yorum sayısı / ortalama puanını yeniden hesaplar. */
export async function syncAllReviewStats() {
  const [companies, places] = await Promise.all([
    getDocs(collection(db, 'firmalar')),
    getDocs(collection(db, 'gezilecek_yerler')),
  ]);
  const targets = [
    ...companies.docs.map((d) => ({ id: d.id, collection: 'firmalar' })),
    ...places.docs.map((d) => ({ id: d.id, collection: 'gezilecek_yerler' })),
  ];

  for (const target of targets) {
    const reviews = await getDocs(query(collection(db, 'reviews'), where('targetId', '==', target.id)));
    const ref = doc(db, target.collection, target.id);
    if (!reviews.empty) {
      const total = reviews.docs.reduce((sum, r) => {
        const rating = r.data().rating;
        return sum + (typeof rating === 'number' ? rating : 0);
      }, 0);
      await updateDoc(ref, { ortalama_puan: total / reviews.docs.length, yorum_sayisi: reviews.docs.length });
    } else {
      await updateDoc(ref, { ortalama_puan: 0.0, yorum_sayisi: 0 });
    }
  }
}
