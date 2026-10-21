import { create } from 'zustand';

import { getItem, removeItem, setItem, StorageKeys } from '@/services/storage';

// Flutter search_history_provider.dart + search_screen.dart'taki searchQueryProvider karşılığı.

const MAX_HISTORY = 10;

export const useSearchHistoryStore = create<{ history: string[] }>(() => ({ history: [] }));

export async function loadSearchHistory() {
  const history = await getItem<string[]>(StorageKeys.searchHistory);
  if (history) useSearchHistoryStore.setState({ history });
}

export async function addSearchTerm(term: string) {
  const cleanTerm = term.trim();
  if (!cleanTerm) return;
  // Varsa önce eskiyi çıkar (başa taşımak için), başa ekle, sınırı aşanı sil.
  const next = [cleanTerm, ...useSearchHistoryStore.getState().history.filter((t) => t !== cleanTerm)].slice(
    0,
    MAX_HISTORY,
  );
  useSearchHistoryStore.setState({ history: next });
  await setItem(StorageKeys.searchHistory, next);
}

export async function removeSearchTerm(term: string) {
  const next = useSearchHistoryStore.getState().history.filter((t) => t !== term);
  useSearchHistoryStore.setState({ history: next });
  await setItem(StorageKeys.searchHistory, next);
}

export async function clearSearchHistory() {
  useSearchHistoryStore.setState({ history: [] });
  await removeItem(StorageKeys.searchHistory);
}

/**
 * Flutter'daki searchQueryProvider global (autoDispose değil); arama ekranı kapanınca sıfırlanmıyor ve
 * ekrana tekrar girildiğinde kutu boşken eski sonuçlar görünüyor. Aynı davranış korunuyor.
 */
export const useSearchQueryStore = create<{ query: string }>(() => ({ query: '' }));
