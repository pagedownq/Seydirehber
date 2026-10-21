import { collection, query } from '@react-native-firebase/firestore';

import { createLiveQuery, type FirestoreData, type LiveDoc } from '@/features/firestore/live-query';
import { db } from '@/services/firebase';
import { isTimestamp, str } from '@/utils/firestore-values';

// İş ilanları (Expo'ya özgü, Flutter'da yok). Koleksiyon `is_ilanlari`, sadece admin yazar.
// Yayın bitişi boşsa ilan eklendikten 30 gün sonra listeden düşer; süre istemcide hesaplanır.
export const JOBS_COLLECTION = 'is_ilanlari';
const DEFAULT_DURATION_MS = 30 * 24 * 60 * 60 * 1000;

export const useJobs = createLiveQuery('isIlanlari', () => query(collection(db, JOBS_COLLECTION)));

/** Firestore'da henüz sunucu saati yazılmamış yeni kayıtlar için şimdiki zaman. */
export function createdAt(data: FirestoreData): Date {
  return isTimestamp(data.created_at) ? data.created_at.toDate() : new Date();
}

export function expiresAt(data: FirestoreData): Date {
  if (isTimestamp(data.bitis_tarihi)) {
    // Seçilen günün sonuna kadar yayında kalsın
    const end = data.bitis_tarihi.toDate();
    end.setHours(23, 59, 59, 999);
    return end;
  }
  return new Date(createdAt(data).getTime() + DEFAULT_DURATION_MS);
}

export function isJobVisible(data: FirestoreData, now = new Date()) {
  return data.aktif !== false && expiresAt(data) > now;
}

/** Yayındaki ilanlar, en yeni üstte. */
export function visibleJobs(docs: LiveDoc[]): LiveDoc[] {
  const now = new Date();
  return docs
    .filter((d) => isJobVisible(d.data, now))
    .sort((a, b) => createdAt(b.data).getTime() - createdAt(a.data).getTime());
}

/** "3 gün önce" gibi kısa göreli zaman. */
export function timeAgo(date: Date, now = new Date()) {
  const minutes = Math.floor((now.getTime() - date.getTime()) / 60_000);
  if (minutes < 60) return 'Az önce';
  const hours = Math.floor(minutes / 60);
  if (hours < 24) return `${hours} saat önce`;
  const days = Math.floor(hours / 24);
  if (days === 1) return 'Dün';
  if (days < 7) return `${days} gün önce`;
  const weeks = Math.floor(days / 7);
  return `${weeks} hafta önce`;
}

export function daysLeft(data: FirestoreData, now = new Date()) {
  return Math.max(0, Math.ceil((expiresAt(data).getTime() - now.getTime()) / (24 * 60 * 60 * 1000)));
}

/** WhatsApp için uluslararası biçim: 0532... / 532... / +90532... → 90532... */
export function whatsappNumber(phone: string) {
  let digits = phone.replace(/\D/g, '');
  if (digits.startsWith('0')) digits = digits.slice(1);
  if (digits.length === 10) digits = `90${digits}`;
  return digits;
}

export function jobFields(data: FirestoreData) {
  return {
    title: str(data.baslik, 'İş İlanı'),
    employer: str(data.firma_adi),
    companyId: str(data.company_id),
    workType: str(data.calisma_sekli),
    description: str(data.aciklama),
    hours: str(data.calisma_saatleri),
    salary: str(data.ucret),
    phone: str(data.telefon),
    hasWhatsapp: data.whatsapp !== false,
    address: str(data.adres),
    location: str(data.konum),
  };
}
