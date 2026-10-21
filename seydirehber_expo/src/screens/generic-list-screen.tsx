import { MaterialCommunityIcons, MaterialIcons } from '@expo/vector-icons';
import { LinearGradient } from 'expo-linear-gradient';
import { type Href, router } from 'expo-router';
import { StatusBar } from 'expo-status-bar';
import { useEffect, useState } from 'react';
import { FlatList, Pressable, StyleSheet, Text, useWindowDimensions, View } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';

import { CachedImage } from '@/components/cached-image';
import { EmptyState } from '@/components/empty-state';
import { ErrorView } from '@/components/error-view';
import { shareContent } from '@/components/share-button';
import { ListCardShimmer } from '@/components/shimmer';
import type { LiveQueryHook } from '@/features/firestore/live-query';
import { type CachedItem, getList, saveList } from '@/features/list/manual-cache';
import { haptics } from '@/services/haptics';
import { colors, fonts, gradientDirection, gradients } from '@/theme';
import { int, isTimestamp, str, toStr } from '@/utils/firestore-values';
import { goBack } from '@/utils/navigation';

// Flutter lib/core/widgets/generic_list_screen.dart karşılığı.
type GenericListScreenProps = {
  title: string;
  useQuery: LiveQueryHook;
  routePrefix: 'events' | 'places' | 'companies';
  showViewCount?: boolean;
  cacheKey?: string;
  useGrid?: boolean;
  showRating?: boolean;
};

const BACKGROUND = '#F8F9FA';

function isNewCompany(routePrefix: string, createdAt: unknown) {
  return (
    routePrefix === 'companies' &&
    isTimestamp(createdAt) &&
    Math.floor((Date.now() - createdAt.toMillis()) / 86_400_000) < 30
  );
}

function isNotExpired(item: CachedItem) {
  const expiry = item.expiry_date;
  if (expiry == null) return true;
  return isTimestamp(expiry) ? expiry.toDate() > new Date() : true;
}

export function GenericListScreen({
  title,
  useQuery,
  routePrefix,
  showViewCount = false,
  cacheKey,
  useGrid = false,
  showRating = false,
}: GenericListScreenProps) {
  const insets = useSafeAreaInsets();
  const state = useQuery();
  const [manualCache, setManualCache] = useState<CachedItem[] | null>(null);

  const liveItems: CachedItem[] = state.docs.map((d) => ({ ...d.data, id: d.id }));
  const hasLiveData = state.status === 'success' && liveItems.length > 0;

  // Başarılı veri ek güvence için saklanır; hata ya da boş liste gelirse önbellek okunur.
  useEffect(() => {
    if (!cacheKey) return;
    if (hasLiveData) {
      saveList(cacheKey, liveItems);
    } else if (state.status !== 'loading') {
      getList(cacheKey).then(setManualCache);
    }
    // liveItems her render'da yeni dizi; kaynak değişimini state.docs temsil ediyor.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [cacheKey, state.status, state.docs]);

  let body;
  if (state.status === 'loading') {
    body = <ShimmerLoading useGrid={useGrid} />;
  } else if (state.status === 'error') {
    body =
      manualCache && manualCache.length > 0 ? (
        <ItemList items={manualCache} fromCache {...{ useGrid, routePrefix, showViewCount, showRating }} />
      ) : (
        <ErrorView
          message="Bilgileri güncellemek için lütfen internet bağlantınızı kontrol edin."
          onRetry={() => useQuery.refresh()}
        />
      );
  } else if (liveItems.length === 0) {
    body =
      manualCache && manualCache.length > 0 ? (
        <ItemList items={manualCache} fromCache {...{ useGrid, routePrefix, showViewCount, showRating }} />
      ) : (
        <EmptyState
          icon="inventory-2"
          title={`Henüz ${title} Eklenmedi`}
          subtitle="Burayı canlandırmak için biraz bekleyin veya aramaya devam edin."
        />
      );
  } else {
    body = (
      <ItemList
        items={liveItems.filter(isNotExpired)}
        fromCache={false}
        {...{ useGrid, routePrefix, showViewCount, showRating }}
      />
    );
  }

  return (
    <View style={styles.container}>
      <StatusBar style="light" />
      <View style={[styles.appBar, { paddingTop: insets.top }]}>
        <View style={styles.toolbar}>
          <Pressable
            hitSlop={8}
            style={styles.iconButton}
            onPress={() => {
              haptics.selection();
              goBack();
            }}>
            <MaterialIcons name="arrow-back" size={22} color={colors.white} />
          </Pressable>
          <Text style={styles.title} numberOfLines={1}>
            {title}
          </Text>
          <Pressable
            hitSlop={8}
            style={styles.iconButton}
            onPress={() => {
              haptics.selection();
              shareContent(`Seydi Rehber - ${title} listesine göz at!`);
            }}>
            <MaterialIcons name="share" size={22} color={colors.white} />
          </Pressable>
        </View>
      </View>
      <View style={{ flex: 1 }}>{body}</View>
    </View>
  );
}

function ShimmerLoading({ useGrid }: { useGrid: boolean }) {
  const { width } = useWindowDimensions();
  if (useGrid) {
    const itemWidth = (width - 32 - 16) / 2;
    return (
      <View style={styles.shimmerGrid}>
        {Array.from({ length: 6 }, (_, i) => (
          <View key={i} style={{ width: itemWidth, height: itemWidth / 0.75 }}>
            <ListCardShimmer isGrid />
          </View>
        ))}
      </View>
    );
  }
  return (
    <View style={styles.shimmerList}>
      {Array.from({ length: 6 }, (_, i) => (
        <ListCardShimmer key={i} />
      ))}
    </View>
  );
}

type ItemListProps = {
  items: CachedItem[];
  fromCache: boolean;
  useGrid: boolean;
  routePrefix: string;
  showViewCount: boolean;
  showRating: boolean;
};

function ItemList({ items, fromCache, useGrid, routePrefix, showViewCount, showRating }: ItemListProps) {
  const { width } = useWindowDimensions();
  const open = (id: string) => {
    haptics.selection();
    router.push(`/${routePrefix}/${id}` as Href);
  };

  if (useGrid) {
    const itemWidth = (width - 32 - 16) / 2;
    return (
      <FlatList
        data={items}
        keyExtractor={(item) => item.id}
        numColumns={2}
        columnWrapperStyle={{ gap: 16 }}
        contentContainerStyle={styles.gridContent}
        renderItem={({ item }) => (
          <View style={{ width: itemWidth, height: itemWidth / 0.54 }}>
            <GridCard item={item} routePrefix={routePrefix} onPress={() => open(item.id)} />
          </View>
        )}
      />
    );
  }

  return (
    <FlatList
      data={items}
      keyExtractor={(item) => item.id}
      contentContainerStyle={styles.listContent}
      renderItem={({ item }) => (
        <ListCard
          item={item}
          fromCache={fromCache}
          routePrefix={routePrefix}
          showViewCount={showViewCount}
          showRating={showRating}
          onPress={() => open(item.id)}
        />
      )}
    />
  );
}

function CategoryBadge({ category, offset }: { category: string; offset: number }) {
  return (
    <LinearGradient
      colors={gradients.primary}
      start={gradientDirection.start}
      end={gradientDirection.end}
      style={[styles.categoryBadge, { top: offset, left: offset }]}>
      <Text style={styles.categoryText}>{category.toUpperCase()}</Text>
    </LinearGradient>
  );
}

function ListCard({
  item,
  fromCache,
  routePrefix,
  showViewCount,
  showRating,
  onPress,
}: {
  item: CachedItem;
  fromCache: boolean;
  routePrefix: string;
  showViewCount: boolean;
  showRating: boolean;
  onPress: () => void;
}) {
  const name = str(item.ad, str(item.name));
  const imageUrl = str(item.image_url, str(item.gorsel));
  const viewCount = int(item.goruntulenme);
  const category = str(item.kategori);
  const rawAdres = str(item.adres);
  const rawKonum = str(item.konum);
  const locationText = rawAdres || (rawKonum.startsWith('http') ? 'Seydişehir, Konya' : rawKonum);
  const isNew = isNewCompany(routePrefix, item.created_at);

  return (
    <Pressable onPress={onPress} style={styles.listCard}>
      <View style={styles.listClip}>
        <CachedImage
          imageUrl={imageUrl}
          isCompany={routePrefix === 'companies'}
          isEvent={routePrefix === 'events'}
        />
        <LinearGradient
          colors={['rgba(0, 0, 0, 0.1)', 'transparent', 'rgba(0, 0, 0, 0.6)']}
          style={StyleSheet.absoluteFill}
        />
        {category ? <CategoryBadge category={category} offset={15} /> : null}
        {isNew && (
          <LinearGradient
            colors={['#FF5252', '#FF1744']}
            start={{ x: 0, y: 0.5 }}
            end={{ x: 1, y: 0.5 }}
            style={styles.newBadgeLarge}>
            <Text style={styles.newTextLarge}>YENİ</Text>
          </LinearGradient>
        )}
        {fromCache && (
          <View style={styles.cacheBadge}>
            <MaterialIcons name="storage" size={12} color={colors.white} />
            <Text style={styles.cacheText}>ÖNBELLEK</Text>
          </View>
        )}
        <LinearGradient colors={['transparent', 'rgba(0, 0, 0, 0.8)']} style={styles.listInfo}>
          <View style={{ flex: 1 }}>
            <Text style={styles.listName} numberOfLines={1}>
              {name}
            </Text>
            <View style={styles.listMetaRow}>
              <MaterialIcons
                name={showRating ? 'star' : 'location-on'}
                size={14}
                color={showRating ? '#FFEB3B' : 'rgba(255, 255, 255, 0.7)'}
              />
              <Text style={styles.listMetaText} numberOfLines={1}>
                {showRating ? `(${toStr(item.yorum_sayisi, '0')} Değerlendirme)` : locationText}
              </Text>
            </View>
          </View>
          {showViewCount && (
            <View style={styles.viewChip}>
              <MaterialIcons name="remove-red-eye" size={14} color={colors.white} />
              <Text style={styles.viewText}>{viewCount}</Text>
            </View>
          )}
        </LinearGradient>
      </View>
    </Pressable>
  );
}

function GridCard({ item, routePrefix, onPress }: { item: CachedItem; routePrefix: string; onPress: () => void }) {
  const name = str(item.ad, str(item.name));
  const imageUrl = str(item.image_url, str(item.gorsel));
  const category = str(item.kategori);
  const rawAdres = str(item.adres);
  const rawKonum = str(item.konum);
  const address = rawAdres || (rawKonum.startsWith('http') ? '' : rawKonum);
  const isNew = isNewCompany(routePrefix, item.created_at);

  return (
    <Pressable onPress={onPress}>
      <View style={styles.gridImage}>
        <View style={styles.gridClip}>
          <CachedImage imageUrl={imageUrl} isEvent={routePrefix === 'events'} />
          {category ? <CategoryBadge category={category} offset={10} /> : null}
          {isNew && (
            <LinearGradient
              colors={['#FF5252', '#FF1744']}
              start={{ x: 0, y: 0.5 }}
              end={{ x: 1, y: 0.5 }}
              style={styles.newBadgeSmall}>
              <Text style={styles.newTextSmall}>YENİ</Text>
            </LinearGradient>
          )}
        </View>
      </View>
      <Text style={styles.gridName} numberOfLines={2}>
        {name}
      </Text>
      {address ? (
        <View style={styles.gridAddressRow}>
          <MaterialCommunityIcons name="map-marker-outline" size={12} color={colors.textLight} />
          <Text style={styles.gridAddress} numberOfLines={1}>
            {address}
          </Text>
        </View>
      ) : null}
    </Pressable>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: BACKGROUND,
  },
  appBar: {
    backgroundColor: colors.primary,
  },
  toolbar: {
    height: 56,
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 4,
  },
  iconButton: {
    width: 48,
    height: 48,
    alignItems: 'center',
    justifyContent: 'center',
  },
  title: {
    flex: 1,
    fontFamily: fonts.bold,
    fontSize: 17,
    color: colors.white,
    textAlign: 'center',
  },
  shimmerGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 16,
    padding: 16,
  },
  shimmerList: {
    padding: 16,
    gap: 16,
  },
  gridContent: {
    paddingTop: 20,
    paddingHorizontal: 16,
    paddingBottom: 40,
    gap: 24,
  },
  listContent: {
    paddingTop: 20,
    paddingHorizontal: 16,
    paddingBottom: 40,
  },
  listCard: {
    height: 220,
    marginBottom: 20,
    borderRadius: 20,
    backgroundColor: colors.white,
    shadowColor: '#000000',
    shadowOpacity: 0.12,
    shadowRadius: 15,
    shadowOffset: { width: 0, height: 8 },
    elevation: 6,
  },
  listClip: {
    flex: 1,
    borderRadius: 20,
    overflow: 'hidden',
  },
  // Gölgeli görünümlerde düz arka plan: iOS gölgeyi verimli çizebilsin (gradyan üstünü kaplar).
  categoryBadge: {
    position: 'absolute',
    paddingHorizontal: 10,
    paddingVertical: 5,
    borderRadius: 8,
    backgroundColor: gradients.primary[0],
    borderWidth: 0.5,
    borderColor: 'rgba(255, 255, 255, 0.2)',
    shadowColor: '#000000',
    shadowOpacity: 0.2,
    shadowRadius: 6,
    shadowOffset: { width: 0, height: 2 },
    elevation: 3,
  },
  categoryText: {
    fontFamily: fonts.black,
    fontSize: 9,
    letterSpacing: 0.5,
    color: colors.white,
    textShadowColor: 'rgba(0, 0, 0, 0.26)',
    textShadowOffset: { width: 0, height: 1 },
    textShadowRadius: 2,
  },
  newBadgeLarge: {
    position: 'absolute',
    top: 15,
    right: 15,
    paddingHorizontal: 12,
    paddingVertical: 7,
    borderRadius: 10,
    backgroundColor: '#FF5252',
    shadowColor: '#000000',
    shadowOpacity: 0.3,
    shadowRadius: 10,
    shadowOffset: { width: 0, height: 4 },
    elevation: 4,
  },
  newTextLarge: {
    fontFamily: fonts.black,
    fontSize: 10,
    letterSpacing: 0.5,
    color: colors.white,
  },
  cacheBadge: {
    position: 'absolute',
    top: 15,
    right: 15,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    paddingHorizontal: 8,
    paddingVertical: 4,
    borderRadius: 8,
    backgroundColor: 'rgba(255, 152, 0, 0.9)',
  },
  cacheText: {
    fontFamily: fonts.bold,
    fontSize: 10,
    color: colors.white,
  },
  listInfo: {
    position: 'absolute',
    left: 0,
    right: 0,
    bottom: 0,
    flexDirection: 'row',
    alignItems: 'flex-end',
    paddingTop: 40,
    paddingHorizontal: 16,
    paddingBottom: 16,
  },
  listName: {
    fontFamily: fonts.bold,
    fontSize: 18,
    letterSpacing: -0.5,
    color: colors.white,
  },
  listMetaRow: {
    marginTop: 6,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
  },
  listMetaText: {
    flex: 1,
    fontFamily: fonts.medium,
    fontSize: 11,
    color: 'rgba(255, 255, 255, 0.8)',
  },
  viewChip: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    paddingHorizontal: 8,
    paddingVertical: 4,
    borderRadius: 8,
    backgroundColor: 'rgba(255, 255, 255, 0.2)',
  },
  viewText: {
    fontFamily: fonts.bold,
    fontSize: 11,
    color: colors.white,
  },
  gridImage: {
    aspectRatio: 0.82,
    borderRadius: 16,
    backgroundColor: colors.white,
    shadowColor: '#000000',
    shadowOpacity: 0.08,
    shadowRadius: 10,
    shadowOffset: { width: 0, height: 4 },
    elevation: 3,
  },
  gridClip: {
    flex: 1,
    borderRadius: 16,
    overflow: 'hidden',
  },
  newBadgeSmall: {
    position: 'absolute',
    top: 10,
    right: 10,
    paddingHorizontal: 10,
    paddingVertical: 5,
    borderRadius: 8,
  },
  newTextSmall: {
    fontFamily: fonts.black,
    fontSize: 9,
    letterSpacing: 0.5,
    color: colors.white,
  },
  gridName: {
    marginTop: 10,
    paddingHorizontal: 4,
    fontFamily: fonts.bold,
    fontSize: 15,
    lineHeight: 16.5,
    letterSpacing: -0.3,
    color: '#000000',
  },
  gridAddressRow: {
    marginTop: 4,
    paddingHorizontal: 4,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
  },
  gridAddress: {
    flex: 1,
    fontFamily: fonts.regular,
    fontSize: 11,
    color: colors.textLight,
  },
});
