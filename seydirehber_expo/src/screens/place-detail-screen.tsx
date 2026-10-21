import { MaterialIcons } from '@expo/vector-icons';
import { StatusBar } from 'expo-status-bar';
import { ActivityIndicator, Pressable, StyleSheet, Text, View } from 'react-native';

import { CachedImage } from '@/components/cached-image';
import { CollapsingHeaderScreen } from '@/components/collapsing-header-screen';
import { FavoriteButton } from '@/components/favorite-button';
import { HeaderCircleButton } from '@/components/header-circle-button';
import { InteractiveMap } from '@/components/interactive-map';
import { ReviewSection } from '@/components/review-section';
import { shareContent } from '@/components/share-button';
import { DetailShimmer } from '@/components/shimmer';
import type { FirestoreData } from '@/features/firestore/live-query';
import { useDocument } from '@/features/firestore/use-document';
import { useCoordinates } from '@/features/map/use-coordinates';
import { haptics } from '@/services/haptics';
import { colors, fonts, typography } from '@/theme';
import { toStr } from '@/utils/firestore-values';
import { openMapWithAddress } from '@/utils/map';
import { goBack } from '@/utils/navigation';

// Flutter lib/features/places/screens/place_detail_screen.dart karşılığı.

/** Öncelik sırasıyla ilk dolu alan (Flutter getField). */
function getField(data: FirestoreData, keys: string[]) {
  for (const key of keys) {
    const value = data[key] == null ? '' : String(data[key]).trim();
    if (value) return value;
  }
  return '';
}

export function PlaceDetailScreen({ placeId }: { placeId: string }) {
  const place = useDocument('gezilecek_yerler', placeId);
  const konum = place.status === 'ready' ? getField(place.data, ['konum', 'location', 'address']) : '';
  const coordinates = useCoordinates(konum);

  if (place.status === 'loading') {
    return (
      <View style={styles.screen}>
        <DetailShimmer />
      </View>
    );
  }
  if (place.status !== 'ready') {
    return (
      <View style={[styles.screen, styles.center]}>
        <Text>Bir hata oluştu veya veri bulunamadı.</Text>
      </View>
    );
  }

  const { data } = place;
  const name = toStr(data.ad, toStr(data.name));
  const imageUrl = toStr(data.image_url, toStr(data.gorsel));
  const hakkinda = getField(data, ['hakkinda', 'aciklama', 'description', 'info']);
  const tarihce = getField(data, ['tarihce', 'history']);

  return (
    <>
      <StatusBar style="light" />
      <CollapsingHeaderScreen
        expandedHeight={350}
        barColor={colors.primary}
        bounces
        background={<CachedImage imageUrl={imageUrl} />}
        overlayColors={['rgba(0, 0, 0, 0.4)', 'transparent', 'rgba(0, 0, 0, 0.4)']}
        leading={
          <HeaderCircleButton
            icon="arrow-back"
            color={colors.white}
            size={24}
            onPress={() => {
              haptics.selection();
              goBack();
            }}
          />
        }
        actions={
          <>
            <HeaderCircleButton
              icon="share"
              color={colors.white}
              accessibilityLabel="Paylaş"
              onPress={() => {
                haptics.selection();
                shareContent(`${name} yerini Seydi Rehber'de keşfet!`);
              }}
            />
            <FavoriteButton id={placeId} type="place" />
          </>
        }>
        <View style={styles.content}>
          <Text style={styles.name}>{name}</Text>
          {hakkinda ? (
            <>
              <Text style={typography.heading3}>Hakkında</Text>
              <Text style={styles.body}>{hakkinda}</Text>
              <View style={{ height: 24 }} />
            </>
          ) : null}
          {tarihce ? (
            <>
              <Text style={typography.heading3}>Tarihçe</Text>
              <Text style={styles.body}>{tarihce}</Text>
              <View style={{ height: 24 }} />
            </>
          ) : null}

          <Text style={styles.locationTitle}>Konum</Text>
          <View style={{ height: 16 }} />
          {konum ? (
            <>
              <View style={styles.mapFrame}>
                {coordinates.status === 'loading' ? (
                  <ActivityIndicator color={colors.primary} />
                ) : coordinates.coords ? (
                  <InteractiveMap position={coordinates.coords} title={name} />
                ) : (
                  <Text style={styles.mapUnavailable}>Harita görüntülenemiyor</Text>
                )}
              </View>
              <View style={{ height: 16 }} />
              <Pressable
                onPress={() => {
                  haptics.selection();
                  openMapWithAddress(konum);
                }}
                style={styles.directionsButton}>
                <MaterialIcons name="directions" size={24} color={colors.white} />
                <Text style={typography.button}>Yol Tarifi Al</Text>
              </Pressable>
            </>
          ) : null}

          <View style={{ height: 40 }} />
          <ReviewSection targetId={placeId} targetType="place" />
          <View style={{ height: 100 }} />
        </View>
      </CollapsingHeaderScreen>
    </>
  );
}

const styles = StyleSheet.create({
  screen: {
    flex: 1,
    backgroundColor: colors.white,
  },
  center: {
    alignItems: 'center',
    justifyContent: 'center',
  },
  content: {
    backgroundColor: colors.white,
    paddingHorizontal: 25,
  },
  name: {
    fontFamily: fonts.black,
    fontSize: 26,
    letterSpacing: -0.5,
    color: '#1E293B',
  },
  body: {
    ...typography.bodyMedium,
    marginTop: 8,
    lineHeight: 21,
    color: '#424242',
  },
  locationTitle: {
    fontFamily: fonts.extraBold,
    fontSize: 20,
    color: '#1E293B',
  },
  mapFrame: {
    height: 200,
    alignItems: 'center',
    justifyContent: 'center',
    borderRadius: 24,
    borderWidth: 1,
    borderColor: '#EEEEEE',
    backgroundColor: '#F5F5F5',
    overflow: 'hidden',
  },
  mapUnavailable: {
    fontFamily: fonts.regular,
    fontSize: 14,
    color: '#9E9E9E',
  },
  directionsButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 8,
    paddingVertical: 16,
    borderRadius: 16,
    backgroundColor: colors.primary,
  },
});
