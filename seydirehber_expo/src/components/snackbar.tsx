import { Pressable, StyleSheet, Text, useWindowDimensions, View } from 'react-native';
import Animated, { FadeIn, FadeOut } from 'react-native-reanimated';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { create } from 'zustand';

import { colors, fonts } from '@/theme';

// Flutter ScaffoldMessenger.showSnackBar karşılığı (alttan çıkan mesaj çubuğu).
// <SnackbarHost /> kök layout'ta bir kez durur. Yeni mesaj eskisinin yerini alır.
type SnackbarOptions = {
  message: string;
  backgroundColor?: string;
  /** Flutter SnackBarBehavior.floating; false ise ekranın altına yapışık tam genişlik. */
  floating?: boolean;
  /** Ekran yüksekliğine oranla alttan boşluk (Flutter margin bottom: height * x). */
  bottomRatio?: number;
  borderRadius?: number;
  durationMs?: number;
  action?: { label: string; onPress: () => void };
};

type SnackbarItem = SnackbarOptions & { id: number };

let nextId = 0;
let timer: ReturnType<typeof setTimeout> | null = null;
const useSnackbarStore = create<{ current: SnackbarItem | null }>(() => ({ current: null }));

// Flutter Colors.* karşılıkları
export const snackbarColors = {
  green: '#4CAF50',
  redAccent: '#FF5252',
  orange: '#FF9800',
  error: colors.error,
};

export function showSnackbar(options: SnackbarOptions) {
  if (timer) clearTimeout(timer);
  const item = { ...options, id: nextId++ };
  useSnackbarStore.setState({ current: item });
  timer = setTimeout(() => hideSnackbar(item.id), options.durationMs ?? 4000);
}

export function hideSnackbar(id?: number) {
  const current = useSnackbarStore.getState().current;
  if (current && (id == null || current.id === id)) useSnackbarStore.setState({ current: null });
}

export function SnackbarHost() {
  const current = useSnackbarStore((state) => state.current);
  const insets = useSafeAreaInsets();
  const { height } = useWindowDimensions();

  if (!current) return null;

  const floating = current.floating ?? true;
  const bottom = floating
    ? Math.max(insets.bottom, 0) + (current.bottomRatio != null ? height * current.bottomRatio : 10)
    : 0;

  return (
    <View pointerEvents="box-none" style={StyleSheet.absoluteFill}>
      <Animated.View
        key={current.id}
        entering={FadeIn.duration(250)}
        exiting={FadeOut.duration(250)}
        style={[
          styles.bar,
          floating ? styles.floating : [styles.fixed, { paddingBottom: 14 + insets.bottom }],
          {
            bottom,
            backgroundColor: current.backgroundColor ?? '#323232',
            borderRadius: floating ? (current.borderRadius ?? 4) : 0,
          },
        ]}>
        <Text style={styles.message}>{current.message}</Text>
        {current.action && (
          <Pressable
            hitSlop={8}
            onPress={() => {
              current.action?.onPress();
              hideSnackbar(current.id);
            }}>
            <Text style={styles.action}>{current.action.label}</Text>
          </Pressable>
        )}
      </Animated.View>
    </View>
  );
}

const styles = StyleSheet.create({
  bar: {
    position: 'absolute',
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
    paddingHorizontal: 16,
    paddingVertical: 14,
    elevation: 6,
    shadowColor: '#000000',
    shadowOpacity: 0.2,
    shadowRadius: 6,
    shadowOffset: { width: 0, height: 3 },
  },
  floating: {
    left: 20,
    right: 20,
  },
  fixed: {
    left: 0,
    right: 0,
  },
  message: {
    flex: 1,
    fontFamily: fonts.regular,
    fontSize: 14,
    color: colors.white,
  },
  action: {
    fontFamily: fonts.medium,
    fontSize: 14,
    color: colors.white,
  },
});
