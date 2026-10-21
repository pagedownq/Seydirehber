import { useEffect, useState } from 'react';
import { AppState } from 'react-native';
import { create } from 'zustand';

import {
  addDays,
  findCurrentPrayer,
  findNextPrayer,
  getPrayerDay,
  parseDiyanetResponse,
  type PrayerCache,
  type PrayerDay,
  SOURCE_URL,
  turkeyDateKey,
} from '@/features/prayer/prayer-calc';
import { analyticsService } from '@/services/analytics';
import { getItem, setItem, StorageKeys } from '@/services/storage';

export * from '@/features/prayer/prayer-calc';

// Diyanet vakitlerinin çekilmesi, cihazda saklanması ve ekranlara verilmesi. Hesaplama/doğrulama: prayer-calc.ts.

const FETCH_TIMEOUT_MS = 10_000;
const REFRESH_AFTER_MS = 3 * 24 * 60 * 60_000;
const MIN_FUTURE_DAYS = 7;

async function fetchDiyanetDays(): Promise<PrayerDay[]> {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), FETCH_TIMEOUT_MS);
  try {
    const response = await fetch(SOURCE_URL, { signal: controller.signal });
    if (!response.ok) throw new Error(`http_${response.status}`);
    return parseDiyanetResponse(await response.json());
  } finally {
    clearTimeout(timer);
  }
}

// ── Saklama ve yenileme ──────────────────────────────────────────────────────

type PrayerStore = {
  cache: PrayerCache | null;
  loaded: boolean;
  refreshing: boolean;
  lastError: string | null;
};

const usePrayerStore = create<PrayerStore>(() => ({ cache: null, loaded: false, refreshing: false, lastError: null }));

let loadPromise: Promise<void> | null = null;
let refreshPromise: Promise<void> | null = null;
let failureLogged = false;

function loadCache() {
  loadPromise ??= getItem<PrayerCache>(StorageKeys.prayerTimesCache)
    .then((cache) => {
      const valid = cache && Array.isArray(cache.days) && typeof cache.fetchedAt === 'number' ? cache : null;
      usePrayerStore.setState({ cache: valid, loaded: true });
    })
    .catch(() => usePrayerStore.setState({ loaded: true }));
  return loadPromise;
}

function needsRefresh(cache: PrayerCache | null, now: number) {
  if (!cache) return true;
  if (now - cache.fetchedAt > REFRESH_AFTER_MS) return true;
  const lastNeeded = addDays(turkeyDateKey(now), MIN_FUTURE_DAYS - 1);
  return !cache.days.some((d) => d.date >= lastNeeded);
}

/** Diyanet vakitlerini çeker; `force` yoksa sadece gerektiğinde. Hata olursa eldeki veriyle devam edilir. */
export function refreshPrayerTimes(force = false): Promise<void> {
  if (refreshPromise) return refreshPromise;
  refreshPromise = (async () => {
    await loadCache();
    const now = Date.now();
    if (!force && !needsRefresh(usePrayerStore.getState().cache, now)) return;

    usePrayerStore.setState({ refreshing: true });
    try {
      const fresh = await fetchDiyanetDays();
      // Dünden eski günleri at, yenileri eskilerin üstüne yaz.
      const keepFrom = addDays(turkeyDateKey(now), -1);
      const byDate = new Map<string, PrayerDay>();
      for (const d of usePrayerStore.getState().cache?.days ?? []) if (d.date >= keepFrom) byDate.set(d.date, d);
      for (const d of fresh) if (d.date >= keepFrom) byDate.set(d.date, d);
      const cache: PrayerCache = { fetchedAt: now, days: [...byDate.values()].sort((a, b) => a.date.localeCompare(b.date)) };
      usePrayerStore.setState({ cache, lastError: null });
      await setItem(StorageKeys.prayerTimesCache, cache);
    } catch (error) {
      const reason = error instanceof Error ? error.message : 'unknown';
      usePrayerStore.setState({ lastError: reason });
      // Servisin kapandığını kullanıcı şikayetinden önce görebilmek için (oturum başına bir kez).
      if (!failureLogged) {
        failureLogged = true;
        analyticsService.logEvent('prayer_times_fetch_failed', { reason: reason.slice(0, 90) });
      }
    } finally {
      usePrayerStore.setState({ refreshing: false });
    }
  })().finally(() => {
    refreshPromise = null;
  });
  return refreshPromise;
}

const TICK_MS = 15_000;

/** Bugün/yarın vakitleri, sıradaki vakit ve kaynak. Her 15 sn ve uygulama öne gelince yenilenir. */
export function usePrayerTimes() {
  const { cache, loaded, refreshing, lastError } = usePrayerStore();
  const [now, setNow] = useState(() => Date.now());

  useEffect(() => {
    void refreshPrayerTimes();
    const timer = setInterval(() => setNow(Date.now()), TICK_MS);
    const subscription = AppState.addEventListener('change', (state) => {
      if (state === 'active') {
        setNow(Date.now());
        void refreshPrayerTimes();
      }
    });
    return () => {
      clearInterval(timer);
      subscription.remove();
    };
  }, []);

  const todayKey = turkeyDateKey(now);
  const today = getPrayerDay(cache, todayKey);
  const tomorrow = getPrayerDay(cache, addDays(todayKey, 1));
  const next = findNextPrayer(today, tomorrow, now);

  return {
    now,
    loaded,
    refreshing,
    lastError,
    fetchedAt: cache?.fetchedAt ?? null,
    today,
    tomorrow,
    next,
    current: findCurrentPrayer(today, now),
    upcoming: (count: number) => Array.from({ length: count }, (_, i) => getPrayerDay(cache, addDays(todayKey, i))),
  };
}
