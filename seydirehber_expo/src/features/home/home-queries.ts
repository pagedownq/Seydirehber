import {
  collection,
  deleteDoc,
  doc,
  limit,
  orderBy,
  query,
  Timestamp,
  where,
} from '@react-native-firebase/firestore';

import { createLiveQuery, deriveLiveQuery, type LiveDoc } from '@/features/firestore/live-query';
import { db } from '@/services/firebase';
import { supabase } from '@/services/supabase';
import { byOrderThenName, isTimestamp, parseNum, str } from '@/utils/firestore-values';

// Flutter lib/features/home/providers/home_providers.dart karşılığı.

const thirtyDaysAgo = () => Timestamp.fromDate(new Date(Date.now() - 30 * 24 * 60 * 60 * 1000));

// --- Etkinlikler ---------------------------------------------------------------------------

const cleanupAttempted = new Set<string>();

/**
 * Süresi geçen etkinliği gizler ve silmeyi dener (Flutter'daki gibi her kullanıcıda denenir;
 * Firestore kuralı sadece admin silmesine izin verir, Supabase görsel silme isteği de gönderilir).
 */
function removeExpiredEvent(event: LiveDoc) {
  if (cleanupAttempted.has(event.id)) return;
  cleanupAttempted.add(event.id);

  const images = Array.isArray(event.data.images) ? event.data.images.map(String) : [];
  const imageUrl = str(event.data.image_url, str(event.data.gorsel));
  if (images.length === 0 && imageUrl) images.push(imageUrl);

  if (images.length > 0) {
    const fileNames = images.map((url) => url.split('/').pop() ?? url);
    supabase.storage
      .from('etkinlikler')
      .remove(fileNames)
      .catch(() => {});
  }
  deleteDoc(doc(db, 'etkinlikler', event.id)).catch(() => {});
}

export const useAllEvents = createLiveQuery('allEvents', () => query(collection(db, 'etkinlikler')), {
  transform: (docs) => {
    const now = new Date();
    // Silme sınırı: bugünün başlangıcı (00:00); dünü bitmiş etkinlikler temizlenir.
    const cleanupThreshold = new Date(now.getFullYear(), now.getMonth(), now.getDate());

    const active = docs.filter((event) => {
      const expiry = event.data.bitis_tarihi_str ?? event.data.baslangic_tarihi_str;
      if (isTimestamp(expiry) && expiry.toDate() < cleanupThreshold) {
        removeExpiredEvent(event);
        return false;
      }
      return true;
    });

    // Başlangıç tarihine göre (en yakın önce)
    return active.sort((a, b) => {
      const aDate = a.data.baslangic_tarihi_str ?? a.data.baslangic_tarihi;
      const bDate = b.data.baslangic_tarihi_str ?? b.data.baslangic_tarihi;
      if (isTimestamp(aDate) && isTimestamp(bDate)) return aDate.toMillis() - bDate.toMillis();
      return 0;
    });
  },
});

const takeFive = (docs: LiveDoc[]) => docs.slice(0, 5);

export const useLatestEvents = deriveLiveQuery(useAllEvents, takeFive);

// --- Gezilecek yerler ----------------------------------------------------------------------

export const useAllPlaces = createLiveQuery('allPlaces', () => query(collection(db, 'gezilecek_yerler')), {
  transform: (docs) => [...docs].sort(byOrderThenName('ad')),
});

export const useLatestPlaces = deriveLiveQuery(useAllPlaces, takeFive);

// --- Firmalar ------------------------------------------------------------------------------

/** Son 30 günde eklenenler (Ana Sayfa için 10). */
export const useLatestCompanies = createLiveQuery('latestCompanies', () =>
  query(
    collection(db, 'firmalar'),
    where('created_at', '>=', thirtyDaysAgo()),
    orderBy('created_at', 'desc'),
    limit(10),
  ),
);

/** Son 30 günde eklenenlerin tamamı. */
export const useAllLatestCompanies = createLiveQuery('allLatestCompanies', () =>
  query(collection(db, 'firmalar'), where('created_at', '>=', thirtyDaysAgo()), orderBy('created_at', 'desc')),
);

/** Tüm firmalar: `order` sonra ad. */
export const useAlphabeticalCompanies = createLiveQuery(
  'alphabeticalCompanies',
  () => query(collection(db, 'firmalar')),
  { transform: (docs) => [...docs].sort(byOrderThenName('ad')) },
);

export const useAllCompanies = useAlphabeticalCompanies;

export const useTopFiveCompanies = deriveLiveQuery(useAlphabeticalCompanies, takeFive);

/** Görüntülenmeye göre (Ana Sayfa için 10). */
export const usePopularCompanies = createLiveQuery('popularCompanies', () =>
  query(collection(db, 'firmalar'), orderBy('goruntulenme', 'desc'), limit(10)),
);

export const useAllPopularCompanies = createLiveQuery('allPopularCompanies', () =>
  query(collection(db, 'firmalar'), orderBy('goruntulenme', 'desc')),
);

/** Değerlendirme sayısına göre (Ana Sayfa için 10). */
export const useTopRatedCompanies = createLiveQuery('topRatedCompanies', () =>
  query(collection(db, 'firmalar'), where('yorum_sayisi', '>', 0), orderBy('yorum_sayisi', 'desc'), limit(10)),
);

export const useAllTopRatedCompanies = createLiveQuery('allTopRatedCompanies', () =>
  query(collection(db, 'firmalar'), where('yorum_sayisi', '>', 0), orderBy('yorum_sayisi', 'desc')),
);

// --- Hizmetler -----------------------------------------------------------------------------

export const useNoterler = createLiveQuery('noterler', () => query(collection(db, 'noterler')));

export const usePazarlar = createLiveQuery('pazarlar', () => query(collection(db, 'pazarlar')));

export const useOtobusSaatleri = createLiveQuery('otobusSaatleri', () => query(collection(db, 'otobus_saatleri')), {
  transform: (docs) => [...docs].sort(byOrderThenName('guzergah')),
});

// --- Banner ve kuponlar --------------------------------------------------------------------

export const useBanners = createLiveQuery('banners', () => query(collection(db, 'banners')), {
  includeMetadataChanges: true,
  transform: (docs) => [...docs].sort((a, b) => parseNum(a.data.order, 999999) - parseNum(b.data.order, 999999)),
});

export const useLatestCoupons = createLiveQuery('latestCoupons', () => query(collection(db, 'coupons')));

export const useAllCoupons = createLiveQuery('allCoupons', () => query(collection(db, 'coupons')));
