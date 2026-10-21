import {
  addDoc,
  collection,
  deleteDoc,
  doc,
  query,
  runTransaction,
  serverTimestamp,
  Timestamp,
} from '@react-native-firebase/firestore';

import { useAuthStore } from '@/features/auth/auth-store';
import { createLiveQuery, type LiveDoc } from '@/features/firestore/live-query';
import { db } from '@/services/firebase';
import { isTimestamp, str } from '@/utils/firestore-values';

// Flutter lib/features/reports (models/report_model.dart + providers/report_provider.dart) karşılığı.
// Koleksiyon: traffic_reports (snake_case alanlar).
export const REPORT_CATEGORIES = [
  { value: 'yol_arizasi', label: 'Altyapı/Yol Arızası', emoji: '🛠️' },
  { value: 'yol_kapali', label: 'Kapalı Yol', emoji: '🚫' },
  { value: 'kaza', label: 'Trafik Kazası', emoji: '💥' },
  { value: 'su_kesintisi', label: 'Su Kesintisi', emoji: '💧' },
  { value: 'diger', label: 'Diğer', emoji: '⚠️' },
] as const;

export type ReportCategory = (typeof REPORT_CATEGORIES)[number];
export type ReportCategoryValue = ReportCategory['value'];

export function reportCategory(value: string): ReportCategory {
  return REPORT_CATEGORIES.find((c) => c.value === value) ?? REPORT_CATEGORIES[4];
}

export type TrafficReport = {
  id: string;
  userId: string;
  displayName: string;
  category: string;
  address: string;
  description: string;
  dateTime: Date;
  confirmedUserIds: string[];
  unconfirmedUserIds: string[];
  createdAt: Date;
};

const toDate = (value: unknown) => (isTimestamp(value) ? value.toDate() : new Date());
const toIds = (value: unknown) => (Array.isArray(value) ? value.filter((v): v is string => typeof v === 'string') : []);

export function toTrafficReport({ id, data }: LiveDoc): TrafficReport {
  return {
    id,
    userId: str(data.user_id),
    displayName: str(data.display_name, 'Kullanıcı'),
    category: str(data.category, 'diger'),
    address: str(data.address),
    description: str(data.description),
    dateTime: toDate(data.date_time),
    confirmedUserIds: toIds(data.confirmed_user_ids),
    unconfirmedUserIds: toIds(data.unconfirmed_user_ids),
    createdAt: toDate(data.created_at),
  };
}

/** Son 24 saatte oluşturulan bildirimler, yeniden eskiye. */
export const useActiveReports = createLiveQuery('activeReports', () => query(collection(db, 'traffic_reports')), {
  transform: (docs) => {
    const threshold = Date.now() - 24 * 60 * 60 * 1000;
    return docs
      .filter((d) => toTrafficReport(d).createdAt.getTime() > threshold)
      .sort((a, b) => toTrafficReport(b).createdAt.getTime() - toTrafficReport(a).createdAt.getTime());
  },
});

const currentUser = () => useAuthStore.getState().user;

export async function createReport(input: {
  category: ReportCategoryValue;
  address: string;
  description: string;
  dateTime: Date;
}) {
  const user = currentUser();
  if (!user) throw new Error('Giriş yapmanız gerekmektedir.');

  await addDoc(collection(db, 'traffic_reports'), {
    user_id: user.uid,
    display_name: user.displayName ?? 'Kullanıcı',
    category: input.category,
    address: input.address,
    description: input.description,
    date_time: Timestamp.fromDate(input.dateTime),
    confirmed_user_ids: [],
    unconfirmed_user_ids: [],
    created_at: serverTimestamp(),
  });
}

/** Doğrula / Yanlış: biri eklenince diğerinden çıkarılır (karşılıklı dışlayıcı). */
async function toggleVote(reportId: string, field: 'confirmed_user_ids' | 'unconfirmed_user_ids') {
  const user = currentUser();
  if (!user) throw new Error('Doğrulamak için giriş yapmanız gerekmektedir.');

  const ref = doc(db, 'traffic_reports', reportId);
  await runTransaction(db, async (tx) => {
    const snapshot = await tx.get(ref);
    if (!snapshot.exists()) return;
    const data = snapshot.data() ?? {};
    const confirmed = toIds(data.confirmed_user_ids);
    const unconfirmed = toIds(data.unconfirmed_user_ids);
    const [own, other] = field === 'confirmed_user_ids' ? [confirmed, unconfirmed] : [unconfirmed, confirmed];

    if (own.includes(user.uid)) {
      own.splice(own.indexOf(user.uid), 1);
    } else {
      own.push(user.uid);
      if (other.includes(user.uid)) other.splice(other.indexOf(user.uid), 1);
    }

    tx.update(ref, { confirmed_user_ids: confirmed, unconfirmed_user_ids: unconfirmed });
  });
}

export const toggleConfirmReport = (reportId: string) => toggleVote(reportId, 'confirmed_user_ids');
export const toggleUnconfirmReport = (reportId: string) => toggleVote(reportId, 'unconfirmed_user_ids');

export async function deleteReport(reportId: string) {
  if (!currentUser()) throw new Error('Giriş yapmanız gerekmektedir.');
  await deleteDoc(doc(db, 'traffic_reports', reportId));
}
