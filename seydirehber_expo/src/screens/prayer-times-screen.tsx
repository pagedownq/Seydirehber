import { MaterialCommunityIcons, MaterialIcons } from '@expo/vector-icons';
import { LinearGradient } from 'expo-linear-gradient';
import type { ComponentProps } from 'react';
import { useState } from 'react';
import { ActivityIndicator, Pressable, RefreshControl, ScrollView, StyleSheet, Text, View } from 'react-native';

import { AppBar } from '@/components/app-bar';
import {
  formatRemaining,
  PRAYER_KEYS,
  PRAYER_LABELS,
  type PrayerKey,
  prayerInstant,
  refreshPrayerTimes,
  usePrayerTimes,
} from '@/features/prayer/prayer-times';
import { colors, fonts, gradientDirection, gradients } from '@/theme';

// Namaz vakitleri (Expo'ya özgü, Flutter'da yok). Veri ve doğruluk önlemleri: features/prayer/.

type IconName = ComponentProps<typeof MaterialCommunityIcons>['name'];

const ICONS: Record<PrayerKey, IconName> = {
  imsak: 'moon-waning-crescent',
  gunes: 'weather-sunset-up',
  ogle: 'white-balance-sunny',
  ikindi: 'weather-partly-cloudy',
  aksam: 'weather-sunset-down',
  yatsi: 'weather-night',
};

const MONTHS = ['Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran', 'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'];
const WEEKDAYS = ['Pazar', 'Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi'];

// Tarih anahtarından (YYYY-MM-DD) saat diliminden bağımsız Türkçe metin.
function dateParts(dateKey: string) {
  const [y, m, d] = dateKey.split('-').map(Number);
  const weekday = new Date(Date.UTC(y, m - 1, d)).getUTCDay();
  return { day: d, month: MONTHS[m - 1], year: y, weekday: WEEKDAYS[weekday] };
}

const longDate = (dateKey: string) => {
  const p = dateParts(dateKey);
  return `${p.day} ${p.month} ${p.year}, ${p.weekday}`;
};

const shortDate = (dateKey: string) => {
  const p = dateParts(dateKey);
  return `${p.day} ${p.month.slice(0, 3)} ${p.weekday.slice(0, 3)}`;
};

const pad = (n: number) => String(n).padStart(2, '0');
const formatClock = (ms: number) => {
  const d = new Date(ms);
  return `${d.getDate()} ${MONTHS[d.getMonth()].slice(0, 3)} ${pad(d.getHours())}:${pad(d.getMinutes())}`;
};

export function PrayerTimesScreen() {
  const { now, today, next, current, upcoming, refreshing, fetchedAt } = usePrayerTimes();
  const [pulling, setPulling] = useState(false);
  const week = upcoming(7);
  const isTomorrow = next.date !== today.date;

  const onRefresh = async () => {
    setPulling(true);
    await refreshPrayerTimes(true);
    setPulling(false);
  };

  return (
    <View style={styles.container}>
      <AppBar title="Namaz Vakitleri" />
      <ScrollView
        contentContainerStyle={styles.content}
        refreshControl={
          <RefreshControl refreshing={pulling} onRefresh={onRefresh} colors={[colors.primary]} tintColor={colors.primary} />
        }>
        <View style={styles.heroShadow}>
          <View style={styles.heroClip}>
            <LinearGradient colors={gradients.primary} start={gradientDirection.start} end={gradientDirection.end} style={StyleSheet.absoluteFill} />
            <MaterialCommunityIcons name="mosque" size={140} color="rgba(255, 255, 255, 0.1)" style={styles.heroBgIcon} />
            <Text style={styles.heroLabel}>Sıradaki vakit · Seydişehir</Text>
            <Text style={styles.heroPrayer}>{PRAYER_LABELS[next.key]}</Text>
            <Text style={styles.heroRemaining}>{formatRemaining(next.at - now)} kaldı</Text>
            <Text style={styles.heroAt}>
              {isTomorrow ? 'Yarın ' : ''}
              {next.time}
            </Text>
          </View>
        </View>

        <View style={styles.card}>
          <View style={styles.dateRow}>
            <Text style={styles.dateText}>{longDate(today.date)}</Text>
            {today.hijri && <Text style={styles.hijriText}>{today.hijri}</Text>}
          </View>
          {PRAYER_KEYS.map((key) => {
            const isCurrent = key === current;
            const passed = !isCurrent && prayerInstant(today.date, today.times[key]) <= now;
            return (
              <View key={key} style={[styles.row, isCurrent && styles.rowCurrent]}>
                <View style={[styles.rowIcon, isCurrent && styles.rowIconCurrent]}>
                  <MaterialCommunityIcons name={ICONS[key]} size={20} color={isCurrent ? colors.white : colors.primaryDark} />
                </View>
                <Text style={[styles.rowLabel, passed && styles.rowPassed]}>{PRAYER_LABELS[key]}</Text>
                {isCurrent && (
                  <View style={styles.nowPill}>
                    <Text style={styles.nowPillText}>Şu an</Text>
                  </View>
                )}
                <Text style={[styles.rowTime, passed && styles.rowPassed, isCurrent && styles.rowTimeCurrent]}>
                  {today.times[key]}
                </Text>
              </View>
            );
          })}
        </View>

        <Text style={styles.sectionTitle}>Önümüzdeki 7 gün</Text>
        <View style={[styles.card, styles.tableCard]}>
          <View style={[styles.tableRow, styles.tableHead]}>
            <Text style={[styles.tableDate, styles.tableHeadText]}>Tarih</Text>
            {PRAYER_KEYS.map((key) => (
              <Text key={key} style={[styles.tableCell, styles.tableHeadText]} numberOfLines={1}>
                {PRAYER_LABELS[key]}
              </Text>
            ))}
          </View>
          {week.map((day, index) => (
            <View key={day.date} style={[styles.tableRow, index === 0 && styles.tableToday]}>
              <Text style={[styles.tableDate, index === 0 && styles.tableTodayText]} numberOfLines={1}>
                {index === 0 ? 'Bugün' : shortDate(day.date)}
              </Text>
              {PRAYER_KEYS.map((key) => (
                <Text key={key} style={[styles.tableCell, index === 0 && styles.tableTodayText]}>
                  {day.times[key]}
                </Text>
              ))}
            </View>
          ))}
        </View>

        {today.source === 'diyanet' ? (
          <View style={styles.sourceBox}>
            <MaterialIcons name="verified" size={18} color={colors.primaryDark} />
            <Text style={styles.sourceText}>
              {"Vakitler, Diyanet İşleri Başkanlığı'nın Seydişehir için yayımladığı vakitlerdir."}
              {fetchedAt ? ` Son güncelleme: ${formatClock(fetchedAt)}.` : ''}
            </Text>
          </View>
        ) : (
          <View style={[styles.sourceBox, styles.sourceWarn]}>
            <MaterialIcons name="info-outline" size={18} color="#B45309" />
            <View style={{ flex: 1 }}>
              <Text style={[styles.sourceText, { color: '#78350F' }]}>
                Diyanet vakitleri şu an alınamadı; vakitler Diyanet yöntemiyle hesaplanarak gösteriliyor. Fark en fazla 1
                dakikadır ve her zaman ihtiyatlı yöndedir (imsak erken, akşam geç). İnternet bağlantısı olunca otomatik
                güncellenir.
              </Text>
              <Pressable onPress={() => refreshPrayerTimes(true)} disabled={refreshing} style={styles.retryButton}>
                {refreshing ? (
                  <ActivityIndicator size="small" color="#B45309" />
                ) : (
                  <Text style={styles.retryText}>Tekrar dene</Text>
                )}
              </Pressable>
            </View>
          </View>
        )}
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.background,
  },
  content: {
    padding: 16,
    paddingBottom: 40,
  },
  heroShadow: {
    borderRadius: 24,
    backgroundColor: colors.white,
    shadowColor: '#43A047',
    shadowOpacity: 0.3,
    shadowRadius: 12,
    shadowOffset: { width: 0, height: 6 },
    elevation: 6,
  },
  heroClip: {
    borderRadius: 24,
    overflow: 'hidden',
    paddingVertical: 24,
    paddingHorizontal: 22,
  },
  heroBgIcon: {
    position: 'absolute',
    right: -18,
    bottom: -24,
  },
  heroLabel: {
    fontFamily: fonts.medium,
    fontSize: 13,
    color: 'rgba(255, 255, 255, 0.9)',
  },
  heroPrayer: {
    marginTop: 4,
    fontFamily: fonts.extraBold,
    fontSize: 30,
    color: colors.white,
  },
  heroRemaining: {
    fontFamily: fonts.bold,
    fontSize: 20,
    color: colors.white,
  },
  heroAt: {
    marginTop: 2,
    fontFamily: fonts.medium,
    fontSize: 14,
    color: 'rgba(255, 255, 255, 0.9)',
  },
  card: {
    marginTop: 16,
    padding: 8,
    borderRadius: 18,
    backgroundColor: colors.white,
    borderWidth: 1,
    borderColor: colors.divider,
  },
  dateRow: {
    paddingHorizontal: 8,
    paddingTop: 6,
    paddingBottom: 10,
  },
  dateText: {
    fontFamily: fonts.semiBold,
    fontSize: 15,
    color: colors.textPrimary,
  },
  hijriText: {
    fontFamily: fonts.regular,
    fontSize: 13,
    color: colors.textSecondary,
  },
  row: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
    paddingVertical: 10,
    paddingHorizontal: 8,
    borderRadius: 12,
  },
  rowCurrent: {
    backgroundColor: colors.primarySurface,
  },
  rowIcon: {
    width: 36,
    height: 36,
    borderRadius: 10,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: colors.primarySurface,
  },
  rowIconCurrent: {
    backgroundColor: colors.primary,
  },
  rowLabel: {
    flex: 1,
    fontFamily: fonts.semiBold,
    fontSize: 16,
    color: colors.textPrimary,
  },
  rowTime: {
    fontFamily: fonts.bold,
    fontSize: 18,
    color: colors.textPrimary,
    fontVariant: ['tabular-nums'],
  },
  rowTimeCurrent: {
    color: colors.primaryDark,
  },
  rowPassed: {
    color: colors.textLight,
  },
  nowPill: {
    paddingHorizontal: 8,
    paddingVertical: 2,
    borderRadius: 999,
    backgroundColor: colors.primary,
  },
  nowPillText: {
    fontFamily: fonts.semiBold,
    fontSize: 11,
    color: colors.white,
  },
  sectionTitle: {
    marginTop: 24,
    marginLeft: 4,
    fontFamily: fonts.semiBold,
    fontSize: 16,
    color: colors.textPrimary,
  },
  tableCard: {
    marginTop: 8,
    paddingVertical: 4,
  },
  tableRow: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: 9,
    paddingHorizontal: 6,
    borderRadius: 10,
  },
  tableHead: {
    borderBottomWidth: 1,
    borderBottomColor: colors.divider,
    borderRadius: 0,
  },
  tableHeadText: {
    fontFamily: fonts.semiBold,
    fontSize: 10,
    color: colors.textSecondary,
  },
  tableToday: {
    backgroundColor: colors.primarySurface,
  },
  tableTodayText: {
    fontFamily: fonts.bold,
    color: colors.primaryDark,
  },
  tableDate: {
    width: 74,
    fontFamily: fonts.medium,
    fontSize: 11,
    color: colors.textPrimary,
  },
  tableCell: {
    flex: 1,
    textAlign: 'center',
    fontFamily: fonts.medium,
    fontSize: 12,
    color: colors.textPrimary,
    fontVariant: ['tabular-nums'],
  },
  sourceBox: {
    marginTop: 16,
    flexDirection: 'row',
    gap: 10,
    padding: 14,
    borderRadius: 14,
    backgroundColor: colors.primarySurface,
  },
  sourceWarn: {
    backgroundColor: '#FEF3C7',
  },
  sourceText: {
    flex: 1,
    fontFamily: fonts.regular,
    fontSize: 12,
    lineHeight: 18,
    color: colors.textSecondary,
  },
  retryButton: {
    alignSelf: 'flex-start',
    marginTop: 8,
    paddingVertical: 6,
    paddingHorizontal: 12,
    borderRadius: 8,
    borderWidth: 1,
    borderColor: '#F59E0B',
  },
  retryText: {
    fontFamily: fonts.semiBold,
    fontSize: 12,
    color: '#B45309',
  },
});
