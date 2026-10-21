import { MaterialCommunityIcons, MaterialIcons } from '@expo/vector-icons';
import { collection, query as firestoreQuery } from '@react-native-firebase/firestore';
import { type Href, router } from 'expo-router';
import { StatusBar } from 'expo-status-bar';
import type { ComponentProps } from 'react';
import { useEffect, useState } from 'react';
import { FlatList, Pressable, ScrollView, StyleSheet, Text, TextInput, View } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';

import { CachedImage } from '@/components/cached-image';
import { EmptyState } from '@/components/empty-state';
import { ShimmerSearchList } from '@/components/shimmer';
import { createLiveQuery, type LiveDoc } from '@/features/firestore/live-query';
import {
  addSearchTerm,
  clearSearchHistory,
  removeSearchTerm,
  useSearchHistoryStore,
  useSearchQueryStore,
} from '@/features/search/search-store';
import { db } from '@/services/firebase';
import { haptics } from '@/services/haptics';
import { colors, fonts, typography } from '@/theme';
import { isTimestamp, str, toStr } from '@/utils/firestore-values';
import { goBack } from '@/utils/navigation';

// Flutter lib/features/search/screens/search_screen.dart karşılığı.
type IconName = ComponentProps<typeof MaterialIcons>['name'];

const DEBOUNCE_MS = 500;

const SERVICES: { title: string; route: string; icon: IconName }[] = [
  { title: 'Hava Durumu', route: '/weather', icon: 'cloud-queue' },
  { title: 'Nöbetçi Eczane', route: '/pharmacy', icon: 'local-pharmacy' },
  { title: 'Noterler', route: '/noterler', icon: 'gavel' },
  { title: 'Halk Pazarları', route: '/pazarlar', icon: 'storefront' },
  { title: 'Otobüs Saatleri', route: '/otobus', icon: 'directions-bus' },
  { title: 'İş İlanları', route: '/is-ilanlari', icon: 'work' },
  { title: 'Haberler', route: '/news', icon: 'newspaper' },
  { title: 'Fırsat Kuponları', route: '/coupons', icon: 'confirmation-number' },
];

// Flutter her bölüm için koleksiyonun tamamını dinliyor. "Gezilecek Yerler" bölümü Flutter'da
// `yerler` koleksiyonunu sorguluyor (gerçek koleksiyon `gezilecek_yerler`); davranış korunuyor.
const SECTIONS = [
  { title: 'Fırsat Kuponları', routePrefix: '/coupons', useDocs: createSearchQuery('coupons') },
  { title: 'Etkinlikler', routePrefix: '/events', useDocs: createSearchQuery('etkinlikler') },
  { title: 'Gezilecek Yerler', routePrefix: '/places', useDocs: createSearchQuery('yerler') },
  { title: 'Firmalar', routePrefix: '/companies', useDocs: createSearchQuery('firmalar') },
];

function createSearchQuery(collectionPath: string) {
  return createLiveQuery(`search:${collectionPath}`, () => firestoreQuery(collection(db, collectionPath)));
}

/** Flutter debouncedSearchQueryProvider: boşsa hemen '', değilse 500 ms sonra değer. */
function useDebounced(value: string) {
  const [debounced, setDebounced] = useState(value);
  useEffect(() => {
    if (!value) return;
    const timer = setTimeout(() => setDebounced(value), DEBOUNCE_MS);
    return () => clearTimeout(timer);
  }, [value]);
  return value ? debounced : '';
}

export function SearchScreen({ initialQuery }: { initialQuery?: string }) {
  const insets = useSafeAreaInsets();
  const query = useSearchQueryStore((state) => state.query);
  const [text, setText] = useState(initialQuery ?? '');

  useEffect(() => {
    if (initialQuery != null) useSearchQueryStore.setState({ query: initialQuery });
  }, [initialQuery]);

  const setQuery = (value: string) => useSearchQueryStore.setState({ query: value });

  return (
    <View style={styles.container}>
      <StatusBar style="dark" />
      <View style={[styles.appBar, { paddingTop: insets.top }]}>
        <View style={styles.toolbar}>
          <Pressable
            hitSlop={8}
            style={styles.iconButton}
            onPress={() => {
              haptics.selection();
              goBack();
            }}>
            <MaterialIcons name="arrow-back-ios-new" size={20} color={colors.textPrimary} />
          </Pressable>
          <TextInput
            value={text}
            autoFocus
            onChangeText={(value) => {
              setText(value);
              setQuery(value);
            }}
            onSubmitEditing={(event) => {
              const value = event.nativeEvent.text;
              if (value.trim()) addSearchTerm(value);
            }}
            placeholder="Firma, yer, kupon veya kategori ara..."
            placeholderTextColor={colors.textLight}
            style={styles.input}
            returnKeyType="search"
          />
          {query ? (
            <Pressable
              hitSlop={8}
              style={styles.iconButton}
              onPress={() => {
                haptics.selection();
                setText('');
                setQuery('');
              }}>
              <MaterialIcons name="clear" size={20} color={colors.textLight} />
            </Pressable>
          ) : null}
          <Pressable
            style={styles.cancelButton}
            onPress={() => {
              haptics.selection();
              goBack();
            }}>
            <Text style={styles.cancelText}>Vazgeç</Text>
          </Pressable>
        </View>
      </View>
      {query ? (
        <SearchResults immediateQuery={query} />
      ) : (
        <SearchHistory
          onHistoryPress={(term) => {
            setText(term);
            setQuery(term);
          }}
        />
      )}
    </View>
  );
}

function SearchHistory({ onHistoryPress }: { onHistoryPress: (term: string) => void }) {
  const history = useSearchHistoryStore((state) => state.history);

  if (history.length === 0) {
    return (
      <EmptyState
        icon="search"
        title="Neyi Aramıştın?"
        subtitle="Aramak istediğin kelimeyi yukarıdaki kutuya yazarak Seydişehir'de keşfe çıkabilirsin."
      />
    );
  }

  return (
    <View style={{ flex: 1 }}>
      <View style={styles.historyHeader}>
        <Text style={typography.heading3}>Son Aramalar</Text>
        <Pressable
          style={styles.clearHistory}
          onPress={() => {
            haptics.selection();
            clearSearchHistory();
          }}>
          <Text style={styles.clearHistoryText}>Temizle</Text>
        </Pressable>
      </View>
      <FlatList
        data={history}
        keyExtractor={(term) => term}
        ItemSeparatorComponent={() => <View style={styles.divider} />}
        renderItem={({ item: term }) => (
          <Pressable
            style={styles.historyRow}
            onPress={() => {
              haptics.selection();
              onHistoryPress(term);
            }}>
            <MaterialIcons name="history" size={20} color={colors.textLight} />
            <Text style={[typography.bodyMedium, { flex: 1 }]}>{term}</Text>
            <Pressable
              hitSlop={8}
              style={styles.historyRemove}
              onPress={() => {
                haptics.selection();
                removeSearchTerm(term);
              }}>
              <MaterialIcons name="close" size={18} color={colors.textLight} />
            </Pressable>
          </Pressable>
        )}
      />
    </View>
  );
}

function SearchResults({ immediateQuery }: { immediateQuery: string }) {
  const debouncedQuery = useDebounced(immediateQuery);

  if (!debouncedQuery || debouncedQuery !== immediateQuery) {
    return (
      <View style={{ padding: 0 }}>
        <ShimmerSearchList />
      </View>
    );
  }

  const normalizedQuery = debouncedQuery.toLowerCase();
  const services = SERVICES.filter((s) => s.title.toLowerCase().includes(normalizedQuery));

  return (
    <ScrollView contentContainerStyle={{ padding: 16 }} keyboardShouldPersistTaps="handled">
      {services.length > 0 && (
        <>
          <Text style={[typography.heading3, styles.sectionTitle]}>Uygulama Özellikleri</Text>
          {services.map((service) => (
            <ResultRow
              key={service.route}
              leading={
                <View style={styles.serviceIcon}>
                  <MaterialIcons name={service.icon} size={24} color={colors.primary} />
                </View>
              }
              title={service.title}
              subtitle={<Text style={styles.subtitle}>Uygulama içi kısayol</Text>}
              onPress={() => {
                haptics.selection();
                addSearchTerm(normalizedQuery);
                router.push(service.route as Href);
              }}
            />
          ))}
          <View style={styles.sectionDivider} />
        </>
      )}
      {SECTIONS.map((section) => (
        <SearchCollectionSection key={section.title} {...section} query={normalizedQuery} />
      ))}
    </ScrollView>
  );
}

function matches(doc: LiveDoc, query: string) {
  const data = doc.data;
  if (data.isActive === false) return false;
  if (isTimestamp(data.expiry_date) && data.expiry_date.toDate() < new Date()) return false;

  const name = toStr(data.ad ?? data.name ?? data.title ?? '').toLowerCase();
  const category = toStr(data.kategori ?? '').toLowerCase();
  const companyName = toStr(data.companyName ?? '').toLowerCase();
  const description = toStr(data.description ?? data.aciklama ?? '').toLowerCase();
  return (
    name.includes(query) || category.includes(query) || companyName.includes(query) || description.includes(query)
  );
}

function SearchCollectionSection({
  title,
  routePrefix,
  useDocs,
  query,
}: {
  title: string;
  routePrefix: string;
  useDocs: () => { status: string; docs: LiveDoc[] };
  query: string;
}) {
  const state = useDocs();
  if (state.status !== 'success') return null;

  const docs = state.docs.filter((doc) => matches(doc, query));
  if (docs.length === 0) return null;

  return (
    <>
      <Text style={[typography.heading3, styles.sectionTitle]}>{title}</Text>
      {docs.map((doc) => {
        const data = doc.data;
        const name = toStr(data.ad ?? data.name ?? data.title ?? '');
        const imageUrl = toStr(data.image_url ?? data.gorsel ?? '');
        const category = toStr(data.kategori ?? data.companyName ?? '');
        const rawAdres = str(data.adres);
        const rawKonum = str(data.konum);
        const address = rawAdres || (rawKonum.startsWith('http') ? '' : rawKonum);

        return (
          <ResultRow
            key={doc.id}
            leading={
              routePrefix === '/coupons' ? (
                <View style={styles.serviceIcon}>
                  <MaterialCommunityIcons name="ticket-confirmation-outline" size={24} color={colors.primary} />
                </View>
              ) : (
                <CachedImage
                  imageUrl={imageUrl}
                  width={50}
                  height={50}
                  borderRadius={8}
                  isCompany={routePrefix === '/companies'}
                  isEvent={routePrefix === '/events'}
                />
              )
            }
            title={name}
            subtitle={
              <>
                {category ? <Text style={styles.category}>{category}</Text> : null}
                {address ? (
                  <Text style={styles.subtitle} numberOfLines={1}>
                    {address}
                  </Text>
                ) : null}
              </>
            }
            onPress={() => {
              haptics.selection();
              addSearchTerm(query);
              router.push(`${routePrefix}/${doc.id}` as Href);
            }}
          />
        );
      })}
      <View style={styles.sectionDivider} />
    </>
  );
}

function ResultRow({
  leading,
  title,
  subtitle,
  onPress,
}: {
  leading: React.ReactNode;
  title: string;
  subtitle: React.ReactNode;
  onPress: () => void;
}) {
  return (
    <Pressable onPress={onPress} style={styles.resultRow}>
      {leading}
      <View style={{ flex: 1 }}>
        <Text style={typography.bodyLarge}>{title}</Text>
        {subtitle}
      </View>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.background,
  },
  appBar: {
    backgroundColor: colors.white,
  },
  toolbar: {
    height: 56,
    flexDirection: 'row',
    alignItems: 'center',
  },
  iconButton: {
    width: 48,
    height: 48,
    alignItems: 'center',
    justifyContent: 'center',
  },
  input: {
    flex: 1,
    ...typography.bodyMedium,
    paddingVertical: 8,
  },
  cancelButton: {
    paddingHorizontal: 12,
    paddingVertical: 10,
  },
  cancelText: {
    fontFamily: fonts.bold,
    fontSize: 14,
    color: colors.primary,
  },
  historyHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingTop: 24,
    paddingHorizontal: 16,
    paddingBottom: 8,
  },
  clearHistory: {
    paddingHorizontal: 12,
    paddingVertical: 8,
  },
  clearHistoryText: {
    fontFamily: fonts.medium,
    fontSize: 14,
    color: colors.error,
  },
  historyRow: {
    minHeight: 56,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 16,
    paddingHorizontal: 16,
  },
  historyRemove: {
    padding: 8,
  },
  divider: {
    height: 1,
    backgroundColor: colors.divider,
  },
  sectionTitle: {
    paddingVertical: 8,
  },
  sectionDivider: {
    height: 1,
    marginVertical: 8,
    backgroundColor: colors.divider,
  },
  resultRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 16,
    paddingVertical: 8,
  },
  serviceIcon: {
    width: 50,
    height: 50,
    alignItems: 'center',
    justifyContent: 'center',
    borderRadius: 8,
    backgroundColor: colors.primarySurface,
  },
  subtitle: {
    fontFamily: fonts.regular,
    fontSize: 14,
    color: colors.textSecondary,
  },
  category: {
    fontFamily: fonts.semiBold,
    fontSize: 12,
    color: colors.primary,
  },
});
