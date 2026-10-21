import { MaterialIcons } from '@expo/vector-icons';
import { LinearGradient } from 'expo-linear-gradient';
import { FlatList, Pressable, StyleSheet, Text, View } from 'react-native';

import { CouponCardShimmer } from '@/components/shimmer';
import type { FirestoreData, LiveDoc, LiveQueryState } from '@/features/firestore/live-query';
import { useAlphabeticalCompanies } from '@/features/home/home-queries';
import { haptics } from '@/services/haptics';
import { colors, fonts, typography } from '@/theme';
import { int, isTimestamp, toStr } from '@/utils/firestore-values';

// Flutter lib/features/home/widgets/horizontal_coupon_list.dart karşılığı.
type HorizontalCouponListProps = {
  state: LiveQueryState;
  onPress: (id: string, data: FirestoreData) => void;
};

/** Aktif, süresi dolmamış ve limiti dolmamış kuponlar; en yeni önce (Ana Sayfa'da en fazla 10). */
export function activeCoupons(docs: LiveDoc[], max = 10) {
  const now = new Date();
  return docs
    .filter(({ data }) => {
      if (data.isActive !== true) return false;
      if (isTimestamp(data.expiry_date) && data.expiry_date.toDate() < now) return false;
      const totalLimit = typeof data.total_limit === 'number' ? data.total_limit : null;
      const usedCount = int(data.used_count);
      if (totalLimit != null && usedCount >= totalLimit) return false;
      return true;
    })
    .sort((a, b) => {
      const aSeconds = isTimestamp(a.data.created_at) ? a.data.created_at.seconds : 0;
      const bSeconds = isTimestamp(b.data.created_at) ? b.data.created_at.seconds : 0;
      return bSeconds - aSeconds;
    })
    .slice(0, max);
}

export function HorizontalCouponList({ state, onPress }: HorizontalCouponListProps) {
  if (state.status === 'loading') {
    return (
      <View style={[styles.row, { height: 120 }]}>
        {Array.from({ length: 3 }, (_, i) => (
          <CouponCardShimmer key={i} />
        ))}
      </View>
    );
  }

  if (state.status === 'error') {
    return (
      <View style={styles.errorBox}>
        <Text style={styles.errorText}>Hata: {String(state.error)}</Text>
      </View>
    );
  }

  const coupons = activeCoupons(state.docs);

  if (coupons.length === 0) {
    return (
      <View style={styles.emptyBox}>
        <Text style={styles.emptyText}>Şu anda aktif kupon bulunmamaktadır.</Text>
      </View>
    );
  }

  return (
    <FlatList
      horizontal
      data={coupons}
      keyExtractor={(item) => item.id}
      showsHorizontalScrollIndicator={false}
      style={{ height: 120, flexGrow: 0 }}
      contentContainerStyle={styles.listContent}
      ItemSeparatorComponent={() => <View style={{ width: 12 }} />}
      renderItem={({ item }) => (
        <CouponCard
          data={item.data}
          onPress={() => {
            haptics.selection();
            onPress(item.id, item.data);
          }}
        />
      )}
    />
  );
}

/** Flutter _getRemainingDaysText: "Son dakikalar!", "Bugün son!", "Yarın son!", "N gün kaldı". */
export function remainingDaysText(expiry: unknown): string | null {
  if (!isTimestamp(expiry)) return null;
  const difference = expiry.toMillis() - Date.now();
  if (difference < 0) return null;

  const days = Math.floor(difference / 86_400_000);
  if (days === 0) {
    const hours = Math.floor(difference / 3_600_000);
    return hours <= 0 ? 'Son dakikalar!' : 'Bugün son!';
  }
  if (days === 1) return 'Yarın son!';
  return `${days} gün kaldı`;
}

function CouponCard({ data, onPress }: { data: FirestoreData; onPress: () => void }) {
  const companies = useAlphabeticalCompanies();
  const title = toStr(data.title);
  const discountPercentage = typeof data.discountPercentage === 'number' ? Math.trunc(data.discountPercentage) : 0;
  const companyName = toStr(data.companyName);
  const isInformational = data.isInformational === true;
  const isOrange = isInformational && discountPercentage === 0;
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
              <MaterialIcons name="card-giftcard" size={28} color={colors.white} />
              <Text style={styles.opportunityLabel}>Fırsat</Text>
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
  row: {
    flexDirection: 'row',
    paddingHorizontal: 16,
  },
  listContent: {
    paddingHorizontal: 16,
  },
  errorBox: {
    height: 100,
    marginHorizontal: 16,
    padding: 8,
    alignItems: 'center',
    justifyContent: 'center',
    borderRadius: 16,
    borderWidth: 1,
    borderColor: '#EF9A9A',
    backgroundColor: '#FFEBEE',
  },
  errorText: {
    fontFamily: fonts.regular,
    fontSize: 11,
    color: '#F44336',
    textAlign: 'center',
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
  card: {
    width: 260,
    borderRadius: 16,
    shadowOpacity: 0.3,
    shadowRadius: 8,
    shadowOffset: { width: 0, height: 4 },
    elevation: 4,
    height: 120,
  },
  cardInner: {
    flex: 1,
    flexDirection: 'row',
    borderRadius: 16,
    borderWidth: 1,
    borderColor: 'rgba(255, 255, 255, 0.1)',
    overflow: 'hidden',
  },
  left: {
    width: 80,
    alignItems: 'center',
    justifyContent: 'center',
    borderRightWidth: 2,
    borderRightColor: 'rgba(255, 255, 255, 0.3)',
  },
  percent: {
    fontFamily: fonts.bold,
    fontSize: 24,
    color: colors.white,
  },
  percentLabel: {
    fontFamily: fonts.medium,
    fontSize: 12,
    color: 'rgba(255, 255, 255, 0.7)',
  },
  opportunityLabel: {
    marginTop: 4,
    fontFamily: fonts.semiBold,
    fontSize: 11,
    color: 'rgba(255, 255, 255, 0.7)',
  },
  right: {
    flex: 1,
    padding: 12,
    justifyContent: 'center',
  },
  title: {
    fontFamily: fonts.bold,
    fontSize: 15,
    color: colors.white,
  },
  companyRow: {
    marginTop: 6,
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
