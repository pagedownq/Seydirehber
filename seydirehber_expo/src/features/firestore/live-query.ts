import { onSnapshot, type Query } from '@react-native-firebase/firestore';
import { create } from 'zustand';

// Flutter'daki Riverpod StreamProvider karşılığı: her sorgu için tek bir onSnapshot dinleyicisi
// açılır, ilk kullanımda başlar ve uygulama boyunca canlı kalır (autoDispose olmayan provider gibi).
// Aynı veriyi kullanan ekranlar dinleyiciyi paylaşır.

export type FirestoreData = Record<string, unknown>;
export type LiveDoc = { id: string; data: FirestoreData };

export type LiveQueryState =
  | { status: 'loading'; docs: LiveDoc[]; error: null }
  | { status: 'success'; docs: LiveDoc[]; error: null }
  | { status: 'error'; docs: LiveDoc[]; error: Error };

type LiveQueryOptions = {
  /** Belgeleri süzme / sıralama (Flutter'daki .map((snapshot) => ...) kısmı). */
  transform?: (docs: LiveDoc[]) => LiveDoc[];
  includeMetadataChanges?: boolean;
};

const useLiveQueryStore = create<Record<string, LiveQueryState>>(() => ({}));
const unsubscribers = new Map<string, () => void>();

function start(key: string, buildQuery: () => Query, options: LiveQueryOptions) {
  if (unsubscribers.has(key)) return;
  useLiveQueryStore.setState({ [key]: { status: 'loading', docs: [], error: null } });

  const unsubscribe = onSnapshot(
    buildQuery(),
    { includeMetadataChanges: options.includeMetadataChanges ?? false },
    (snapshot) => {
      const docs = snapshot.docs.map((doc) => ({ id: doc.id, data: doc.data() as FirestoreData }));
      useLiveQueryStore.setState({
        [key]: { status: 'success', docs: options.transform ? options.transform(docs) : docs, error: null },
      });
    },
    (error) => {
      const previous = useLiveQueryStore.getState()[key];
      useLiveQueryStore.setState({ [key]: { status: 'error', docs: previous?.docs ?? [], error } });
    },
  );
  unsubscribers.set(key, unsubscribe);
}

const LOADING: LiveQueryState = { status: 'loading', docs: [], error: null };

export type LiveQueryHook = (() => LiveQueryState) & {
  /** Flutter ref.refresh(provider): dinleyiciyi kapatıp yeniden başlatır. */
  refresh: () => void;
};

/** Paylaşılan canlı sorgu hook'u üretir. `key` uygulama genelinde benzersiz olmalı. */
export function createLiveQuery(key: string, buildQuery: () => Query, options: LiveQueryOptions = {}): LiveQueryHook {
  function useLiveQuery(): LiveQueryState {
    start(key, buildQuery, options);
    return useLiveQueryStore((state) => state[key] ?? LOADING);
  }
  useLiveQuery.refresh = () => {
    unsubscribers.get(key)?.();
    unsubscribers.delete(key);
    start(key, buildQuery, options);
  };
  return useLiveQuery;
}

/** Başka bir canlı sorgudan türetilmiş sonuç (Flutter: ref.watch(x.stream).map(...)). */
export function deriveLiveQuery(
  useSource: () => LiveQueryState,
  select: (docs: LiveDoc[]) => LiveDoc[],
) {
  return function useDerived(): LiveQueryState {
    const source = useSource();
    // Kaynak değişmedikçe aynı sonuç dönsün diye son hesap önbellekte tutulur.
    return memoizedSelect(source, select);
  };
}

const derivedCache = new WeakMap<LiveQueryState, Map<unknown, LiveQueryState>>();

function memoizedSelect(source: LiveQueryState, select: (docs: LiveDoc[]) => LiveDoc[]): LiveQueryState {
  let bySelector = derivedCache.get(source);
  if (!bySelector) {
    bySelector = new Map();
    derivedCache.set(source, bySelector);
  }
  let result = bySelector.get(select);
  if (!result) {
    result = { ...source, docs: select(source.docs) } as LiveQueryState;
    bySelector.set(select, result);
  }
  return result;
}
