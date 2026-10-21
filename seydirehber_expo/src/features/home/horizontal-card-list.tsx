import { MaterialCommunityIcons, MaterialIcons } from '@expo/vector-icons';
import { LinearGradient } from 'expo-linear-gradient';
import { FlatList, Pressable, StyleSheet, Text, View } from 'react-native';

import { CachedImage } from '@/components/cached-image';
import { HorizontalCardShimmer } from '@/components/shimmer';
import type { FirestoreData, LiveDoc, LiveQueryState } from '@/features/firestore/live-query';
import { haptics } from '@/services/haptics';
import { colors, fonts, gradientDirection, gradients, typography } from '@/theme';
import { int, isTimestamp, str, toStr } from '@/utils/firestore-values';

// Flutter lib/features/home/widgets/horizontal_card_list.dart karşılığı.
export type CardType = 'event' | 'place' | 'company';

type HorizontalCardListProps = {
  state: LiveQueryState;
  type: CardType;
  onPress: (id: string) => void;
  showRating?: boolean;
};

const EMPTY_TITLE: Record<CardType, string> = { event: 'Etkinlik', place: 'Yer', company: 'Firma' };

/** `expiry_date` geçmişse gizlenir; alan yoksa ya da tarih değilse gösterilir. */
function isNotExpired(item: LiveDoc) {
  const expiry = item.data.expiry_date;
  if (expiry == null) return true;
  return isTimestamp(expiry) ? expiry.toDate() > new Date() : true;
}

/** Flutter: DateTime.now().difference(createdAt).inDays < days */
function isAddedWithinDays(createdAt: unknown, days: number) {
  return isTimestamp(createdAt) && Math.floor((Date.now() - createdAt.toMillis()) / 86_400_000) < days;
}

/** Flutter: adres yoksa konum (link değilse) gösterilir. */
function addressOf(data: FirestoreData) {
  const rawAdres = str(data.adres);
  const rawKonum = str(data.konum);
  return rawAdres || (rawKonum.startsWith('http') ? '' : rawKonum);
}

export function HorizontalCardList({ state, type, onPress, showRating = false }: HorizontalCardListProps) {
  const listHeight = type === 'company' ? 220 : 340;

  if (state.status === 'loading') {
    return (
      <View style={[styles.row, { height: listHeight }]}>
        {Array.from({ length: 3 }, (_, i) => (
          <HorizontalCardShimmer key={i} />
        ))}
      </View>
    );
  }

  if (state.status === 'error') {
    return (
      <View style={styles.errorBox}>
        <Text style={typography.bodyMedium}>Veriler yüklenemedi</Text>
      </View>
    );
  }

  const items = state.docs.filter(isNotExpired);

  if (items.length === 0) {
    return (
      <View style={styles.emptyBox}>
        <Text style={styles.emptyText}>Henüz {EMPTY_TITLE[type]} eklenmedi</Text>
      </View>
    );
  }

  return (
    <FlatList
      horizontal
      data={items}
      keyExtractor={(item) => item.id}
      showsHorizontalScrollIndicator={false}
      style={{ height: listHeight, flexGrow: 0 }}
      contentContainerStyle={styles.listContent}
      ItemSeparatorComponent={() => <View style={{ width: 12 }} />}
      renderItem={({ item }) => {
        const press = () => {
          haptics.selection();
          onPress(item.id);
        };
        return type === 'company' ? (
          <CompanyCard data={item.data} showRating={showRating} onPress={press} />
        ) : (
          <VerticalCard data={item.data} isEvent={type === 'event'} onPress={press} />
        );
      }}
    />
  );
}

function VerticalCard({ data, isEvent, onPress }: { data: FirestoreData; isEvent: boolean; onPress: () => void }) {
  const name = str(data.ad, str(data.name));
  const imageUrl = str(data.image_url, str(data.gorsel));
  const address = addressOf(data);

  return (
    <Pressable onPress={onPress} style={{ width: 220 }}>
      <CachedImage imageUrl={imageUrl} width={220} height={240} borderRadius={16} isEvent={isEvent} />
      <Text style={styles.cardTitle} numberOfLines={2}>
        {name}
      </Text>
      {isEvent && <EventDate data={data} />}
      {address ? (
        <View style={styles.metaRow}>
          <MaterialCommunityIcons name="map-marker-outline" size={12} color={colors.textLight} />
          <Text style={[typography.caption, styles.metaText]} numberOfLines={1}>
            {address}
          </Text>
        </View>
      ) : null}
    </Pressable>
  );
}

function EventDate({ data }: { data: FirestoreData }) {
  const startDate = data.baslangic_tarihi ?? data.baslangic_tarihi_str;
  if (startDate == null) return null;

  let dateStr: string;
  if (isTimestamp(startDate)) {
    const dt = startDate.toDate();
    dateStr = `${String(dt.getDate()).padStart(2, '0')}.${String(dt.getMonth() + 1).padStart(2, '0')}.${dt.getFullYear()}`;
  } else {
    dateStr = toStr(startDate);
  }

  return (
    <View style={styles.metaRow}>
      <MaterialIcons name="calendar-today" size={12} color={colors.primary} />
      <Text style={[typography.caption, styles.metaText, { color: colors.primary }]} numberOfLines={1}>
        {dateStr}
      </Text>
    </View>
  );
}

function CompanyCard({
  data,
  showRating,
  onPress,
}: {
  data: FirestoreData;
  showRating: boolean;
  onPress: () => void;
}) {
  const name = str(data.ad, str(data.name));
  const imageUrl = str(data.image_url, str(data.gorsel));
  const viewCount = int(data.goruntulenme);
  const category = str(data.kategori);
  const address = addressOf(data);
  const isNew = isAddedWithinDays(data.created_at, 30);

  return (
    <Pressable onPress={onPress} style={styles.companyCard}>
      <View style={styles.companyClip}>
        <CachedImage imageUrl={imageUrl} isCompany />
        <LinearGradient
          colors={['rgba(0, 0, 0, 0.2)', 'transparent', 'rgba(0, 0, 0, 0.8)']}
          locations={[0, 0.4, 0.9]}
          style={StyleSheet.absoluteFill}
        />
        {category ? (
          <LinearGradient
            colors={gradients.primary}
            start={gradientDirection.start}
            end={gradientDirection.end}
            style={[styles.badge, styles.categoryBadge]}>
            <Text style={[styles.badgeText, styles.badgeTextShadow]}>{category.toUpperCase()}</Text>
          </LinearGradient>
        ) : null}
        {isNew && (
          <LinearGradient
            colors={['#FF5252', '#FF1744']}
            start={{ x: 0, y: 0.5 }}
            end={{ x: 1, y: 0.5 }}
            style={[styles.badge, styles.newBadge]}>
            <Text style={styles.badgeText}>YENİ</Text>
          </LinearGradient>
        )}
        <LinearGradient colors={['transparent', 'rgba(0, 0, 0, 0.8)']} style={styles.companyInfo}>
          <Text style={styles.companyName} numberOfLines={1}>
            {name}
          </Text>
          <View style={styles.companyMetaRow}>
            <View style={styles.companyMeta}>
              {(address || showRating) && (
                <>
                  <MaterialIcons
                    name={showRating ? 'star' : 'location-on'}
                    size={14}
                    color={showRating ? '#FFEB3B' : 'rgba(255, 255, 255, 0.7)'}
                  />
                  <Text
                    numberOfLines={1}
                    style={[
                      styles.companyMetaText,
                      showRating
                        ? { color: '#FFEB3B', fontFamily: fonts.bold }
                        : { color: 'rgba(255, 255, 255, 0.7)' },
                    ]}>
                    {showRating ? `(${toStr(data.yorum_sayisi, '0')} Değerlendirme)` : address}
                  </Text>
                </>
              )}
            </View>
            <View style={styles.viewChip}>
              <MaterialIcons name="visibility" size={12} color={colors.white} />
              <Text style={styles.viewCount}>{viewCount}</Text>
            </View>
          </View>
        </LinearGradient>
      </View>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  row: {
    flexDirection: 'row',
    paddingHorizontal: 16,
  },
  listContent: {
    paddingHorizontal: 16,
  },
  errorBox: {
    height: 100,
    alignItems: 'center',
    justifyContent: 'center',
  },
  emptyBox: {
    height: 100,
    marginHorizontal: 16,
    alignItems: 'center',
    justifyContent: 'center',
    borderRadius: 16,
    borderWidth: 1,
    borderColor: colors.border,
    backgroundColor: colors.white,
  },
  emptyText: {
    ...typography.bodySmall,
    color: colors.textLight,
  },
  cardTitle: {
    marginTop: 8,
    fontFamily: fonts.bold,
    fontSize: 16,
    letterSpacing: -0.2,
    color: '#000000',
  },
  metaRow: {
    marginTop: 4,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
  },
  metaText: {
    flex: 1,
    color: colors.textLight,
  },
  companyCard: {
    width: 250,
    height: 218,
    marginBottom: 2,
    borderRadius: 18,
    backgroundColor: colors.white,
    shadowColor: '#000000',
    shadowOpacity: 0.1,
    shadowRadius: 8,
    shadowOffset: { width: 0, height: 4 },
    elevation: 4,
  },
  companyClip: {
    flex: 1,
    borderRadius: 18,
    overflow: 'hidden',
  },
  badge: {
    position: 'absolute',
    top: 12,
    paddingHorizontal: 10,
    paddingVertical: 5,
    borderRadius: 8,
    shadowColor: '#000000',
    shadowOpacity: 0.2,
    shadowRadius: 6,
    shadowOffset: { width: 0, height: 2 },
    elevation: 3,
  },
  // Gölgeli görünümlerde düz arka plan: iOS gölgeyi verimli çizebilsin (gradyan üstünü kaplar).
  categoryBadge: {
    left: 12,
    backgroundColor: gradients.primary[0],
    borderWidth: 0.5,
    borderColor: 'rgba(255, 255, 255, 0.2)',
  },
  newBadge: {
    right: 12,
    backgroundColor: '#FF5252',
  },
  badgeText: {
    fontFamily: fonts.black,
    fontSize: 9,
    letterSpacing: 0.5,
    color: colors.white,
  },
  badgeTextShadow: {
    textShadowColor: 'rgba(0, 0, 0, 0.26)',
    textShadowOffset: { width: 0, height: 1 },
    textShadowRadius: 2,
  },
  companyInfo: {
    position: 'absolute',
    left: 0,
    right: 0,
    bottom: 0,
    paddingTop: 32,
    paddingHorizontal: 12,
    paddingBottom: 12,
  },
  companyName: {
    fontFamily: fonts.bold,
    fontSize: 16,
    letterSpacing: -0.4,
    color: colors.white,
  },
  companyMetaRow: {
    marginTop: 4,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
  },
  companyMeta: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
  },
  companyMetaText: {
    flex: 1,
    fontFamily: fonts.regular,
    fontSize: 11,
  },
  viewChip: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 3,
    paddingHorizontal: 6,
    paddingVertical: 2,
    borderRadius: 6,
    backgroundColor: 'rgba(255, 255, 255, 0.2)',
  },
  viewCount: {
    fontFamily: fonts.bold,
    fontSize: 10,
    color: colors.white,
  },
});
