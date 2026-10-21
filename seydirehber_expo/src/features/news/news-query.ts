import { useQuery } from '@tanstack/react-query';
import { XMLParser } from 'fast-xml-parser';
import { parse as parseHtml } from 'node-html-parser';

// Flutter lib/features/news/providers/news_provider.dart + models/news_model.dart karşılığı.
const RSS_URL = 'https://seydisehirhaber.com/rss.xml';
const TIMEOUT_MS = 15_000;
const SOURCE = 'Seydişehir Haber';

export type News = {
  title: string;
  link: string;
  description: string;
  imageUrl: string;
  pubDate: string;
  source: string;
  date: Date | null;
};

const MONTHS: Record<string, number> = {
  jan: 1, feb: 2, mar: 3, apr: 4, may: 5, jun: 6, jul: 7, aug: 8, sep: 9, oct: 10, nov: 11, dec: 12,
};

const toIntOr = (text: string | undefined, fallback: number) => {
  const value = text != null && /^[+-]?\d+$/.test(text) ? Number(text) : NaN;
  return Number.isNaN(value) ? fallback : value;
};

/**
 * Flutter _parseRfc822Date birebir. Not: Flutter saat dilimini düzeltirken yerel saatten ofseti çıkarıyor
 * (toLocal() yerel tarihte etkisiz); Türkiye'de "+0300" ile gelen haber saati 3 saat geride görünüyor.
 * Davranış korunuyor.
 */
export function parseRfc822Date(dateStr: string): Date | null {
  try {
    let cleaned = dateStr;
    if (cleaned.includes(',')) cleaned = cleaned.split(',')[1].trim();
    const parts = cleaned.split(/\s+/);
    if (parts.length >= 4) {
      const day = toIntOr(parts[0], 1);
      const month = MONTHS[parts[1].toLowerCase().substring(0, 3)] ?? 1;
      const year = toIntOr(parts[2], 2026);
      const timeParts = parts[3].split(':');
      const hour = toIntOr(timeParts[0], 0);
      const minute = toIntOr(timeParts[1], 0);
      const second = toIntOr(timeParts[2], 0);

      const date = new Date(year, month - 1, day, hour, minute, second);
      if (parts.length >= 5) {
        const offset = parts[4];
        if (offset.startsWith('+') || offset.startsWith('-')) {
          const sign = offset.startsWith('+') ? 1 : -1;
          const offsetHours = toIntOr(offset.substring(1, 3), 0);
          const offsetMinutes = toIntOr(offset.substring(3, 5), 0);
          return new Date(date.getTime() - sign * (offsetHours * 60 + offsetMinutes) * 60_000);
        }
      }
      return date;
    }
  } catch {}
  const fallback = new Date(dateStr);
  return Number.isNaN(fallback.getTime()) ? null : fallback;
}

const TR_MONTHS = ['Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran', 'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'];
const TR_DAYS = ['Pazar', 'Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi'];
const pad = (n: number) => String(n).padStart(2, '0');

/** Flutter formattedDate: DateFormat('d MMMM yyyy, EEEE - HH:mm', 'tr_TR'), tarih yoksa ham pubDate. */
export function formattedDate(news: News): string {
  const d = news.date;
  if (!d) return news.pubDate;
  return `${d.getDate()} ${TR_MONTHS[d.getMonth()]} ${d.getFullYear()}, ${TR_DAYS[d.getDay()]} - ${pad(d.getHours())}:${pad(d.getMinutes())}`;
}

/** HTML etiketlerini atıp metni çözer (Flutter parser.parseFragment(x).text). */
const htmlText = (value: string) => parseHtml(value).text;

const textOf = (value: unknown): string => {
  if (value == null) return '';
  if (typeof value === 'object' && '#text' in (value as Record<string, unknown>)) {
    return String((value as Record<string, unknown>)['#text']);
  }
  return String(value);
};

const urlOf = (value: unknown): string => {
  const first = Array.isArray(value) ? value[0] : value;
  return first && typeof first === 'object' && 'url' in first ? String((first as { url: unknown }).url) : '';
};

const xmlParser = new XMLParser({
  ignoreAttributes: false,
  attributeNamePrefix: '',
  htmlEntities: true,
  parseTagValue: false,
  trimValues: true,
});

async function fetchNews(): Promise<News[]> {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), TIMEOUT_MS);
  try {
    const response = await fetch(RSS_URL, {
      headers: {
        'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      },
      signal: controller.signal,
    });
    if (response.status !== 200) throw new Error(`RSS feed returned status code ${response.status}`);

    const xml = xmlParser.parse(await response.text());
    const rawItems = xml?.rss?.channel?.item ?? [];
    const items: Record<string, unknown>[] = Array.isArray(rawItems) ? rawItems : [rawItems];

    const news: News[] = [];
    for (const item of items) {
      const title = htmlText(textOf(item.title)).trim();
      const link = textOf(item.link).trim() || textOf(item.guid).trim();

      let description = htmlText(textOf(item.description)).replaceAll('&nbsp;', ' ').trim();
      if (description.length > 200) description = `${description.substring(0, 197)}...`;

      const imageUrl = urlOf(item.enclosure) || urlOf(item['media:content']);
      const pubDateStr = textOf(item.pubDate).trim();
      const date = parseRfc822Date(pubDateStr);
      const pubDate = date
        ? `${date.getDate()} ${TR_MONTHS[date.getMonth()]}, ${pad(date.getHours())}:${pad(date.getMinutes())}`
        : pubDateStr;

      if (title && link) news.push({ title, link, description, imageUrl, pubDate, source: SOURCE, date });
    }

    // En yeni en üstte
    return news.sort((a, b) => (a.date && b.date ? b.date.getTime() - a.date.getTime() : 0));
  } finally {
    clearTimeout(timer);
  }
}

/** Flutter FutureProvider gibi: bir kez yüklenir, yenileyene kadar saklanır. */
export function useNews() {
  return useQuery({
    queryKey: ['news'],
    queryFn: fetchNews,
    staleTime: Infinity,
    gcTime: Infinity,
    retry: false,
  });
}
