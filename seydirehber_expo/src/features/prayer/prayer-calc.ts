import { CalculationMethod, Coordinates, PrayerTimes, Rounding } from 'adhan';

// Seydişehir namaz vakitleri (Expo'ya özgü, Flutter'da yok).
//
// Katmanlar:
// 1. Diyanet vakitleri ezanvakti.emushaf.net'ten (Seydişehir ilçe no 9678, tek istekte ~30 gün).
// 2. Gelen veri cihazda saklanır; servis kapalıyken de ileriye dönük günler kullanılır.
// 3. Saklı gün yoksa vakitler cihazda hesaplanır (adhan, Diyanet yöntemi).
//
// Doğruluk önlemleri:
// - Servisten gelen her gün, cihazda hesaplanan vakitle karşılaştırılır; bir vakit 5 dk'dan fazla
//   saparsa (yanlış ilçe, bozuk veri) yanıtın tamamı reddedilir.
// - Hesaplama 32 günlük Diyanet verisiyle karşılaştırıldı (2026-10-21): yukarı yuvarlama + aşağıdaki
//   düzeltmelerle fark en fazla 1 dk ve hep temkinli yönde (imsak/güneş asla geç; öğle, ikindi, akşam,
//   yatsı asla erken) — yedek hesaplama yüzünden kimse sahuru geç bitirmez, iftarı erken açmaz.
// - Tüm tarih/saat işlemleri Türkiye saatine (UTC+3, 2016'dan beri yaz saati yok) sabittir; cihazın
//   saat dilimi ayarı sonucu değiştirmez.

const DISTRICT_ID = 9678;
export const SOURCE_URL = `https://ezanvakti.emushaf.net/vakitler/${DISTRICT_ID}`;
const SEYDISEHIR = new Coordinates(37.4192, 31.8486);
const TR_OFFSET_MS = 3 * 60 * 60_000;
const MAX_DEVIATION_MIN = 5;

export const PRAYER_KEYS = ['imsak', 'gunes', 'ogle', 'ikindi', 'aksam', 'yatsi'] as const;
export type PrayerKey = (typeof PRAYER_KEYS)[number];

export const PRAYER_LABELS: Record<PrayerKey, string> = {
  imsak: 'İmsak',
  gunes: 'Güneş',
  ogle: 'Öğle',
  ikindi: 'İkindi',
  aksam: 'Akşam',
  yatsi: 'Yatsı',
};

export type PrayerDay = {
  /** Türkiye tarihi, YYYY-MM-DD */
  date: string;
  /** HH:mm, Türkiye saati */
  times: Record<PrayerKey, string>;
  /** Örn. "10 Cemaziyelevvel 1448" (sadece Diyanet verisinde) */
  hijri?: string;
};

export type PrayerSource = 'diyanet' | 'calculated';

export type PrayerCache = { fetchedAt: number; days: PrayerDay[] };

// ── Türkiye saati yardımcıları ───────────────────────────────────────────────

/** Verilen andaki Türkiye tarihi (YYYY-MM-DD). */
export function turkeyDateKey(ms: number): string {
  return new Date(ms + TR_OFFSET_MS).toISOString().slice(0, 10);
}

export function addDays(dateKey: string, days: number): string {
  const [y, m, d] = dateKey.split('-').map(Number);
  return new Date(Date.UTC(y, m - 1, d + days)).toISOString().slice(0, 10);
}

/** Türkiye tarihindeki "HH:mm" saatinin mutlak anı. */
export function prayerInstant(dateKey: string, time: string): number {
  const [y, m, d] = dateKey.split('-').map(Number);
  const [hh, mm] = time.split(':').map(Number);
  return Date.UTC(y, m - 1, d, hh, mm) - TR_OFFSET_MS;
}

const toMinutes = (time: string) => {
  const [hh, mm] = time.split(':').map(Number);
  return hh * 60 + mm;
};

const formatTurkeyTime = (date: Date) => new Date(date.getTime() + TR_OFFSET_MS).toISOString().slice(11, 16);

// ── Cihazda hesaplama ────────────────────────────────────────────────────────

function calculationParams() {
  const params = CalculationMethod.Turkey();
  params.rounding = Rounding.Up;
  Object.assign(params.adjustments, { fajr: -1, sunrise: -1, asr: 1, maghrib: 1, isha: 1 });
  return params;
}

export function calculateDay(dateKey: string): PrayerDay {
  const [y, m, d] = dateKey.split('-').map(Number);
  // adhan günü cihazın yerel takviminden okur; öğlen saati her saat diliminde aynı günü verir.
  const pt = new PrayerTimes(SEYDISEHIR, new Date(y, m - 1, d, 12), calculationParams());
  return {
    date: dateKey,
    times: {
      imsak: formatTurkeyTime(pt.fajr),
      gunes: formatTurkeyTime(pt.sunrise),
      ogle: formatTurkeyTime(pt.dhuhr),
      ikindi: formatTurkeyTime(pt.asr),
      aksam: formatTurkeyTime(pt.maghrib),
      yatsi: formatTurkeyTime(pt.isha),
    },
  };
}

// ── Diyanet verisi ───────────────────────────────────────────────────────────

const TIME_RE = /^([01]\d|2[0-3]):[0-5]\d$/;
const DATE_RE = /^(\d{2})\.(\d{2})\.(\d{4})$/;
const SOURCE_FIELDS: Record<PrayerKey, string> = {
  imsak: 'Imsak',
  gunes: 'Gunes',
  ogle: 'Ogle',
  ikindi: 'Ikindi',
  aksam: 'Aksam',
  yatsi: 'Yatsi',
};

/** Servis yanıtını doğrular; tek bir hatalı gün bile varsa tamamı reddedilir. */
export function parseDiyanetResponse(json: unknown): PrayerDay[] {
  if (!Array.isArray(json) || json.length === 0) throw new Error('empty_response');
  const days = json.map((raw): PrayerDay => {
    const entry = raw as Record<string, unknown>;
    const dateMatch = DATE_RE.exec(String(entry.MiladiTarihKisa ?? ''));
    if (!dateMatch) throw new Error('bad_date');
    const date = `${dateMatch[3]}-${dateMatch[2]}-${dateMatch[1]}`;

    const times = {} as Record<PrayerKey, string>;
    for (const key of PRAYER_KEYS) {
      const value = String(entry[SOURCE_FIELDS[key]] ?? '');
      if (!TIME_RE.test(value)) throw new Error(`bad_time_${key}`);
      times[key] = value;
    }
    for (let i = 1; i < PRAYER_KEYS.length; i++) {
      if (toMinutes(times[PRAYER_KEYS[i]]) <= toMinutes(times[PRAYER_KEYS[i - 1]])) throw new Error('bad_order');
    }

    const reference = calculateDay(date);
    for (const key of PRAYER_KEYS) {
      if (Math.abs(toMinutes(times[key]) - toMinutes(reference.times[key])) > MAX_DEVIATION_MIN) {
        throw new Error(`deviation_${key}`);
      }
    }

    const hijri = typeof entry.HicriTarihUzun === 'string' ? entry.HicriTarihUzun : undefined;
    return { date, times, hijri };
  });
  return days.sort((a, b) => a.date.localeCompare(b.date));
}

// ── Sıradaki vakit ───────────────────────────────────────────────────────────

export type NextPrayer = { key: PrayerKey; date: string; time: string; at: number };

export function findNextPrayer(today: PrayerDay, tomorrow: PrayerDay, now: number): NextPrayer {
  for (const key of PRAYER_KEYS) {
    const at = prayerInstant(today.date, today.times[key]);
    if (at > now) return { key, date: today.date, time: today.times[key], at };
  }
  return { key: 'imsak', date: tomorrow.date, time: tomorrow.times.imsak, at: prayerInstant(tomorrow.date, tomorrow.times.imsak) };
}

/** Şu an içinde bulunulan vakit (imsaktan önceyse null). */
export function findCurrentPrayer(today: PrayerDay, now: number): PrayerKey | null {
  let current: PrayerKey | null = null;
  for (const key of PRAYER_KEYS) {
    if (prayerInstant(today.date, today.times[key]) <= now) current = key;
  }
  return current;
}

/** "1 sa 12 dk", "12 dk", "1 dk" — kalan süre yukarı yuvarlanır. */
export function formatRemaining(ms: number): string {
  const totalMinutes = Math.max(1, Math.ceil(ms / 60_000));
  const hours = Math.floor(totalMinutes / 60);
  const minutes = totalMinutes % 60;
  if (hours === 0) return `${minutes} dk`;
  return minutes === 0 ? `${hours} sa` : `${hours} sa ${minutes} dk`;
}

/** Günün vakitleri: Diyanet verisi varsa o, yoksa hesaplama. */
export function getPrayerDay(cache: PrayerCache | null, dateKey: string): PrayerDay & { source: PrayerSource } {
  const stored = cache?.days.find((d) => d.date === dateKey);
  return stored ? { ...stored, source: 'diyanet' } : { ...calculateDay(dateKey), source: 'calculated' };
}

