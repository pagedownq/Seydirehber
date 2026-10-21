import { isTimestamp } from '@/utils/firestore-values';

const pad = (n: number) => String(n).padStart(2, '0');

const TR_MONTHS = [
  'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
  'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık',
];

/** intl DateFormat('dd MMMM yyyy', 'tr_TR'), ör. "05 Ekim 2026". */
export const formatLongTr = (date: Date) =>
  `${pad(date.getDate())} ${TR_MONTHS[date.getMonth()]} ${date.getFullYear()}`;

/** intl DateFormat('HH:mm'). */
export const formatTime = (date: Date) => `${pad(date.getHours())}:${pad(date.getMinutes())}`;

/** intl DateFormat('dd.MM.yyyy'). */
export const formatDots = (date: Date) => `${pad(date.getDate())}.${pad(date.getMonth() + 1)}.${date.getFullYear()}`;

/** Flutter _formatDate: Timestamp ise GG.AA.YYYY, değilse olduğu gibi metin. */
export function formatDate(date: unknown): string {
  if (date == null) return '';
  if (isTimestamp(date)) {
    const dt = date.toDate();
    return `${pad(dt.getDate())}.${pad(dt.getMonth() + 1)}.${dt.getFullYear()}`;
  }
  return String(date);
}
