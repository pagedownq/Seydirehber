import { MaterialCommunityIcons, MaterialIcons } from '@expo/vector-icons';
import { LinearGradient } from 'expo-linear-gradient';
import { type Href, router } from 'expo-router';
import { StatusBar } from 'expo-status-bar';
import { FlatList, Pressable, StyleSheet, Text, View } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';

import { CachedImage } from '@/components/cached-image';
import { FavoriteButton } from '@/components/favorite-button';
import { type FavoriteItem, useFavoritesStore } from '@/features/favorites/favorites-store';
import { useDocument } from '@/features/firestore/use-document';
import { haptics } from '@/services/haptics';
import { colors, fonts, typography } from '@/theme';
import { int, str, toStr } from '@/utils/firestore-values';
import { goBack } from '@/utils/navigation';

// Flutter lib/features/favorites/screens/favorites_screen.dart karşılığı.
export function FavoritesScreen() {
  const insets = useSafeAreaInsets();
  const favorites = useFavoritesStore((state) => state.items);

  return (
    <View style={styles.container}>
      <StatusBar style="dark" />
      <View style={[styles.appBar, { paddingTop: insets.top }]}>
        <View style={styles.toolbar}>
          <Pressable hitSlop={8} style={styles.backButton} onPress={goBack}>
            <MaterialIcons name="arrow-back" size={24} color={colors.textPrimary} />
          </Pressable>
          <Text style={typography.appBarTitle}>Favorilerim</Text>
        </View>
      </View>
      {favorites.length === 0 ? (
        <View style={styles.empty}>
          <MaterialIcons name="favorite-border" size={64} color={colors.textLight} />
          <Text style={[typography.bodyMedium, { marginTop: 16 }]}>Henüz favori eklemediniz</Text>
        </View>
      ) : (
        <FlatList
          data={favorites}
          keyExtractor={(item) => `${item.id}:${item.type}`}
          contentContainerStyle={{ padding: 16 }}
          renderItem={({ item }) => <FavoriteItemCard item={item} />}
        />
      )}
    </View>
  );
}

function FavoriteItemCard({ item }: { item: FavoriteItem }) {
  const collection = item.type === 'company' ? 'firmalar' : 'gezilecek_yerler';
  const routePrefix = item.type === 'company' ? 'companies' : 'places';
  const document = useDocument(collection, item.id);

  // Flutter: doküman yoksa ya da yüklenmediyse kart hiç gösterilmez.
  if (document.status !== 'ready') return null;

  const { data } = document;
  const name = str(data.ad, str(data.name));
  const imageUrl = str(data.image_url, str(data.gorsel));
  const viewCount = int(data.goruntulenme);
  const category = str(data.kategori);
  const rawAddress = toStr(data.konum ?? data.adres ?? '');
  const address = rawAddress.startsWith('http') ? '' : rawAddress;

  return (
    <Pressable
      onPress={() => {
        haptics.selection();
        router.push(`/${routePrefix}/${item.id}` as Href);
      }}
      style={styles.card}>
      <View style={styles.clip}>
        <CachedImage imageUrl={imageUrl} isCompany={item.type === 'company'} />
        {category ? (
          <View style={styles.category}>
            <Text style={styles.categoryText}>{category}</Text>
          </View>
        ) : null}
        <View style={styles.favorite}>
          <FavoriteButton id={item.id} type={item.type} size={20} />
        </View>
        <LinearGradient colors={['rgba(0, 0, 0, 0)', 'rgba(0, 0, 0, 0.8)']} style={styles.info}>
          <Text style={styles.name} numberOfLines={1}>
            {name}
          </Text>
          <View style={styles.metaRow}>
            <View style={styles.addressRow}>
              {address ? (
                <>
                  <MaterialCommunityIcons name="map-marker-outline" size={14} color="rgba(255, 255, 255, 0.7)" />
                  <Text style={styles.address} numberOfLines={1}>
                    {address}
                  </Text>
                </>
              ) : null}
            </View>
            {item.type === 'company' && (
              <>
                <MaterialCommunityIcons name="eye-outline" size={14} color="rgba(255, 255, 255, 0.7)" />
                <Text style={styles.viewCount}>{viewCount}</Text>
              </>
            )}
          </View>
        </LinearGradient>
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
    paddingHorizontal: 4,
  },
  backButton: {
    width: 48,
    height: 48,
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: 8,
  },
  empty: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
  card: {
    height: 220,
    // Flutter'da kartlar arasında boşluk yoktu (kullanıcı isteğiyle eklendi).
    marginBottom: 16,
    borderRadius: 20,
    backgroundColor: colors.white,
    shadowColor: '#000000',
    shadowOpacity: 0.1,
    shadowRadius: 10,
    shadowOffset: { width: 0, height: 4 },
    elevation: 4,
  },
  clip: {
    flex: 1,
    borderRadius: 20,
    overflow: 'hidden',
  },
  category: {
    position: 'absolute',
    top: 12,
    left: 12,
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 8,
    backgroundColor: 'rgba(76, 175, 80, 0.9)',
  },
  categoryText: {
    fontFamily: fonts.semiBold,
    fontSize: 12,
    color: colors.white,
  },
  favorite: {
    position: 'absolute',
    top: 4,
    right: 4,
  },
  info: {
    position: 'absolute',
    left: 0,
    right: 0,
    bottom: 0,
    padding: 16,
  },
  name: {
    fontFamily: fonts.bold,
    fontSize: 18,
    color: colors.white,
  },
  metaRow: {
    marginTop: 4,
    flexDirection: 'row',
    alignItems: 'center',
  },
  addressRow: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
  },
  address: {
    flex: 1,
    fontFamily: fonts.regular,
    fontSize: 12,
    color: 'rgba(255, 255, 255, 0.7)',
  },
  viewCount: {
    marginLeft: 4,
    fontFamily: fonts.regular,
    fontSize: 11,
    color: 'rgba(255, 255, 255, 0.7)',
  },
});
