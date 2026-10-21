// Flutter lib/core/utils/profanity_filter.dart karşılığı (kelime listesi ve eşleştirme kuralları birebir).
// Her harf bir veya daha fazla kez tekrarlanabilir (ör. y+a+r+r+a+k+); eşleşme ancak tam kelimeyse sayılır.
const BAD_WORDS = [
  'amk', 'aq', 'amın', 'amına', 'oç', 'sik', 'sikerim', 'sikti', 'sikis', 'sikiş',
  'göt', 'götü', 'götlek', 'yarrak', 'yarak', 'taşşak', 'tassak', 'orospu',
  'pezevenk', 'gavat', 'piç', 'pic', 'ibne', 'yavsak', 'yavşak', 'it', 'it oğlu it',
  'itsoy', 'kahpe', 'puşt', 'pust', 'kerhane', 'ananın', 'ananı', 'sülaleni', 'oe',
  'siktir', 'sktir', 'sktr', 'sg', 'amq', 'amg', 'amcık', 'amcik', 'am', 'yarak',
  'yarrak', 'yarram', 'yaram', 'taşak', 'tasak', 'dallama', 'dangalak', 'denyo', 'kavat',
  'kaltak', 'kevaşe', 'motor', 'kaşar', 'kasar', 'sürtük', 'surtuk', 'fahişe', 'fahise',
  'dalyarak', 'dalyarrak', 'sığıntı', 'siginti', 'sığır', 'sigir', 'manyak', 'salak', 'aptal',
  'gerizekalı', 'gerizekali', 'beyinsiz', 'embesil', 'özürlü', 'ozurlu', 'mal', 'mal değneği',
  'veled', 'velet', 'sokuk', 'sokuk', 'sürtük', 'dingil', 'dümbük', 'dumbuk', 'hıyar', 'hiyar',
  'lavuk', 'ibine', 'sıçtığım', 'sictigim', 'sıçayım', 'sicayim', 'sıç', 'sic', 'bitch', 'fuck',
  'shit', 'asshole', 'motherfucker', 'or çocuğu', 'or cocugu', 'orospu çocuğu', 'orospu cocugu',
  'zibidi', 'zibidi', 'zina', 'kaltak', 'şıllık', 'sillik', 'çük', 'cuk', 'pip', 'pipi',
];

const LETTER = /[a-zA-ZğüşıöçĞÜŞİÖÇ]/;

const escapeRegExp = (c: string) => c.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

const PATTERNS = BAD_WORDS.map((word) => ({
  word,
  regex: new RegExp(
    [...word].map((c) => `${escapeRegExp(c)}+`).join(''),
    'giu',
  ),
}));

function isWholeWordMatch(text: string, start: number, end: number) {
  if (start > 0 && LETTER.test(text.substring(start - 1, start))) return false;
  if (end < text.length && LETTER.test(text.substring(end, end + 1))) return false;
  return true;
}

function* matchesOf(regex: RegExp, text: string) {
  regex.lastIndex = 0;
  for (const match of text.matchAll(regex)) {
    const start = match.index ?? 0;
    yield { start, end: start + match[0].length };
  }
}

/** Metindeki argo/küfür kelimelerinin listesi. */
export function findProfanity(text: string): string[] {
  if (!text) return [];
  const found = new Set<string>();
  for (const { word, regex } of PATTERNS) {
    for (const { start, end } of matchesOf(regex, text)) {
      if (isWholeWordMatch(text, start, end)) {
        found.add(word);
        break;
      }
    }
  }
  return [...found];
}

export const hasProfanity = (text: string) => findProfanity(text).length > 0;

/** Kötü kelimeleri aynı uzunlukta yıldızla değiştirir. */
export function censor(text: string): string {
  if (!text) return text;
  const matches: { start: number; end: number }[] = [];
  for (const { regex } of PATTERNS) {
    for (const match of matchesOf(regex, text)) {
      if (isWholeWordMatch(text, match.start, match.end)) matches.push(match);
    }
  }
  if (matches.length === 0) return text;

  matches.sort((a, b) => a.start - b.start || b.end - a.end);
  const merged: { start: number; end: number }[] = [];
  for (const match of matches) {
    const last = merged[merged.length - 1];
    if (last && match.start < last.end) {
      if (match.end > last.end) last.end = match.end;
    } else {
      merged.push({ ...match });
    }
  }

  let result = text;
  for (let i = merged.length - 1; i >= 0; i--) {
    const { start, end } = merged[i];
    result = result.slice(0, start) + '*'.repeat(end - start) + result.slice(end);
  }
  return result;
}
