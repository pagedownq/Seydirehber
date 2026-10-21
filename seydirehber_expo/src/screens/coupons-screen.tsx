import { MaterialIcons } from '@expo/vector-icons';
import { LinearGradient } from 'expo-linear-gradient';
import { type Href, router } from 'expo-router';
import { ActivityIndicator, FlatList, Pressable, StyleSheet, Text, View } from 'react-native';

import { AppBar } from '@/components/app-bar';
import type { FirestoreData } from '@/features/firestore/live-query';
import { useAllCoupons, useAlphabeticalCompanies } from '@/features/home/home-queries';
import { activeCoupons, remainingDaysText } from '@/features/home/horizontal-coupon-list';
import { colors, fonts, typography } from '@/theme';
import { toStr } from '@/utils/firestore-values';

// Flutter lib/features/coupons/screens/coupons_screen.dart karşılığı.
export function CouponsScreen() {
  const state = useAllCoupons();

  let body;
  if (state.status === 'loading') {
    body = (
      <View style={styles.center}>
        <ActivityIndicator size="large" color={colors.primary} />
      </View>
    );
  } else if (state.status === 'error') {
    body = (
      <View style={styles.center}>
        <Text style={typography.bodyMedium}>Hata oluştu: {String(state.error)}</Text>
      </View>
    );
  } else {
    const coupons = activeCoupons(state.docs, Infinity);
    body =
      coupons.length === 0 ? (
        <View style={styles.center}>
          <Text style={typography.bodyMedium}>Şu an aktif kupon yok.</Text>
        </View>
      ) : (
        <FlatList
          data={coupons}
          keyExtractor={(item) => item.id}
          contentContainerStyle={{ padding: 16 }}
          ItemSeparatorComponent={() => <View style={{ height: 16 }} />}
          renderItem={({ item }) => (
            <CouponRow data={item.data} onPress={() => router.push(`/coupons/${item.id}` as Href)} />
          )}
        />
      );
  }

  return (
    <View style={styles.container}>
      <AppBar title="Tüm Kuponlar" />
      <View style={{ flex: 1 }}>{body}</View>
    </View>
  );
}

function CouponRow({ data, onPress }: { data: FirestoreData; onPress: () => void }) {
  const companies = useAlphabeticalCompanies();
  const title = toStr(data.title);
  const discountPercentage = typeof data.discountPercentage === 'number' ? Math.trunc(data.discountPercentage) : 0;
  const companyName = toStr(data.companyName);
  const isOrange = data.isInformational === true && discountPercentage === 0;
  const baseColor = isOrange ? colors.warning : colors.primary;
  const baseRgb = isOrange ? '255, 167, 38' : '76, 175, 80';

  const company = companies.status === 'success' ? companies.docs.find((c) => c.id === data.companyId) : undefined;
  const category = company ? toStr(company.data.kategori) : '';
  const daysText = remainingDaysText(data.expiry_date);
  const isUrgent = daysText != null && (daysText.includes('Son') || daysText.includes('Yarın'));

  return (
    // Düz arka plan iOS'un gölgeyi verimli çizmesi için; gradyan üstünü kaplar.
    <Pressable onPress={onPress} style={[styles.card, { shadowColor: baseColor, backgroundColor: baseColor }]}>
      <LinearGradient
        colors={[baseColor, `rgba(${baseRgb}, 0.8)`]}
        start={{ x: 0, y: 0 }}
        end={{ x: 1, y: 1 }}
        style={styles.cardInner}>
        <View style={styles.left}>
          {discountPercentage > 0 ? (
            <>
              <Text style={styles.percent}>%{discountPercentage}</Text>
              <Text style={styles.percentLabel}>İndirim</Text>
            </>
          ) : (
            <>
              <MaterialIcons name="card-giftcard" size={32} color={colors.white} />
              <Text style={styles.opportunity}>Fırsat</Text>
            </>
          )}
        </View>
        <View style={styles.right}>
          <Text style={styles.title} numberOfLines={2}>
            {title}
          </Text>
          <View style={styles.companyRow}>
            <MaterialIcons name="storefront" size={14} color="rgba(255, 255, 255, 0.7)" />
            <Text style={styles.companyName} numberOfLines={1}>
              {companyName}
            </Text>
          </View>
          <View style={styles.chips}>
            {category ? (
              <View style={styles.categoryChip}>
                <Text style={styles.categoryText}>{category}</Text>
              </View>
            ) : null}
            {daysText ? (
              <View style={[styles.daysChip, { backgroundColor: isUrgent ? '#D32F2F' : '#F57C00' }]}>
                <MaterialIcons name="access-time-filled" size={10} color={colors.white} />
                <Text style={styles.daysText}>{daysText}</Text>
              </View>
            ) : null}
          </View>
        </View>
      </LinearGradient>
    </Pressable>
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
  card: {
    height: 120,
    borderRadius: 16,
    shadowOpacity: 0.3,
    shadowRadius: 8,
    shadowOffset: { width: 0, height: 4 },
    elevation: 4,
  },
  cardInner: {
    flex: 1,
    flexDirection: 'row',
    borderRadius: 16,
    overflow: 'hidden',
  },
  left: {
    width: 90,
    alignItems: 'center',
    justifyContent: 'center',
    borderRightWidth: 2,
    borderRightColor: 'rgba(255, 255, 255, 0.3)',
  },
  percent: {
    fontFamily: fonts.bold,
    fontSize: 28,
    color: colors.white,
  },
  percentLabel: {
    fontFamily: fonts.regular,
    fontSize: 14,
    color: 'rgba(255, 255, 255, 0.7)',
  },
  opportunity: {
    marginTop: 4,
    fontFamily: fonts.semiBold,
    fontSize: 12,
    color: 'rgba(255, 255, 255, 0.7)',
  },
  right: {
    flex: 1,
    padding: 16,
    justifyContent: 'center',
  },
  title: {
    fontFamily: fonts.bold,
    fontSize: 16,
    color: colors.white,
  },
  companyRow: {
    marginTop: 8,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
  },
  companyName: {
    flex: 1,
    fontFamily: fonts.semiBold,
    fontSize: 13,
    color: colors.white,
  },
  chips: {
    marginTop: 4,
    flexDirection: 'row',
    flexWrap: 'wrap',
    alignItems: 'center',
    gap: 6,
    rowGap: 4,
  },
  categoryChip: {
    paddingHorizontal: 6,
    paddingVertical: 2,
    borderRadius: 4,
    backgroundColor: 'rgba(255, 255, 255, 0.24)',
  },
  categoryText: {
    fontFamily: fonts.semiBold,
    fontSize: 9,
    color: colors.white,
  },
  daysChip: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 3,
    paddingHorizontal: 6,
    paddingVertical: 2,
    borderRadius: 4,
  },
  daysText: {
    fontFamily: fonts.bold,
    fontSize: 9,
    color: colors.white,
  },
});
