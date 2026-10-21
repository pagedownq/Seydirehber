import { MaterialCommunityIcons, MaterialIcons } from '@expo/vector-icons';
import { LinearGradient } from 'expo-linear-gradient';
import { type Href, router, useScrollToTop } from 'expo-router';
import type { ComponentProps, ComponentRef, ReactNode } from 'react';
import { useRef, useState } from 'react';
import { Pressable, ScrollView, StyleSheet, Text, View } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';

import { SeeAllButton } from '@/components/see-all-button';
import { shareContent } from '@/components/share-button';
import { BannerSlider } from '@/features/home/banner-slider';
import { HorizontalCardList } from '@/features/home/horizontal-card-list';
import { HorizontalCouponList } from '@/features/home/horizontal-coupon-list';
import {
  useAllCompanies,
  useAllPlaces,
  useLatestCompanies,
  useLatestCoupons,
  useLatestEvents,
  usePopularCompanies,
  useTopRatedCompanies,
} from '@/features/home/home-queries';
import { ServiceGrid } from '@/features/home/service-grid';
import { formatRemaining, PRAYER_LABELS, usePrayerTimes } from '@/features/prayer/prayer-times';
import { haptics } from '@/services/haptics';
import { colors, fonts, gradientDirection, gradients, typography } from '@/theme';

// Flutter lib/features/home/screens/home_screen.dart karşılığı.
// ("Anlık Durum Bildirimleri" bölümü Flutter'da yorum satırında; taşınmadı.)
type IconName = ComponentProps<typeof MaterialIcons>['name'];

const push = (href: string) => router.push(href as Href);

export function HomeScreen() {
  const insets = useSafeAreaInsets();
  const scrollRef = useRef<ComponentRef<typeof ScrollView>>(null);
  const [scrolled, setScrolled] = useState(false);
  // Sekmeye tekrar basınca başa kaydırır (Flutter: _homeScrollController.animateTo(0)).
  // RN 0.88 ScrollView ref tipi useScrollToTop'un beklediği tiple henüz örtüşmüyor; çalışma zamanında aynı nesne.
  useScrollToTop(scrollRef as unknown as Parameters<typeof useScrollToTop>[0]);

  const latestEvents = useLatestEvents();
  const latestCoupons = useLatestCoupons();
  const allPlaces = useAllPlaces();
  const latestCompanies = useLatestCompanies();
  const popularCompanies = usePopularCompanies();
  const topRatedCompanies = useTopRatedCompanies();
  const allCompanies = useAllCompanies();

  return (
    <View style={styles.container}>
      <View style={[styles.appBar, { paddingTop: insets.top }, scrolled && styles.appBarScrolled]}>
        <View style={styles.appBarContent}>
          <View style={styles.titleRow}>
            <MaterialIcons name="location-on" size={22} color={colors.primary} />
            <Text style={typography.appBarTitle} numberOfLines={1}>
              Seydi Rehber
            </Text>
          </View>
          <Pressable
            hitSlop={8}
            style={styles.iconButton}
            onPress={() => {
              haptics.selection();
              push('/notifications');
            }}>
            <MaterialCommunityIcons name="bell-outline" size={24} color={colors.textPrimary} />
          </Pressable>
        </View>
      </View>

      <ScrollView
        ref={scrollRef}
        scrollEventThrottle={16}
        onScroll={(event) => setScrolled(event.nativeEvent.contentOffset.y > 0)}
        contentContainerStyle={{ paddingBottom: 32 }}>
        <View style={styles.actionRow}>
          <TopActionButton
            title="Hava Durumu"
            icon="cloud-queue"
            gradient={gradients.weather}
            shadowColor={gradients.weather[0]}
            onPress={() => push('/weather')}
          />
          {/* Expo'ya özgü: hava durumunun sağında iki ince buton (namaz vakti + paylaş). */}
          <View style={styles.sideColumn}>
            <PrayerTimeButton />
            <SlimButton
              icon="share"
              title="Arkadaşınla Paylaş"
              onPress={() =>
                shareContent('Seydi Rehber uygulamasını indir ve Seydişehir hakkında her şeyi öğren! 📱')
              }
            />
          </View>
        </View>

        <Pressable
          style={styles.search}
          onPress={() => {
            haptics.selection();
            push('/search');
          }}>
          <MaterialIcons name="search" size={20} color={colors.textLight} />
          <Text style={styles.searchText}>Etkinlik, firma, yer veya kategori ara...</Text>
        </Pressable>

        <BannerSlider />

        <Section title="Etkinlikler" onSeeAll={() => push('/events')}>
          <HorizontalCardList state={latestEvents} type="event" onPress={(id) => push(`/events/${id}`)} />
        </Section>

        <Section title="Fırsat Kuponları" onSeeAll={() => push('/coupons')}>
          <HorizontalCouponList state={latestCoupons} onPress={(id) => push(`/coupons/${id}`)} />
        </Section>

        <View style={styles.section}>
          <Text style={[typography.heading3, styles.servicesTitle]}>Hizmetler</Text>
          <ServiceGrid />
        </View>

        <Section title="Gezilecek Yerler" onSeeAll={() => push('/places')}>
          <HorizontalCardList state={allPlaces} type="place" onPress={(id) => push(`/places/${id}`)} />
        </Section>

        <Section title="Yeni Eklenen Firmalar" onSeeAll={() => push('/companies/latest')}>
          <HorizontalCardList state={latestCompanies} type="company" onPress={(id) => push(`/companies/${id}`)} />
        </Section>

        <Section title="En Çok Ziyaret Edilen Firmalar" onSeeAll={() => push('/companies/popular')}>
          <HorizontalCardList state={popularCompanies} type="company" onPress={(id) => push(`/companies/${id}`)} />
        </Section>

        <Section title="En Çok Değerlendirme Alan Firmalar" onSeeAll={() => push('/companies/rated')}>
          <HorizontalCardList
            state={topRatedCompanies}
            type="company"
            showRating
            onPress={(id) => push(`/companies/${id}`)}
          />
        </Section>

        <Section title="Tüm Firmalar" onSeeAll={() => push('/companies')}>
          <HorizontalCardList state={allCompanies} type="company" onPress={(id) => push(`/companies/${id}`)} />
        </Section>
      </ScrollView>
    </View>
  );
}

function Section({ title, onSeeAll, children }: { title: string; onSeeAll: () => void; children: ReactNode }) {
  return (
    <View style={styles.section}>
      <View style={styles.sectionHeader}>
        <SeeAllButton title={title} onPress={onSeeAll} />
      </View>
      {children}
    </View>
  );
}

function TopActionButton({
  title,
  icon,
  gradient,
  shadowColor,
  onPress,
}: {
  title: string;
  icon: IconName;
  gradient?: readonly [string, string];
  shadowColor: string;
  onPress: () => void;
}) {
  return (
    <Pressable
      onPress={() => {
        haptics.selection();
        onPress();
      }}
      style={({ pressed }) => [styles.actionButton, { shadowColor }, pressed && styles.pressed]}>
      <View style={[styles.actionClip, !gradient && { backgroundColor: '#000000' }]}>
        {gradient && (
          <LinearGradient
            colors={gradient}
            start={gradientDirection.start}
            end={gradientDirection.end}
            style={StyleSheet.absoluteFill}
          />
        )}
        <MaterialIcons name={icon} size={80} color="rgba(255, 255, 255, 0.12)" style={styles.actionBgIcon} />
        <View style={styles.actionContent}>
          <View style={styles.actionIconBox}>
            <MaterialIcons name={icon} size={22} color={colors.white} />
          </View>
          <Text style={styles.actionTitle} numberOfLines={2}>
            {title}
          </Text>
        </View>
      </View>
    </Pressable>
  );
}

function PrayerTimeButton() {
  const { next, now } = usePrayerTimes();
  return (
    <Pressable
      accessibilityLabel={`${PRAYER_LABELS[next.key]} vakti ${next.time}, ${formatRemaining(next.at - now)} kaldı`}
      onPress={() => {
        haptics.selection();
        push('/namaz-vakitleri');
      }}
      style={({ pressed }) => [styles.slimButton, styles.prayerButton, pressed && styles.pressed]}>
      <MaterialCommunityIcons name="mosque" size={20} color={colors.primaryDark} />
      <View style={styles.slimTextBox}>
        <Text style={styles.prayerName} numberOfLines={1}>
          {PRAYER_LABELS[next.key]} {next.time}
        </Text>
        <Text style={styles.prayerRemaining} numberOfLines={1}>
          {formatRemaining(next.at - now)} kaldı
        </Text>
      </View>
      <MaterialIcons name="chevron-right" size={18} color={colors.primaryDark} />
    </Pressable>
  );
}

function SlimButton({ icon, title, onPress }: { icon: IconName; title: string; onPress: () => void }) {
  return (
    <Pressable
      onPress={() => {
        haptics.selection();
        onPress();
      }}
      style={({ pressed }) => [styles.slimButton, styles.shareButton, pressed && styles.pressed]}>
      <MaterialIcons name={icon} size={18} color={colors.white} />
      <Text style={styles.shareTitle} numberOfLines={1}>
        {title}
      </Text>
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
    zIndex: 1,
  },
  appBarScrolled: {
    shadowColor: '#000000',
    shadowOpacity: 0.12,
    shadowRadius: 1,
    shadowOffset: { width: 0, height: 0.5 },
    elevation: 1,
  },
  appBarContent: {
    height: 56,
    flexDirection: 'row',
    alignItems: 'center',
    paddingLeft: 16,
    paddingRight: 8,
  },
  titleRow: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
  },
  iconButton: {
    width: 48,
    height: 48,
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: 8,
  },
  actionRow: {
    flexDirection: 'row',
    gap: 12,
    paddingHorizontal: 16,
    paddingTop: 16,
  },
  actionButton: {
    flex: 1,
    height: 100,
    borderRadius: 20,
    backgroundColor: colors.white,
    shadowOpacity: 0.25,
    shadowRadius: 10,
    shadowOffset: { width: 0, height: 4 },
    elevation: 6,
  },
  pressed: {
    opacity: 0.9,
  },
  sideColumn: {
    flex: 1,
    gap: 8,
  },
  slimButton: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    paddingHorizontal: 12,
    borderRadius: 14,
  },
  prayerButton: {
    backgroundColor: colors.primarySurface,
    borderWidth: 1,
    borderColor: '#C8E6C9',
  },
  slimTextBox: {
    flex: 1,
  },
  prayerName: {
    fontFamily: fonts.bold,
    fontSize: 13,
    lineHeight: 16,
    color: colors.primaryDark,
  },
  prayerRemaining: {
    fontFamily: fonts.medium,
    fontSize: 11,
    lineHeight: 14,
    color: colors.textSecondary,
  },
  shareButton: {
    backgroundColor: '#000000',
    shadowColor: '#000000',
    shadowOpacity: 0.2,
    shadowRadius: 6,
    shadowOffset: { width: 0, height: 3 },
    elevation: 4,
  },
  shareTitle: {
    flex: 1,
    fontFamily: fonts.extraBold,
    fontSize: 12,
    color: colors.white,
  },
  actionClip: {
    flex: 1,
    borderRadius: 20,
    overflow: 'hidden',
  },
  actionBgIcon: {
    position: 'absolute',
    right: -10,
    top: -10,
  },
  actionContent: {
    flex: 1,
    padding: 12,
    justifyContent: 'space-between',
  },
  actionIconBox: {
    alignSelf: 'flex-start',
    padding: 7,
    borderRadius: 10,
    backgroundColor: 'rgba(255, 255, 255, 0.2)',
  },
  actionTitle: {
    marginTop: 4,
    fontFamily: fonts.extraBold,
    fontSize: 13,
    lineHeight: 14.3,
    color: colors.white,
  },
  search: {
    margin: 16,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    paddingHorizontal: 16,
    paddingVertical: 12,
    borderRadius: 14,
    borderWidth: 1,
    borderColor: colors.border,
    backgroundColor: colors.white,
    shadowColor: '#000000',
    shadowOpacity: 0.05,
    shadowRadius: 10,
    shadowOffset: { width: 0, height: 4 },
    elevation: 2,
  },
  searchText: {
    ...typography.bodySmall,
    color: colors.textLight,
  },
  section: {
    marginTop: 24,
  },
  sectionHeader: {
    paddingHorizontal: 16,
    marginBottom: 8,
  },
  servicesTitle: {
    paddingHorizontal: 16,
    marginBottom: 12,
  },
});
