import { MaterialIcons } from '@expo/vector-icons';
import { LinearGradient } from 'expo-linear-gradient';
import { useEffect, useState } from 'react';
import { FlatList, Pressable, StyleSheet, Text, View } from 'react-native';
import Animated, { FadeIn, LinearTransition, useAnimatedStyle, withTiming } from 'react-native-reanimated';

import { AppBar } from '@/components/app-bar';
import { Shimmer } from '@/components/shimmer';
import type { FirestoreData } from '@/features/firestore/live-query';
import { useOtobusSaatleri } from '@/features/home/home-queries';
import { type CachedItem, getList, saveList } from '@/features/list/manual-cache';
import { haptics } from '@/services/haptics';
import { colors, fonts, gradientDirection, gradients, typography } from '@/theme';
import { byOrderThenName, str } from '@/utils/firestore-values';

// Flutter lib/features/services/screens/otobus_screen.dart karşılığı. Veri ve önbellek aynı;
// tasarım kullanıcı isteğiyle (2026-10-21) yenilendi: üstte gün seçici, kartta sıradaki sefer + geri sayım,
// saatler gün bölümlerine ayrılmış ızgara, duraklar dikey çizgi.
const CACHE_KEY = 'otobus_saatleri';

type DayKey = 'haftaici' | 'cumartesi' | 'pazar';
const DAYS: { key: DayKey; label: string }[] = [
  { key: 'haftaici', label: 'Hafta İçi' },
  { key: 'cumartesi', label: 'Cumartesi' },
  { key: 'pazar', label: 'Pazar' },
];

const dayKeyOf = (date: Date): DayKey => {
  const day = date.getDay(); // 0: Pazar, 6: Cumartesi
  return day === 0 ? 'pazar' : day === 6 ? 'cumartesi' : 'haftaici';
};

const pad = (n: number) => String(n).padStart(2, '0');
const toClock = (date: Date) => `${pad(date.getHours())}:${pad(date.getMinutes())}`;
const toMinutes = (time: string) => {
  const [h, m] = time.split(':').map(Number);
  return (h || 0) * 60 + (m || 0);
};

/** Ekran açıkken "sıradaki sefer" ve geri sayım güncel kalsın. */
function useNow() {
  const [now, setNow] = useState(() => new Date());
  useEffect(() => {
    const timer = setInterval(() => setNow(new Date()), 30_000);
    return () => clearInterval(timer);
  }, []);
  return now;
}

export function OtobusScreen() {
  const state = useOtobusSaatleri();
  const [manualCache, setManualCache] = useState<CachedItem[] | null>(null);
  const now = useNow();
  const todayKey = dayKeyOf(now);
  const [selectedDay, setSelectedDay] = useState<DayKey>(todayKey);

  useEffect(() => {
    if (state.status === 'success' && state.docs.length > 0) {
      saveList(
        CACHE_KEY,
        state.docs.map((d) => ({ ...d.data, id: d.id })),
      );
    } else if (state.status !== 'loading') {
      getList(CACHE_KEY).then(setManualCache);
    }
  }, [state.status, state.docs]);

  let body;
  if (state.status === 'loading') {
    body = (
      <View style={{ padding: 16, gap: 16 }}>
        {Array.from({ length: 4 }, (_, i) => (
          <Shimmer key={i} height={150} borderRadius={20} />
        ))}
      </View>
    );
  } else if (state.status === 'error' && !(manualCache && manualCache.length > 0)) {
    body = (
      <View style={styles.center}>
        <MaterialIcons name="error-outline" size={64} color="#FF9800" />
        <Text style={[typography.bodyMedium, { marginTop: 16 }]}>Veriler yüklenemedi</Text>
        <Pressable
          style={styles.retry}
          onPress={() => {
            haptics.selection();
            useOtobusSaatleri.refresh();
          }}>
          <Text style={styles.retryText}>Tekrar Dene</Text>
        </Pressable>
      </View>
    );
  } else {
    const items: FirestoreData[] =
      state.status === 'success' && state.docs.length > 0 ? state.docs.map((d) => d.data) : (manualCache ?? []);
    body =
      items.length === 0 ? (
        <View style={styles.center}>
          <Text style={typography.bodyMedium}>Henüz otobüs saati bulunmuyor.</Text>
        </View>
      ) : (
        <BusList items={items} now={now} selectedDay={selectedDay} todayKey={todayKey} />
      );
  }

  return (
    <View style={styles.container}>
      <AppBar title="Otobüs Saatleri" />
      <DaySelector selected={selectedDay} todayKey={todayKey} now={now} onSelect={setSelectedDay} />
      <View style={{ flex: 1 }}>{body}</View>
    </View>
  );
}

function DaySelector({
  selected,
  todayKey,
  now,
  onSelect,
}: {
  selected: DayKey;
  todayKey: DayKey;
  now: Date;
  onSelect: (day: DayKey) => void;
}) {
  return (
    <View style={styles.daySelectorWrap}>
      <View style={styles.daySelector}>
        {DAYS.map(({ key, label }) => {
          const active = key === selected;
          return (
            <Pressable
              key={key}
              onPress={() => {
                haptics.selection();
                onSelect(key);
              }}
              style={[styles.dayTab, active && styles.dayTabActive]}>
              <Text style={[styles.dayTabText, active && styles.dayTabTextActive]}>{label}</Text>
              {key === todayKey && <View style={[styles.todayDot, active && { backgroundColor: colors.white }]} />}
            </Pressable>
          );
        })}
      </View>
      <View style={styles.clockRow}>
        <MaterialIcons name="schedule" size={14} color={colors.textLight} />
        <Text style={styles.clockText}>
          Şu an {toClock(now)}
          {selected !== todayKey ? ` · ${DAYS.find((d) => d.key === selected)?.label} seferleri gösteriliyor` : ''}
        </Text>
      </View>
    </View>
  );
}

function BusList({
  items,
  now,
  selectedDay,
  todayKey,
}: {
  items: FirestoreData[];
  now: Date;
  selectedDay: DayKey;
  todayKey: DayKey;
}) {
  const sorted = items.map((data) => ({ data })).sort(byOrderThenName('guzergah'));
  return (
    <FlatList
      data={sorted}
      keyExtractor={(item, index) => `${str(item.data.guzergah)}-${index}`}
      contentContainerStyle={{ paddingTop: 4, paddingHorizontal: 16, paddingBottom: 24 }}
      renderItem={({ item }) => (
        <BusScheduleItem data={item.data} now={now} selectedDay={selectedDay} todayKey={todayKey} />
      )}
    />
  );
}

/** Eski "saatler" + "saatler_hergun" + güne özel saatler; virgül ya da | ile ayrılmış, tekrarsız, sıralı. */
function getTimes(oldSaatler: string, hergun: string, specific: string) {
  return [...new Set(`${oldSaatler}|${hergun}|${specific}`.split(/[,|]/).map((e) => e.trim()).filter(Boolean))].sort();
}

function timesByDay(data: FirestoreData): Record<DayKey, string[]> {
  const oldSaatler = str(data.saatler);
  const hergun = str(data.saatler_hergun);
  return {
    haftaici: getTimes(oldSaatler, hergun, str(data.saatler_haftaici)),
    cumartesi: getTimes(oldSaatler, hergun, str(data.saatler_cumartesi)),
    pazar: getTimes(oldSaatler, hergun, str(data.saatler_pazar)),
  };
}

function formatCountdown(minutes: number) {
  if (minutes < 1) return 'Şimdi';
  if (minutes < 60) return `${minutes} dk sonra`;
  const h = Math.floor(minutes / 60);
  const m = minutes % 60;
  return m === 0 ? `${h} sa sonra` : `${h} sa ${m} dk sonra`;
}

/** "A - B - C", "A → B", "A, B" gibi yazılmış durakları ayırır; ayrılamazsa null. */
function splitStops(duraklar: string) {
  const parts = duraklar
    .split(/\s*(?:→|->|>|–|—|\s-\s|,|\n)\s*/)
    .map((s) => s.trim())
    .filter(Boolean);
  return parts.length >= 2 ? parts : null;
}

function BusScheduleItem({
  data,
  now,
  selectedDay,
  todayKey,
}: {
  data: FirestoreData;
  now: Date;
  selectedDay: DayKey;
  todayKey: DayKey;
}) {
  const [expanded, setExpanded] = useState(false);

  const guzergah = str(data.guzergah);
  const duraklar = typeof data.duraklar === 'string' ? data.duraklar.trim() : '';
  const allTimes = timesByDay(data);
  const times = allTimes[selectedDay];
  const isToday = selectedDay === todayKey;

  const nowClock = toClock(now);
  const upcoming = isToday ? times.filter((time) => time > nowClock) : [];
  const nextTrip = upcoming[0] ?? null;

  // Bugünkü seferler bittiyse yarının ilk seferi
  const tomorrow = new Date(now.getFullYear(), now.getMonth(), now.getDate() + 1);
  const tomorrowFirst = allTimes[dayKeyOf(tomorrow)][0] ?? null;

  const chevronStyle = useAnimatedStyle(() => ({
    transform: [{ rotate: withTiming(expanded ? '180deg' : '0deg', { duration: 250 }) }],
  }));

  return (
    <Animated.View
      layout={LinearTransition.duration(300)}
      style={[styles.card, expanded && { borderColor: 'rgba(76, 175, 80, 0.3)' }]}>
      {/* Başlık */}
      <View style={styles.header}>
        <LinearGradient
          colors={gradients.primary}
          start={gradientDirection.start}
          end={gradientDirection.end}
          style={styles.busIcon}>
          <MaterialIcons name="directions-bus" size={26} color={colors.white} />
        </LinearGradient>
        <View style={{ flex: 1, marginLeft: 14 }}>
          <Text style={styles.route} numberOfLines={2}>
            {guzergah}
          </Text>
          <Text style={styles.routeMeta}>
            {times.length > 0
              ? `${times.length} sefer · ${times[0]} – ${times[times.length - 1]}`
              : 'Bu gün sefer yok'}
          </Text>
        </View>
      </View>

      {/* Sıradaki sefer paneli */}
      {isToday && times.length > 0 && (
        <View style={[styles.nextPanel, !nextTrip && styles.nextPanelDone]}>
          {nextTrip ? (
            <>
              <View style={{ flex: 1 }}>
                <Text style={styles.nextLabel}>Sıradaki sefer</Text>
                <Text style={styles.nextTime}>{nextTrip}</Text>
                {upcoming.length > 1 && (
                  <Text style={styles.followingText}>Sonra: {upcoming.slice(1, 3).join(' · ')}</Text>
                )}
              </View>
              <View style={styles.countdown}>
                <MaterialIcons name="timer" size={14} color={colors.white} />
                <Text style={styles.countdownText}>
                  {formatCountdown(toMinutes(nextTrip) - toMinutes(nowClock))}
                </Text>
              </View>
            </>
          ) : (
            <View style={{ flex: 1 }}>
              <Text style={styles.doneTitle}>Bugünkü seferler tamamlandı</Text>
              {tomorrowFirst && <Text style={styles.doneText}>Yarın ilk sefer: {tomorrowFirst}</Text>}
            </View>
          )}
        </View>
      )}

      {/* Aç / kapat */}
      {(times.length > 0 || duraklar) && (
        <Pressable
          onPress={() => {
            haptics.selection();
            setExpanded((value) => !value);
          }}
          style={styles.toggle}>
          <Text style={styles.toggleText}>
            {expanded ? 'Gizle' : duraklar ? 'Tüm saatler ve duraklar' : 'Tüm saatler'}
          </Text>
          <Animated.View style={chevronStyle}>
            <MaterialIcons name="keyboard-arrow-down" size={20} color={colors.primary} />
          </Animated.View>
        </Pressable>
      )}

      {expanded && (
        <Animated.View entering={FadeIn.duration(250)} style={styles.details}>
          <TimeGrid times={times} isToday={isToday} nextTrip={nextTrip} nowClock={nowClock} />
          {duraklar ? <Stops duraklar={duraklar} /> : null}
        </Animated.View>
      )}
    </Animated.View>
  );
}

const PERIODS = [
  { label: 'Sabah', icon: 'wb-twilight', from: '00:00', to: '12:00' },
  { label: 'Öğle', icon: 'wb-sunny', from: '12:00', to: '17:00' },
  { label: 'Akşam', icon: 'nights-stay', from: '17:00', to: '24:00' },
] as const;

function TimeGrid({
  times,
  isToday,
  nextTrip,
  nowClock,
}: {
  times: string[];
  isToday: boolean;
  nextTrip: string | null;
  nowClock: string;
}) {
  if (times.length === 0) return <Text style={styles.emptyDay}>Bu gün için sefer bulunmuyor.</Text>;

  return (
    <View style={{ gap: 14 }}>
      {PERIODS.map((period) => {
        const periodTimes = times.filter((t) => t >= period.from && t < period.to);
        if (periodTimes.length === 0) return null;
        return (
          <View key={period.label}>
            <View style={styles.periodHeader}>
              <MaterialIcons name={period.icon} size={16} color={colors.textSecondary} />
              <Text style={styles.periodLabel}>{period.label}</Text>
            </View>
            <View style={styles.grid}>
              {periodTimes.map((time) => {
                const isNext = isToday && time === nextTrip;
                const hasPassed = isToday && time <= nowClock;
                return (
                  <View key={time} style={[styles.timeCell, isNext && styles.timeCellNext, hasPassed && styles.timeCellPassed]}>
                    <Text
                      style={[styles.timeText, isNext && styles.timeTextNext, hasPassed && styles.timeTextPassed]}>
                      {time}
                    </Text>
                  </View>
                );
              })}
            </View>
          </View>
        );
      })}
      {isToday && (
        <View style={styles.legend}>
          <View style={[styles.legendDot, { backgroundColor: colors.primary }]} />
          <Text style={styles.legendText}>Sıradaki</Text>
          <View style={[styles.legendDot, { backgroundColor: colors.border, marginLeft: 12 }]} />
          <Text style={styles.legendText}>Geçmiş</Text>
        </View>
      )}
    </View>
  );
}

function Stops({ duraklar }: { duraklar: string }) {
  const stops = splitStops(duraklar);
  return (
    <View style={{ marginTop: 20 }}>
      <View style={styles.periodHeader}>
        <MaterialIcons name="route" size={16} color="#2196F3" />
        <Text style={styles.periodLabel}>Güzergah / Duraklar</Text>
      </View>
      {stops ? (
        <View style={{ marginTop: 4 }}>
          {stops.map((stop, index) => {
            const isEdge = index === 0 || index === stops.length - 1;
            return (
              <View key={`${stop}-${index}`} style={styles.stopRow}>
                <View style={styles.stopRail}>
                  <View style={[styles.railLine, index === 0 && { backgroundColor: 'transparent' }]} />
                  <View style={[styles.stopDot, isEdge && styles.stopDotEdge]} />
                  <View style={[styles.railLine, index === stops.length - 1 && { backgroundColor: 'transparent' }]} />
                </View>
                <Text style={[styles.stopText, isEdge && styles.stopTextEdge]}>{stop}</Text>
              </View>
            );
          })}
        </View>
      ) : (
        <View style={styles.stopsBox}>
          <Text style={styles.stopsBoxText}>{duraklar}</Text>
        </View>
      )}
    </View>
  );
}

const BLUE = '#2196F3';

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
  retry: {
    paddingHorizontal: 12,
    paddingVertical: 10,
  },
  retryText: {
    fontFamily: fonts.medium,
    fontSize: 14,
    color: colors.primary,
  },
  daySelectorWrap: {
    paddingHorizontal: 16,
    paddingTop: 12,
    paddingBottom: 12,
  },
  daySelector: {
    flexDirection: 'row',
    padding: 4,
    borderRadius: 14,
    backgroundColor: colors.white,
    borderWidth: 1,
    borderColor: colors.divider,
  },
  dayTab: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 6,
    paddingVertical: 10,
    borderRadius: 10,
  },
  dayTabActive: {
    backgroundColor: colors.primary,
  },
  dayTabText: {
    fontFamily: fonts.semiBold,
    fontSize: 13,
    color: colors.textSecondary,
  },
  dayTabTextActive: {
    color: colors.white,
  },
  todayDot: {
    width: 6,
    height: 6,
    borderRadius: 3,
    backgroundColor: colors.primary,
  },
  clockRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    marginTop: 8,
    paddingHorizontal: 4,
  },
  clockText: {
    ...typography.caption,
    fontSize: 12,
  },
  card: {
    marginBottom: 14,
    borderRadius: 20,
    borderWidth: 1.5,
    borderColor: 'transparent',
    backgroundColor: colors.white,
    shadowColor: '#000000',
    shadowOpacity: 0.06,
    shadowRadius: 14,
    shadowOffset: { width: 0, height: 6 },
    elevation: 2,
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 16,
    paddingTop: 16,
  },
  busIcon: {
    width: 48,
    height: 48,
    alignItems: 'center',
    justifyContent: 'center',
    borderRadius: 14,
    backgroundColor: gradients.primary[0],
  },
  route: {
    fontFamily: fonts.bold,
    fontSize: 16,
    lineHeight: 21,
    color: colors.textPrimary,
  },
  routeMeta: {
    ...typography.bodySmall,
    marginTop: 2,
  },
  nextPanel: {
    flexDirection: 'row',
    alignItems: 'center',
    marginHorizontal: 16,
    marginTop: 14,
    paddingHorizontal: 14,
    paddingVertical: 12,
    borderRadius: 14,
    backgroundColor: colors.primarySurface,
  },
  nextPanelDone: {
    backgroundColor: 'rgba(158, 158, 158, 0.08)',
  },
  nextLabel: {
    fontFamily: fonts.medium,
    fontSize: 12,
    color: colors.primaryDark,
  },
  nextTime: {
    fontFamily: fonts.bold,
    fontSize: 28,
    lineHeight: 34,
    color: colors.primaryDark,
  },
  followingText: {
    fontFamily: fonts.regular,
    fontSize: 12,
    color: colors.textSecondary,
  },
  countdown: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    paddingHorizontal: 10,
    paddingVertical: 6,
    borderRadius: 20,
    backgroundColor: colors.primary,
  },
  countdownText: {
    fontFamily: fonts.semiBold,
    fontSize: 12,
    color: colors.white,
  },
  doneTitle: {
    fontFamily: fonts.semiBold,
    fontSize: 14,
    color: 'rgba(244, 67, 54, 0.8)',
  },
  doneText: {
    ...typography.bodySmall,
    marginTop: 2,
  },
  toggle: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 2,
    marginTop: 12,
    paddingVertical: 12,
    borderTopWidth: 1,
    borderTopColor: colors.divider,
  },
  toggleText: {
    fontFamily: fonts.semiBold,
    fontSize: 13,
    color: colors.primary,
  },
  details: {
    paddingHorizontal: 16,
    paddingBottom: 18,
  },
  emptyDay: {
    ...typography.bodySmall,
    textAlign: 'center',
    paddingVertical: 8,
  },
  periodHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    marginBottom: 8,
  },
  periodLabel: {
    fontFamily: fonts.bold,
    fontSize: 13,
    color: colors.textPrimary,
  },
  grid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 8,
  },
  timeCell: {
    width: '22.5%',
    alignItems: 'center',
    paddingVertical: 8,
    borderRadius: 10,
    borderWidth: 1,
    borderColor: 'rgba(76, 175, 80, 0.15)',
    backgroundColor: colors.white,
  },
  timeCellNext: {
    borderColor: colors.primary,
    backgroundColor: colors.primary,
  },
  timeCellPassed: {
    borderColor: colors.divider,
    backgroundColor: colors.divider,
  },
  timeText: {
    fontFamily: fonts.semiBold,
    fontSize: 14,
    color: colors.textPrimary,
  },
  timeTextNext: {
    fontFamily: fonts.bold,
    color: colors.white,
  },
  timeTextPassed: {
    fontFamily: fonts.regular,
    color: colors.textLight,
  },
  legend: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
  },
  legendDot: {
    width: 8,
    height: 8,
    borderRadius: 4,
  },
  legendText: {
    ...typography.caption,
  },
  stopRow: {
    flexDirection: 'row',
    alignItems: 'center',
    minHeight: 30,
  },
  stopRail: {
    width: 20,
    alignSelf: 'stretch',
    alignItems: 'center',
  },
  railLine: {
    flex: 1,
    width: 2,
    backgroundColor: 'rgba(33, 150, 243, 0.25)',
  },
  stopDot: {
    width: 8,
    height: 8,
    borderRadius: 4,
    backgroundColor: 'rgba(33, 150, 243, 0.5)',
  },
  stopDotEdge: {
    width: 12,
    height: 12,
    borderRadius: 6,
    borderWidth: 3,
    borderColor: BLUE,
    backgroundColor: colors.white,
  },
  stopText: {
    flex: 1,
    marginLeft: 10,
    fontFamily: fonts.regular,
    fontSize: 13,
    color: colors.textSecondary,
  },
  stopTextEdge: {
    fontFamily: fonts.semiBold,
    color: colors.textPrimary,
  },
  stopsBox: {
    padding: 14,
    borderRadius: 14,
    backgroundColor: 'rgba(158, 158, 158, 0.05)',
  },
  stopsBoxText: {
    ...typography.bodySmall,
    lineHeight: 18,
    color: colors.textSecondary,
  },
});
