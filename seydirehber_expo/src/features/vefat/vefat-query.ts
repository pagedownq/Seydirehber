import { useQuery } from '@tanstack/react-query';
import { parse } from 'node-html-parser';

// Flutter lib/features/services/providers/vefat_provider.dart + models/vefat_model.dart karşılığı.
// Belediye sitesindeki vefat tablosunu okur.
const VEFAT_URL = 'https://www.seydisehir.bel.tr/vefatedenler';

export type Vefat = {
  name: string;
  relative: string;
  date: string;
  detail: string;
  neighborhood: string;
  contact: string;
};

const MONTHS: [string, number][] = [
  ['ocak', 1], ['şubat', 2], ['mart', 3], ['nisan', 4], ['mayıs', 5], ['haziran', 6],
  ['temmuz', 7], ['ağustos', 8], ['eylül', 9], ['ekim', 10], ['kasım', 11], ['aralık', 12],
];

/** Dart int.parse gibi: tamamı sayı değilse hata. */
function parseIntStrict(text: string): number {
  if (!/^[+-]?\d+$/.test(text)) throw new Error(`Invalid number: ${text}`);
  return Number(text);
}

/** "5 Mayıs 2026" ya da "05.05.2026"; çözülemezse null. */
export function vefatDate(vefat: Vefat): Date | null {
  try {
    const cleaned = vefat.date.trim().toLowerCase();
    if (cleaned.includes('.')) {
      const parts = cleaned.split('.');
      if (parts.length === 3) {
        return new Date(parseIntStrict(parts[2]), parseIntStrict(parts[1]) - 1, parseIntStrict(parts[0]));
      }
    }
    const parts = cleaned.split(' ');
    if (parts.length === 3) {
      const day = parseIntStrict(parts[0]);
      const year = parseIntStrict(parts[2]);
      const month = MONTHS.find(([name]) => parts[1].includes(name))?.[1] ?? 1;
      return new Date(year, month - 1, day);
    }
  } catch {}
  return null;
}

const lastPartIsNumber = (parts: string[]) => /^\d+$/.test(parts[parts.length - 1].replace(/[^0-9]/g, ''));

/** İletişim bilgisinin son parçası numaraysa adı ayrılır. */
export function contactName(vefat: Vefat): string {
  if (!vefat.contact) return '';
  const trimmed = vefat.contact.trim();
  const parts = trimmed.split(/\s+/);
  if (parts.length > 1 && lastPartIsNumber(parts)) return parts.slice(0, -1).join(' ');
  return trimmed;
}

export function contactPhone(vefat: Vefat): string {
  if (!vefat.contact) return '';
  const parts = vefat.contact.trim().split(/\s+/);
  return parts.length > 0 && lastPartIsNumber(parts) ? parts[parts.length - 1] : '';
}

async function fetchVefatList(): Promise<Vefat[]> {
  try {
    const response = await fetch(VEFAT_URL);
    if (response.status !== 200) {
      throw new Error(`Exception: Belediye sitesine ulaşılamadı: ${response.status}`);
    }
    const document = parse(await response.text());
    const rows = document.querySelectorAll('table.table tbody tr');

    const list: Vefat[] = [];
    // Geçmişteki her şey gösterilir, gelecekte en fazla 7 gün sonrasına kadar.
    const safetyFutureLimit = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000);
    const seen = new Set<string>();

    for (const row of rows) {
      const cells = row.querySelectorAll('th, td').map((cell) => cell.text);
      if (cells.length < 4) continue;
      const vefat: Vefat = {
        name: (cells[0] ?? '').trim(),
        relative: (cells[1] ?? '').trim(),
        date: (cells[2] ?? '').trim(),
        detail: (cells[3] ?? '').trim(),
        neighborhood: (cells[4] ?? '').trim(),
        contact: (cells[5] ?? '').trim(),
      };
      const date = vefatDate(vefat);
      if (date && date < safetyFutureLimit) {
        const key = `${vefat.name.toLowerCase()}_${vefat.date}`;
        if (!seen.has(key)) {
          list.push(vefat);
          seen.add(key);
        }
      }
    }
    return list;
  } catch (error) {
    const inner = error instanceof Error ? error.message : String(error);
    throw new Error(`Exception: Vefat ilanları yüklenirken hata oluştu: ${inner}`);
  }
}

/** Flutter FutureProvider gibi: bir kez yüklenir, yenileyene kadar saklanır. */
export function useVefatList() {
  return useQuery({
    queryKey: ['vefat'],
    queryFn: fetchVefatList,
    staleTime: Infinity,
    gcTime: Infinity,
    retry: false,
  });
}
