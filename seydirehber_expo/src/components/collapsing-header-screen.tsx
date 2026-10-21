import { LinearGradient } from 'expo-linear-gradient';
import type { ReactNode } from 'react';
import { StyleSheet, View } from 'react-native';
import Animated, {
  interpolate,
  useAnimatedScrollHandler,
  useAnimatedStyle,
  useSharedValue,
} from 'react-native-reanimated';
import { useSafeAreaInsets } from 'react-native-safe-area-context';

import { colors } from '@/theme';

// Flutter detay ekranlarındaki SliverAppBar(expandedHeight, pinned, FlexibleSpaceBar, bottom: 20px beyaz
// yuvarlak şerit) karşılığı. Görsel paralaks kayar; daralmanın son 2×56 pikselinde çubuk rengi belirir.
const TOOLBAR_HEIGHT = 56;
const BOTTOM_HEIGHT = 20;

type CollapsingHeaderScreenProps = {
  expandedHeight: number;
  /** Daralınca görünen çubuk rengi (Flutter SliverAppBar backgroundColor). */
  barColor: string;
  background: ReactNode;
  /** Görselin üstündeki karartma gradyanı (yukarıdan aşağıya); dokunmaları alttaki slider'a geçirir. */
  overlayColors: readonly [string, string, ...string[]];
  leading: ReactNode;
  actions?: ReactNode;
  bounces?: boolean;
  children: ReactNode;
};

export function CollapsingHeaderScreen({
  expandedHeight,
  barColor,
  background,
  overlayColors,
  leading,
  actions,
  bounces = false,
  children,
}: CollapsingHeaderScreenProps) {
  const insets = useSafeAreaInsets();
  const scrollY = useSharedValue(0);
  const headerHeight = insets.top + expandedHeight;
  const deltaExtent = expandedHeight - TOOLBAR_HEIGHT - BOTTOM_HEIGHT;
  // Flutter FlexibleSpaceBar: fadeStart = 1 - kToolbarHeight*2 / deltaExtent
  const fadeStart = Math.max(0, 1 - (TOOLBAR_HEIGHT * 2) / deltaExtent);

  const onScroll = useAnimatedScrollHandler((event) => {
    scrollY.value = event.contentOffset.y;
  });

  const backgroundStyle = useAnimatedStyle(() => ({
    transform: [{ translateY: Math.max(0, scrollY.value) * 0.5 }],
  }));

  const barStyle = useAnimatedStyle(() => {
    const t = scrollY.value / deltaExtent;
    return { opacity: interpolate(t, [fadeStart, 1], [0, 1], 'clamp') };
  });

  const pinnedStripStyle = useAnimatedStyle(() => ({
    opacity: scrollY.value >= deltaExtent ? 1 : 0,
  }));

  return (
    <View style={styles.container}>
      <Animated.ScrollView onScroll={onScroll} scrollEventThrottle={16} bounces={bounces}>
        <View style={{ height: headerHeight, overflow: 'hidden' }}>
          <Animated.View style={[StyleSheet.absoluteFill, backgroundStyle]}>
            {background}
            <LinearGradient pointerEvents="none" colors={overlayColors} style={StyleSheet.absoluteFill} />
          </Animated.View>
          <View style={styles.strip} />
        </View>
        {children}
      </Animated.ScrollView>

      <View pointerEvents="box-none" style={[styles.bar, { height: insets.top + TOOLBAR_HEIGHT + BOTTOM_HEIGHT }]}>
        <Animated.View
          pointerEvents="none"
          style={[styles.barBackground, { height: insets.top + TOOLBAR_HEIGHT, backgroundColor: barColor }, barStyle]}
        />
        <Animated.View
          pointerEvents="none"
          style={[styles.pinnedStrip, { top: insets.top + TOOLBAR_HEIGHT, backgroundColor: barColor }, pinnedStripStyle]}>
          <View style={styles.stripInner} />
        </Animated.View>
        <View pointerEvents="box-none" style={[styles.toolbar, { marginTop: insets.top }]}>
          {leading}
          <View style={{ flex: 1 }} />
          {actions}
        </View>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.white,
  },
  strip: {
    position: 'absolute',
    left: 0,
    right: 0,
    bottom: 0,
    height: BOTTOM_HEIGHT,
    borderTopLeftRadius: 38,
    borderTopRightRadius: 38,
    backgroundColor: colors.white,
  },
  bar: {
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
  },
  barBackground: {
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
  },
  pinnedStrip: {
    position: 'absolute',
    left: 0,
    right: 0,
    height: BOTTOM_HEIGHT,
  },
  stripInner: {
    flex: 1,
    borderTopLeftRadius: 38,
    borderTopRightRadius: 38,
    backgroundColor: colors.white,
  },
  toolbar: {
    height: TOOLBAR_HEIGHT,
    flexDirection: 'row',
    alignItems: 'center',
  },
});
