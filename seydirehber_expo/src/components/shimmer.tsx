import { LinearGradient } from 'expo-linear-gradient';
import { useEffect, useState } from 'react';
import { type DimensionValue, ScrollView, StyleSheet, View } from 'react-native';
import Animated, {
  Easing,
  useAnimatedStyle,
  useSharedValue,
  withRepeat,
  withTiming,
} from 'react-native-reanimated';

import { colors, spacing } from '@/theme';

// Flutter lib/core/widgets/shimmer_widget.dart karşılığı (shimmer paketi: 1.5 sn, soldan sağa).
const PERIOD_MS = 1500;

type ShimmerProps = {
  width?: DimensionValue;
  height?: DimensionValue;
  borderRadius?: number;
};

export function Shimmer({ width = '100%', height = '100%', borderRadius = 12 }: ShimmerProps) {
  const [layoutWidth, setLayoutWidth] = useState(0);
  const progress = useSharedValue(0);

  useEffect(() => {
    progress.value = withRepeat(withTiming(1, { duration: PERIOD_MS, easing: Easing.linear }), -1);
  }, [progress]);

  const sweepStyle = useAnimatedStyle(() => ({
    transform: [{ translateX: (progress.value * 2 - 1) * layoutWidth }],
  }));

  return (
    <View
      style={[styles.base, { width, height, borderRadius }]}
      onLayout={(event) => setLayoutWidth(event.nativeEvent.layout.width)}>
      {layoutWidth > 0 && (
        <Animated.View style={[StyleSheet.absoluteFill, sweepStyle]}>
          <LinearGradient
            colors={[colors.shimmerBase, colors.shimmerHighlight, colors.shimmerBase]}
            locations={[0.3, 0.5, 0.7]}
            start={{ x: 0, y: 0.5 }}
            end={{ x: 1, y: 0.5 }}
            style={StyleSheet.absoluteFill}
          />
        </Animated.View>
      )}
    </View>
  );
}

export function ShimmerList({
  itemCount = 3,
  itemHeight = 220,
  itemWidth = 250,
  borderRadius = 18,
}: {
  itemCount?: number;
  itemHeight?: number;
  itemWidth?: number;
  borderRadius?: number;
}) {
  return (
    <ScrollView
      horizontal
      scrollEnabled={false}
      showsHorizontalScrollIndicator={false}
      style={{ height: itemHeight }}
      contentContainerStyle={styles.horizontalList}>
      {Array.from({ length: itemCount }, (_, i) => (
        <Shimmer key={i} width={itemWidth} height={itemHeight} borderRadius={borderRadius} />
      ))}
    </ScrollView>
  );
}

export function NewsCardShimmer() {
  return (
    <View style={styles.newsCard}>
      <Shimmer height={200} borderRadius={20} />
      <View style={styles.newsBody}>
        <Shimmer height={20} width={200} />
        <View style={{ height: 10 }} />
        <Shimmer height={14} />
        <View style={{ height: 6 }} />
        <Shimmer height={14} width={250} />
        <View style={{ height: 16 }} />
        <View style={styles.spaceBetween}>
          <Shimmer height={12} width={80} />
          <Shimmer height={12} width={100} />
        </View>
      </View>
    </View>
  );
}

export function ListCardShimmer({ isGrid = false }: { isGrid?: boolean }) {
  return (
    <View style={[styles.listCard, !isGrid && { height: 220 }]}>
      <View style={{ flex: 3 }}>
        <Shimmer borderRadius={isGrid ? 16 : 20} />
      </View>
      {!isGrid && (
        <View style={styles.listCardFooter}>
          <View style={{ flex: 1, justifyContent: 'center' }}>
            <Shimmer height={16} width={150} />
            <View style={{ height: 6 }} />
            <Shimmer height={12} width={100} />
          </View>
          <Shimmer height={30} width={30} borderRadius={8} />
        </View>
      )}
    </View>
  );
}

export function ShimmerVerticalList({
  itemCount = 5,
  padding = 16,
}: {
  itemCount?: number;
  padding?: number;
}) {
  return (
    <View style={{ padding, gap: 16 }}>
      {Array.from({ length: itemCount }, (_, i) => (
        <Shimmer key={i} height={120} borderRadius={20} />
      ))}
    </View>
  );
}

export function SearchItemShimmer() {
  return (
    <View style={styles.row}>
      <Shimmer width={50} height={50} borderRadius={8} />
      <View style={{ width: 12 }} />
      <View style={{ flex: 1 }}>
        <Shimmer height={16} width={150} />
        <View style={{ height: 6 }} />
        <Shimmer height={12} width={100} />
      </View>
    </View>
  );
}

export function ShimmerSearchList() {
  return (
    <View style={{ gap: 16 }}>
      {Array.from({ length: 6 }, (_, i) => (
        <SearchItemShimmer key={i} />
      ))}
    </View>
  );
}

export function CouponCardShimmer() {
  return (
    <View style={styles.couponCard}>
      <Shimmer width={80} height={120} borderRadius={0} />
      <View style={styles.couponBody}>
        <Shimmer height={16} width="100%" />
        <View style={{ height: 8 }} />
        <Shimmer height={12} width={100} />
      </View>
    </View>
  );
}

export function HorizontalCardShimmer() {
  return (
    <View style={styles.horizontalCard}>
      <Shimmer height={120} width={160} borderRadius={16} />
      <View style={{ height: 8 }} />
      <Shimmer height={14} width={120} />
      <View style={{ height: 4 }} />
      <Shimmer height={10} width={80} />
    </View>
  );
}

export function BannerShimmer() {
  return (
    <View style={{ paddingHorizontal: spacing.lg }}>
      <Shimmer height={180} width="100%" borderRadius={20} />
    </View>
  );
}

function InfoCardShimmer() {
  return (
    <View style={styles.infoCard}>
      <Shimmer width={32} height={32} borderRadius={10} />
      <View style={{ width: 12 }} />
      <View>
        <Shimmer width={60} height={10} borderRadius={5} />
        <View style={{ height: 4 }} />
        <Shimmer width={80} height={12} borderRadius={6} />
      </View>
    </View>
  );
}

export function DetailShimmer() {
  return (
    <ScrollView scrollEnabled={false}>
      <Shimmer width="100%" height={450} borderRadius={0} />
      <View style={styles.detailBody}>
        <Shimmer width={250} height={30} borderRadius={15} />
        <View style={{ height: 12 }} />
        <Shimmer width={100} height={20} borderRadius={10} />
        <View style={{ height: 32 }} />
        <View style={styles.infoRow}>
          <View style={{ flex: 1 }}>
            <InfoCardShimmer />
          </View>
          <View style={{ flex: 1 }}>
            <InfoCardShimmer />
          </View>
        </View>
        <View style={{ height: 12 }} />
        <View style={styles.infoRow}>
          <View style={{ flex: 1 }}>
            <InfoCardShimmer />
          </View>
          <View style={{ flex: 1 }}>
            <InfoCardShimmer />
          </View>
        </View>
        <View style={{ height: 32 }} />
        <Shimmer width={140} height={24} borderRadius={12} />
        <View style={{ height: 16 }} />
        {Array.from({ length: 4 }, (_, i) => (
          <View key={i} style={{ marginBottom: 10 }}>
            <Shimmer width={i === 3 ? 200 : '100%'} height={14} borderRadius={7} />
          </View>
        ))}
        <View style={{ height: 32 }} />
        <Shimmer width="100%" height={200} borderRadius={20} />
      </View>
    </ScrollView>
  );
}

export function WebViewShimmer() {
  return (
    <ScrollView scrollEnabled={false} contentContainerStyle={{ padding: 20 }}>
      <Shimmer width="100%" height={300} borderRadius={20} />
      <View style={{ height: 20 }} />
      {Array.from({ length: 6 }, (_, i) => (
        <View key={i} style={{ marginBottom: 12 }}>
          <Shimmer width="100%" height={40} borderRadius={12} />
        </View>
      ))}
    </ScrollView>
  );
}

export function ReviewShimmer() {
  return (
    <View style={{ paddingVertical: 16 }}>
      <Shimmer width="100%" height={120} borderRadius={20} />
      <View style={{ height: 24 }} />
      {Array.from({ length: 3 }, (_, i) => (
        <View key={i} style={[styles.reviewRow, { marginBottom: 24 }]}>
          <Shimmer width={44} height={44} borderRadius={22} />
          <View style={{ width: 16 }} />
          <View style={{ flex: 1 }}>
            <Shimmer width={120} height={16} borderRadius={8} />
            <View style={{ height: 8 }} />
            <Shimmer width="100%" height={12} borderRadius={6} />
            <View style={{ height: 6 }} />
            <Shimmer width={180} height={12} borderRadius={6} />
          </View>
        </View>
      ))}
    </View>
  );
}

const styles = StyleSheet.create({
  base: {
    backgroundColor: colors.shimmerBase,
    overflow: 'hidden',
  },
  horizontalList: {
    paddingHorizontal: spacing.lg,
    gap: spacing.md,
  },
  newsCard: {
    backgroundColor: colors.white,
    borderRadius: 20,
  },
  newsBody: {
    padding: 20,
  },
  spaceBetween: {
    flexDirection: 'row',
    justifyContent: 'space-between',
  },
  listCard: {
    backgroundColor: colors.white,
    borderRadius: 20,
  },
  listCardFooter: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 15,
  },
  row: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  couponCard: {
    width: 260,
    height: 120,
    marginRight: spacing.md,
    flexDirection: 'row',
    backgroundColor: colors.white,
    borderRadius: 16,
    borderWidth: 1,
    borderColor: colors.border,
    overflow: 'hidden',
  },
  couponBody: {
    flex: 1,
    padding: spacing.md,
    justifyContent: 'center',
  },
  horizontalCard: {
    width: 160,
    marginRight: spacing.md,
  },
  detailBody: {
    paddingHorizontal: 20,
    paddingTop: 20,
  },
  infoRow: {
    flexDirection: 'row',
    gap: spacing.md,
  },
  infoCard: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: spacing.md,
    backgroundColor: colors.white,
    borderRadius: 16,
    borderWidth: 1,
    borderColor: colors.grey200,
  },
  reviewRow: {
    flexDirection: 'row',
    alignItems: 'flex-start',
  },
});
