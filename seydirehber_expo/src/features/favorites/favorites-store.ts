import { create } from 'zustand';

import { getItem, setItem, StorageKeys } from '@/services/storage';

// Flutter lib/features/favorites/providers/favorites_provider.dart karşılığı.
// Saklama biçimi Flutter'la aynı: "id:type" metinlerinden oluşan liste.
export type FavoriteType = 'company' | 'place';
export type FavoriteItem = { id: string; type: FavoriteType };

const toRaw = (item: FavoriteItem) => `${item.id}:${item.type}`;
const fromRaw = (raw: string): FavoriteItem => {
  const [id, type] = raw.split(':');
  return { id, type: type as FavoriteType };
};

export const useFavoritesStore = create<{ items: FavoriteItem[] }>(() => ({ items: [] }));

export async function loadFavorites() {
  const raw = await getItem<string[]>(StorageKeys.favoritesList);
  if (raw) useFavoritesStore.setState({ items: raw.map(fromRaw) });
}

export async function toggleFavorite(id: string, type: FavoriteType) {
  const { items } = useFavoritesStore.getState();
  const exists = items.some((e) => e.id === id && e.type === type);
  const next = exists ? items.filter((e) => !(e.id === id && e.type === type)) : [...items, { id, type }];
  useFavoritesStore.setState({ items: next });
  await setItem(StorageKeys.favoritesList, next.map(toRaw));
}

export const useIsFavorite = (id: string, type: FavoriteType) =>
  useFavoritesStore((state) => state.items.some((e) => e.id === id && e.type === type));
