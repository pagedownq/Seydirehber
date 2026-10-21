import { MaterialIcons } from '@expo/vector-icons';
import { useState } from 'react';
import { FlatList, Pressable, ScrollView, StyleSheet, Text, View } from 'react-native';

import { AppBar } from '@/components/app-bar';
import { CachedImage } from '@/components/cached-image';
import { MapButton } from '@/components/map-button';
import { Shimmer } from '@/components/shimmer';
import type { FirestoreData } from '@/features/firestore/live-query';
import { usePazarlar } from '@/features/home/home-queries';
import { haptics } from '@/services/haptics';
import { colors, fonts, typography } from '@/theme';
import { str } from '@/utils/firestore-values';

// Flutter pazarlar_screen.dart karşılığı. Veri aynı (ad, image_url/gorsel, gunler, adres, konum);
// tasarım kullanıcı isteğiyle (2026-10-21) yenilendi: bugünün özeti, gün süzgeci, "Bugün kuruluyor" rozeti,
// gunler metninden çıkarılan gün çipleri.

// JS getDay sırası: 0 = Pazar
const DAY_NAMES = ['Pazar', 'Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi'];
const SHORT_NAMES = ['Paz', 'Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt'];
// Pazartesiden başlayan hafta
const WEEK_ORDER = [1, 2, 3, 4, 5, 6, 0];

// Uzun adlar önce: "pazartesi" "pazar"dan, "cumartesi" "cuma"dan önce denenmeli.
const DAY_PATTERN = /pazartesi|sal[ıi]|[çc]ar[şs]amba|per[şs]embe|cumartesi|cuma|pazar/g;
const DAY_INDEX: Record<string, number> = {
  pazartesi: 1,
  salı: 2,
  sali: 2,
  çarşamba: 3,
  carsamba: 3,
  çarsamba: 3,
  carşamba: 3,
  perşembe: 4,
  persembe: 4,
  cuma: 5,
  cumartesi: 6,
  pazar: 0,
};

/** "Her Salı ve Cuma" gibi serbest metinden günleri çıkarır; "her gün" tüm hafta. Bulunamazsa boş. */
function parseDays(gunler: string): number[] {
  const text = gunler.toLocaleLowerCase('tr-TR');
  if (/her\s*g[üu]n/.test(text)) return [...WEEK_ORDER];
  const days = new Set<number>();
  for (const match of text.matchAll(DAY_PATTERN)) {
    const index = DAY_INDEX[match[0]];
    if (index != null) days.add(index);
  }
  return WEEK_ORDER.filter((d) => days.has(d));
}

/** Metinde saat aralığı varsa (08:00-18:00 / 08.00 - 18.00) çıkarır. */
function parseHours(gunler: string) {
  const match = gunler.match(/(\d{1,2}[:.]\d{2})\s*[-–]\s*(\d{1,2}[:.]\d{2})/);
  return match ? `${match[1].replace('.', ':')} – ${match[2].replace('.', ':')}` : null;
}

type Market = { id: string; data: FirestoreData; days: number[] };

export function PazarlarScreen() {
  const state = usePazarlar();
  const today = new Date().getDay();
  const [filter, setFilter] = useState<number | null>(null);

  let body;
  if (state.status === 'loading') {
    body = (
      <View style={{ padding: 16, gap: 12 }}>
        <Shimmer height={72} borderRadius={16} />
        {Array.from({ length: 3 }, (_, i) => (
          <Shimmer key={i} height={220} borderRadius={20} />
        ))}
      </View>
    );
  } else if (state.status === 'error') {
    body = <CenteredText text="Veriler yüklenemedi." />;
  } else if (state.docs.length === 0) {
    body = <CenteredText text="Henüz pazar eklenmemiş" />;
  } else {
    const markets: Market[] = state.docs.map((d) => ({ id: d.id, data: d.data, days: parseDays(str(d.data.gunler)) }));
    const todayMarkets = markets.filter((m) => m.days.includes(today));
    // Tümü: bugün kurulanlar üstte, sıra Firestore'daki gibi
    const visible =
      filter == null
        ? [...todayMarkets, ...markets.filter((m) => !m.days.includes(today))]
        : markets.filter((m) => m.days.includes(filter));

    body = (
      <FlatList
        data={visible}
        keyExtractor={(item) => item.id}
        contentContainerStyle={{ paddingHorizontal: 16, paddingBottom: 24 }}
        ItemSeparatorComponent={() => <View style={{ height: 14 }} />}
        ListHeaderComponent={
          <>
            <TodaySummary today={today} markets={todayMarkets} />
            <DayFilter today={today} selected={filter} onSelect={setFilter} markets={markets} />
          </>
        }
        ListEmptyComponent={
          <View style={styles.emptyFilter}>
            <MaterialIcons name="storefront" size={40} color={colors.textLight} />
            <Text style={[typography.bodyMedium, { marginTop: 8, color: colors.textSecondary }]}>
              {filter != null ? `${DAY_NAMES[filter]} günü kurulan pazar yok` : 'Pazar bulunamadı'}
            </Text>
          </View>
        }
        renderItem={({ item }) => <MarketCard market={item} today={today} />}
      />
    );
  }

  return (
    <View style={styles.container}>
      <AppBar title="Halk Pazarları" />
      <View style={{ flex: 1 }}>{body}</View>
    </View>
  );
}

function CenteredText({ text }: { text: string }) {
  return (
    <View style={styles.center}>
      <Text style={typography.bodyMedium}>{text}</Text>
    </View>
  );
}

function TodaySummary({ today, markets }: { today: number; markets: Market[] }) {
  const has = markets.length > 0;
  return (
    <View style={[styles.summary, !has && styles.summaryEmpty]}>
      <View style={[styles.summaryIcon, !has && { backgroundColor: colors.textLight }]}>
        <MaterialIcons name="storefront" size={24} color={colors.white} />
      </View>
      <View style={{ flex: 1, marginLeft: 12 }}>
        <Text style={styles.summaryLabel}>Bugün {DAY_NAMES[today]}</Text>
        <Text style={styles.summaryTitle} numberOfLines={2}>
          {has ? markets.map((m) => str(m.data.ad)).join(', ') : 'Bugün kurulan pazar yok'}
        </Text>
      </View>
    </View>
  );
}

function DayFilter({
  today,
  selected,
  onSelect,
  markets,
}: {
  today: number;
  selected: number | null;
  onSelect: (day: number | null) => void;
  markets: Market[];
}) {
  const chips: { key: number | null; label: string }[] = [
    { key: null, label: 'Tümü' },
    ...WEEK_ORDER.map((d) => ({ key: d, label: SHORT_NAMES[d] })),
  ];
  return (
    <ScrollView
      horizontal
      showsHorizontalScrollIndicator={false}
      style={{ marginHorizontal: -16, marginBottom: 14 }}
      contentContainerStyle={{ paddingHorizontal: 16, gap: 8 }}>
      {chips.map(({ key, label }) => {
        const active = key === selected;
        const isToday = key === today;
        const hasMarket = key == null || markets.some((m) => m.days.includes(key));
        return (
          <Pressable
            key={label}
            onPress={() => {
              haptics.selection();
              onSelect(key);
            }}
            style={[styles.chip, active && styles.chipActive, !hasMarket && !active && { opacity: 0.45 }]}>
            <Text style={[styles.chipText, active && styles.chipTextActive]}>{label}</Text>
            {isToday && <View style={[styles.chipDot, active && { backgroundColor: colors.white }]} />}
          </Pressable>
        );
      })}
    </ScrollView>
  );
}

function MarketCard({ market, today }: { market: Market; today: number }) {
  const { data, days } = market;
  const name = str(data.ad);
  const imageUrl = str(data.image_url, str(data.gorsel));
  const gunler = str(data.gunler);
  const rawAdres = str(data.adres);
  const konum = str(data.konum);
  const adres = rawAdres || (konum.startsWith('http') ? '' : konum);
  const hours = parseHours(gunler);
  const isToday = days.includes(today);

  return (
    <View style={[styles.card, isToday && styles.cardToday]}>
      {imageUrl ? (
        <View>
          <CachedImage imageUrl={imageUrl} width="100%" height={150} borderRadius={0} />
          {isToday && <TodayBadge style={styles.badgeOnImage} />}
        </View>
      ) : null}
      <View style={styles.cardBody}>
        <View style={styles.titleRow}>
          <Text style={[typography.heading3, { flex: 1 }]}>{name}</Text>
          {isToday && !imageUrl && <TodayBadge />}
        </View>

        {days.length > 0 ? (
          <View style={styles.weekRow}>
            {WEEK_ORDER.map((d) => {
              const open = days.includes(d);
              const current = d === today;
              return (
                <View
                  key={d}
                  style={[
                    styles.weekDay,
                    open && styles.weekDayOpen,
                    open && current && styles.weekDayToday,
                    !open && current && styles.weekDayCurrentClosed,
                  ]}>
                  <Text
                    style={[
                      styles.weekDayText,
                      open && styles.weekDayTextOpen,
                      open && current && { color: colors.white },
                    ]}>
                    {SHORT_NAMES[d]}
                  </Text>
                </View>
              );
            })}
          </View>
        ) : null}

        {/* Gün çipleri metni tam karşılamayabilir; asıl bilgi her zaman yazılı. */}
        {gunler ? <InfoRow icon="event" text={gunler} /> : null}
        {hours ? <InfoRow icon="schedule" text={hours} /> : null}
        {adres ? <InfoRow icon="location-on" text={adres} numberOfLines={2} /> : null}
        {konum ? (
          <View style={{ marginTop: 14 }}>
            <MapButton locationUrl={konum} label="Yol Tarifi Al" />
          </View>
        ) : null}
      </View>
    </View>
  );
}

function TodayBadge({ style }: { style?: object }) {
  return (
    <View style={[styles.badge, style]}>
      <View style={styles.badgeDot} />
      <Text style={styles.badgeText}>Bugün kuruluyor</Text>
    </View>
  );
}

function InfoRow({
  icon,
  text,
  numberOfLines,
}: {
  icon: 'event' | 'schedule' | 'location-on';
  text: string;
  numberOfLines?: number;
}) {
  return (
    <View style={styles.infoRow}>
      <View style={styles.infoIcon}>
        <MaterialIcons name={icon} size={15} color={colors.primary} />
      </View>
      <Text style={[typography.bodySmall, { flex: 1, color: colors.textPrimary }]} numberOfLines={numberOfLines}>
        {text}
      </Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.background,
  },
  center: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
  summary: {
    flexDirection: 'row',
    alignItems: 'center',
    marginTop: 12,
    marginBottom: 14,
    padding: 14,
    borderRadius: 16,
    backgroundColor: colors.primarySurface,
  },
  summaryEmpty: {
    backgroundColor: 'rgba(158, 158, 158, 0.1)',
  },
  summaryIcon: {
    width: 44,
    height: 44,
    alignItems: 'center',
    justifyContent: 'center',
    borderRadius: 12,
    backgroundColor: colors.primary,
  },
  summaryLabel: {
    fontFamily: fonts.medium,
    fontSize: 12,
    color: colors.textSecondary,
  },
  summaryTitle: {
    fontFamily: fonts.bold,
    fontSize: 15,
    color: colors.textPrimary,
  },
  chip: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 5,
    paddingHorizontal: 14,
    paddingVertical: 8,
    borderRadius: 20,
    borderWidth: 1,
    borderColor: colors.border,
    backgroundColor: colors.white,
  },
  chipActive: {
    borderColor: colors.primary,
    backgroundColor: colors.primary,
  },
  chipText: {
    fontFamily: fonts.semiBold,
    fontSize: 13,
    color: colors.textSecondary,
  },
  chipTextActive: {
    color: colors.white,
  },
  chipDot: {
    width: 6,
    height: 6,
    borderRadius: 3,
    backgroundColor: colors.primary,
  },
  emptyFilter: {
    alignItems: 'center',
    paddingVertical: 40,
  },
  card: {
    overflow: 'hidden',
    borderRadius: 20,
    borderWidth: 1.5,
    borderColor: 'transparent',
    backgroundColor: colors.cardBackground,
    shadowColor: '#000000',
    shadowOpacity: 0.06,
    shadowRadius: 12,
    shadowOffset: { width: 0, height: 4 },
    elevation: 2,
  },
  cardToday: {
    borderColor: 'rgba(76, 175, 80, 0.4)',
  },
  cardBody: {
    padding: 16,
  },
  titleRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
  },
  badge: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    paddingHorizontal: 10,
    paddingVertical: 5,
    borderRadius: 20,
    backgroundColor: colors.primary,
  },
  badgeOnImage: {
    position: 'absolute',
    top: 12,
    left: 12,
  },
  badgeDot: {
    width: 6,
    height: 6,
    borderRadius: 3,
    backgroundColor: colors.white,
  },
  badgeText: {
    fontFamily: fonts.semiBold,
    fontSize: 11,
    color: colors.white,
  },
  weekRow: {
    flexDirection: 'row',
    gap: 4,
    marginTop: 12,
    marginBottom: 4,
  },
  weekDay: {
    flex: 1,
    alignItems: 'center',
    paddingVertical: 6,
    borderRadius: 8,
    backgroundColor: 'rgba(158, 158, 158, 0.08)',
  },
  weekDayOpen: {
    backgroundColor: colors.primarySurface,
  },
  weekDayToday: {
    backgroundColor: colors.primary,
  },
  weekDayCurrentClosed: {
    borderWidth: 1,
    borderColor: colors.border,
  },
  weekDayText: {
    fontFamily: fonts.medium,
    fontSize: 11,
    color: colors.textLight,
  },
  weekDayTextOpen: {
    fontFamily: fonts.bold,
    color: colors.primaryDark,
  },
  infoRow: {
    marginTop: 8,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 10,
  },
  infoIcon: {
    width: 26,
    height: 26,
    alignItems: 'center',
    justifyContent: 'center',
    borderRadius: 8,
    backgroundColor: colors.primarySurface,
  },
});
