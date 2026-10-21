import { MaterialIcons } from '@expo/vector-icons';
import { StatusBar } from 'expo-status-bar';
import { Pressable, StyleSheet, Text, View } from 'react-native';

import { CachedImage } from '@/components/cached-image';
import { CollapsingHeaderScreen } from '@/components/collapsing-header-screen';
import { HeaderCircleButton } from '@/components/header-circle-button';
import { InteractiveMap } from '@/components/interactive-map';
import { ModernInfoRow } from '@/components/modern-info-row';
import { shareContent } from '@/components/share-button';
import { DetailShimmer } from '@/components/shimmer';
import { useDocument } from '@/features/firestore/use-document';
import { useCoordinates } from '@/features/map/use-coordinates';
import { colors, fonts } from '@/theme';
import { formatDate } from '@/utils/date';
import { str } from '@/utils/firestore-values';
import { openMapWithAddress } from '@/utils/map';
import { goBack } from '@/utils/navigation';

// Flutter lib/features/events/screens/event_detail_screen.dart karşılığı.
export function EventDetailScreen({ eventId }: { eventId: string }) {
  const event = useDocument('etkinlikler', eventId);
  const konum = event.status === 'ready' ? (typeof event.data.konum === 'string' ? event.data.konum : null) : null;
  const coordinates = useCoordinates(konum);

  if (event.status === 'loading') {
    return (
      <View style={styles.screen}>
        <DetailShimmer />
      </View>
    );
  }
  if (event.status !== 'ready') {
    return (
      <View style={[styles.screen, styles.center]}>
        <Text>Etkinlik bulunamadı</Text>
      </View>
    );
  }

  const { data } = event;
  const name = str(data.ad);
  const imageUrl = str(data.image_url, str(data.gorsel));
  const hakkinda = str(data.hakkinda);
  const adres = str(data.adres, str(data.konum));
  const startDate = data.baslangic_tarihi ?? data.baslangic_tarihi_str;
  const endDate = data.bitis_tarihi ?? data.bitis_tarihi_str;
  const saat = typeof data.saat === 'string' ? data.saat : null;

  return (
    <>
      <StatusBar style="dark" />
      <CollapsingHeaderScreen
        expandedHeight={450}
        barColor={colors.white}
        background={<CachedImage imageUrl={imageUrl} isEvent />}
        overlayColors={['rgba(0, 0, 0, 0.4)', 'transparent', 'rgba(0, 0, 0, 0.2)']}
        leading={<HeaderCircleButton icon="arrow-back" color={colors.white} onPress={goBack} />}
        actions={
          <HeaderCircleButton
            icon="share"
            color={colors.primaryDark}
            accessibilityLabel="Paylaş"
            onPress={() => shareContent(`${name} etkinliğini Seydi Rehber'de keşfet!`)}
          />
        }>
        <View style={styles.content}>
          <Text style={styles.name}>{name}</Text>
          <View style={{ height: 42 }} />

          <Text style={styles.sectionTitle}>Zaman Bilgisi</Text>
          <View style={{ height: 20 }} />
          <ModernInfoRow icon="calendar-month" label="BAŞLANGIÇ" value={formatDate(startDate)} />
          {endDate != null && <ModernInfoRow icon="event-note" label="BİTİŞ TARİHİ" value={formatDate(endDate)} />}
          {saat != null && <ModernInfoRow icon="access-time-filled" label="ETKİNLİK SAATİ" value={saat} />}
          <View style={{ height: 40 }} />

          {hakkinda ? (
            <>
              <Text style={styles.sectionTitle}>Açıklama</Text>
              <Text style={styles.description}>{hakkinda}</Text>
              <View style={{ height: 40 }} />
            </>
          ) : null}

          {konum ? (
            <>
              <Text style={styles.sectionTitle}>Konum</Text>
              <View style={{ height: 16 }} />
              {adres ? <ModernInfoRow icon={{ community: 'map-marker-outline' }} label="ADRES" value={adres} /> : null}
              {coordinates.status === 'done' && coordinates.coords && (
                <View style={{ marginBottom: 20 }}>
                  <InteractiveMap position={coordinates.coords} title={name} />
                </View>
              )}
              <Pressable onPress={() => openMapWithAddress(konum)} style={styles.mapButton}>
                <MaterialIcons name="near-me" size={24} color={colors.primaryDark} />
                <Text style={styles.mapButtonText}>HARİTA ÜZERİNDEN BAK</Text>
              </Pressable>
            </>
          ) : null}
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
    paddingBottom: 120,
  },
  name: {
    fontFamily: fonts.black,
    fontSize: 22,
    letterSpacing: -0.5,
    color: '#000000',
  },
  sectionTitle: {
    fontFamily: fonts.bold,
    fontSize: 16,
    color: colors.black87,
  },
  description: {
    marginTop: 12,
    fontFamily: fonts.regular,
    fontSize: 14,
    lineHeight: 21,
    color: '#424242',
  },
  mapButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 8,
    paddingVertical: 18,
    borderRadius: 15,
    backgroundColor: colors.primarySurface,
  },
  mapButtonText: {
    fontFamily: fonts.black,
    fontSize: 13,
    letterSpacing: 0.5,
    color: colors.primaryDark,
  },
});
