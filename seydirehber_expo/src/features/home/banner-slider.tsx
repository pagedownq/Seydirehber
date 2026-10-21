import { type Href, router } from 'expo-router';
import { Linking, Pressable, StyleSheet, useWindowDimensions, View } from 'react-native';
import Animated, {
  useAnimatedScrollHandler,
  useAnimatedStyle,
  useSharedValue,
  type SharedValue,
} from 'react-native-reanimated';

import { CachedImage } from '@/components/cached-image';
import { BannerShimmer } from '@/components/shimmer';
import { useBanners } from '@/features/home/home-queries';
import { haptics } from '@/services/haptics';
import { colors } from '@/theme';
import { str } from '@/utils/firestore-values';

// Flutter lib/features/home/widgets/banner_slider.dart karşılığı: 4:1 oranlı, kaydırmalı banner.
async function launchUrl(url: string) {
  const finalUrl = url.startsWith('http://') || url.startsWith('https://') ? url : `https://${url}`;
  try {
    if (await Linking.canOpenURL(finalUrl)) await Linking.openURL(finalUrl);
  } catch (error) {
    console.warn('Error launching URL:', error);
  }
}

export function BannerSlider() {
  const banners = useBanners();
  const { width } = useWindowDimensions();
  const scrollX = useSharedValue(0);
  const onScroll = useAnimatedScrollHandler((event) => {
    scrollX.value = event.contentOffset.x;
  });

  if (banners.status === 'loading') return <BannerShimmer />;
  if (banners.status === 'error' || banners.docs.length === 0) return null;

  const imageWidth = width - 32;
  const imageHeight = imageWidth / 4;

  return (
    <View>
      <Animated.ScrollView
        horizontal
        pagingEnabled
        showsHorizontalScrollIndicator={false}
        onScroll={onScroll}
        scrollEventThrottle={16}
        style={{ height: imageHeight }}>
        {banners.docs.map((banner) => {
          const imageUrl = str(banner.data.image_url);
          const companyId = str(banner.data.company_id);
          const targetUrl = str(banner.data.url);
          return (
            <Pressable
              key={banner.id}
              style={[styles.page, { width }]}
              onPress={() => {
                haptics.selection();
                if (companyId) router.push(`/companies/${companyId}` as Href);
                else if (targetUrl) launchUrl(targetUrl);
              }}>
              <View style={styles.shadow}>
                <CachedImage imageUrl={imageUrl} width={imageWidth} height={imageHeight} borderRadius={16} />
              </View>
            </Pressable>
          );
        })}
      </Animated.ScrollView>
      {banners.docs.length > 1 && (
        <WormIndicator count={banners.docs.length} scrollX={scrollX} pageWidth={width} />
      )}
    </View>
  );
}

const DOT = 8;
const SPACING = 8;

// Flutter WormEffect: aktif nokta bir sonrakine doğru uzayıp sonra toparlanır.
function WormIndicator({
  count,
  scrollX,
  pageWidth,
}: {
  count: number;
  scrollX: SharedValue<number>;
  pageWidth: number;
}) {
  const step = DOT + SPACING;
  const wormStyle = useAnimatedStyle(() => {
    const position = Math.max(0, Math.min(count - 1, scrollX.value / pageWidth));
    const index = Math.floor(position);
    const fraction = position - index;
    const left = index * step + Math.max(0, (fraction - 0.5) * 2) * step;
    const right = index * step + DOT + Math.min(1, fraction * 2) * step;
    return { left, width: right - left };
  });

  return (
    <View style={styles.indicatorRow}>
      <View style={{ width: count * DOT + (count - 1) * SPACING, height: DOT }}>
        {Array.from({ length: count }, (_, i) => (
          <View key={i} style={[styles.dot, { left: i * step }]} />
        ))}
        <Animated.View style={[styles.worm, wormStyle]} />
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  page: {
    paddingHorizontal: 16,
  },
  shadow: {
    borderRadius: 16,
    backgroundColor: colors.white,
    shadowColor: '#000000',
    shadowOpacity: 0.08,
    shadowRadius: 12,
    shadowOffset: { width: 0, height: 4 },
    elevation: 4,
  },
  indicatorRow: {
    marginTop: 10,
    alignItems: 'center',
  },
  dot: {
    position: 'absolute',
    width: DOT,
    height: DOT,
    borderRadius: DOT / 2,
    backgroundColor: colors.border,
  },
  worm: {
    position: 'absolute',
    height: DOT,
    borderRadius: DOT / 2,
    backgroundColor: colors.primary,
  },
});
