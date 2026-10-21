import { MaterialIcons } from '@expo/vector-icons';
import type { ComponentProps } from 'react';
import { useEffect } from 'react';
import { StyleSheet, Text, View } from 'react-native';
import Animated, {
  Easing,
  useAnimatedStyle,
  useSharedValue,
  withDelay,
  withSequence,
  withTiming,
} from 'react-native-reanimated';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { create } from 'zustand';

import { colors, fonts, typography } from '@/theme';

// Flutter lib/core/utils/app_notification.dart karşılığı: üstten kayan, 3 sn sonra kaybolan bildirim.
// <AppNotificationHost /> kök layout'ta bir kez durur.
type IconName = ComponentProps<typeof MaterialIcons>['name'];
type NotificationItem = { id: number; message: string; isError: boolean; icon?: IconName };

const DURATION_MS = 3000;
const ANIMATION_MS = 500;
const REVERSE_AT_MS = 2600;

let nextId = 0;
const useNotificationStore = create<{ items: NotificationItem[] }>(() => ({ items: [] }));

function show(message: string, options: { isError?: boolean; icon?: IconName } = {}) {
  const item = { id: nextId++, message, isError: options.isError ?? false, icon: options.icon };
  useNotificationStore.setState((state) => ({ items: [...state.items, item] }));
  setTimeout(() => {
    useNotificationStore.setState((state) => ({ items: state.items.filter((i) => i.id !== item.id) }));
  }, DURATION_MS);
}

export const appNotification = {
  show,
  success: (message: string) => show(message, { icon: 'check-circle' }),
  error: (message: string) => show(message, { isError: true, icon: 'error' }),
};

// Flutter Curves.easeOutBack
const easeOutBack = Easing.bezier(0.175, 0.885, 0.32, 1.275);

function NotificationToast({ item, top }: { item: NotificationItem; top: number }) {
  const slide = useSharedValue(0);
  const fade = useSharedValue(0);

  useEffect(() => {
    slide.value = withSequence(
      withTiming(1, { duration: ANIMATION_MS, easing: easeOutBack }),
      withDelay(REVERSE_AT_MS - ANIMATION_MS, withTiming(0, { duration: ANIMATION_MS, easing: easeOutBack })),
    );
    fade.value = withSequence(
      withTiming(1, { duration: ANIMATION_MS, easing: Easing.in(Easing.ease) }),
      withDelay(REVERSE_AT_MS - ANIMATION_MS, withTiming(0, { duration: ANIMATION_MS })),
    );
  }, [slide, fade]);

  const animatedStyle = useAnimatedStyle(() => ({
    opacity: fade.value,
    // Flutter SlideTransition Offset(0, -1): kendi yüksekliği kadar yukarıdan gelir.
    transform: [{ translateY: (slide.value - 1) * 100 }],
  }));

  return (
    <Animated.View
      pointerEvents="none"
      style={[
        styles.toast,
        { top, backgroundColor: item.isError ? colors.red800 : colors.primary },
        animatedStyle,
      ]}>
      <MaterialIcons
        name={item.icon ?? (item.isError ? 'error' : 'info')}
        size={24}
        color={colors.white}
      />
      <Text style={styles.message}>{item.message}</Text>
    </Animated.View>
  );
}

export function AppNotificationHost() {
  const items = useNotificationStore((state) => state.items);
  const insets = useSafeAreaInsets();

  return (
    <View pointerEvents="none" style={StyleSheet.absoluteFill}>
      {items.map((item) => (
        <NotificationToast key={item.id} item={item} top={insets.top + 10} />
      ))}
    </View>
  );
}

const styles = StyleSheet.create({
  toast: {
    position: 'absolute',
    left: 16,
    right: 16,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
    paddingHorizontal: 16,
    paddingVertical: 12,
    borderRadius: 16,
    shadowColor: '#000000',
    shadowOpacity: 0.2,
    shadowRadius: 10,
    shadowOffset: { width: 0, height: 4 },
    elevation: 6,
  },
  message: {
    ...typography.bodyMedium,
    flex: 1,
    fontFamily: fonts.bold,
    color: colors.white,
  },
});
