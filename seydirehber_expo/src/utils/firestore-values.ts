// Firestore alanlarını Flutter'daki `as String? ?? ''` kalıplarıyla aynı şekilde okumak için yardımcılar.

type TimestampLike = { toDate(): Date; toMillis(): number; seconds: number };

export function isTimestamp(value: unknown): value is TimestampLike {
  return (
    typeof value === 'object' &&
    value != null &&
    typeof (value as TimestampLike).toDate === 'function' &&
    typeof (value as TimestampLike).toMillis === 'function'
  );
}

/** Dart `data['x'] as String? ?? fallback`: değer string değilse fallback. */
export function str(value: unknown, fallback = ''): string {
  return typeof value === 'string' ? value : fallback;
}

/** Dart `data['x']?.toString() ?? fallback`. */
export function toStr(value: unknown, fallback = ''): string {
  return value == null ? fallback : String(value);
}

/** Dart `data['x'] as int? ?? fallback`. */
export function int(value: unknown, fallback = 0): number {
  return typeof value === 'number' && Number.isInteger(value) ? value : fallback;
}

/** Dart `num.tryParse(x?.toString() ?? '') ?? fallback`. */
export function parseNum(value: unknown, fallback: number): number {
  if (value == null) return fallback;
  const text = String(value).trim();
  if (text === '') return fallback;
  const parsed = Number(text);
  return Number.isNaN(parsed) ? fallback : parsed;
}

/** Dart String.compareTo: UTF-16 kod birimi sırası (yerel ayara bakmaz). */
export function compareStrings(a: string, b: string): number {
  return a < b ? -1 : a > b ? 1 : 0;
}

/** Flutter'daki ortak sıralama: `order` (yoksa 999999), sonra küçük harfli ad alanı. */
export function byOrderThenName(nameField: string) {
  return (a: { data: Record<string, unknown> }, b: { data: Record<string, unknown> }) => {
    const orderComparison = parseNum(a.data.order, 999999) - parseNum(b.data.order, 999999);
    if (orderComparison !== 0) return orderComparison;
    return compareStrings(
      toStr(a.data[nameField]).toLowerCase(),
      toStr(b.data[nameField]).toLowerCase(),
    );
  };
}
