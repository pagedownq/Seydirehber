import { MaterialIcons } from '@expo/vector-icons';
import { Pressable, StyleSheet, View } from 'react-native';
import Animated, {
  Easing,
  interpolate,
  useAnimatedStyle,
  useSharedValue,
  withSequence,
  withTiming,
  type SharedValue,
} from 'react-native-reanimated';

import { appNotification } from '@/components/app-notification';
import { type FavoriteType, toggleFavorite, useIsFavorite } from '@/features/favorites/favorites-store';
import { haptics } from '@/services/haptics';

// Flutter lib/core/widgets/favorite_button.dart karşılığı: kalp büyüyüp küçülür, etrafına parçacık saçılır.
type FavoriteButtonProps = {
  id: string;
  type: FavoriteType;
  size?: number;
  color?: string;
  showBackground?: boolean;
};

const DURATION = 600;
const PARTICLE_COUNT = 10;
const RED = '#F44336';

// Flutter Curves.easeOutBack / easeInBack
const easeOutBack = Easing.bezier(0.175, 0.885, 0.32, 1.275);
const easeInBack = Easing.bezier(0.6, -0.28, 0.735, 0.045);

export function FavoriteButton({ id, type, size = 20, color = '#FFFFFF', showBackground = true }: FavoriteButtonProps) {
  const isFav = useIsFavorite(id, type);
  const scale = useSharedValue(1);
  const progress = useSharedValue(0);

  const onPress = () => {
    haptics.vibrate();
    const willBeFavorite = !isFav;
    toggleFavorite(id, type);

    // Flutter: ölçek 0–0.6 aralığında (1 → 1.5 → 1), parçacıklar 0.2–1 aralığında
    scale.value = withSequence(
      withTiming(1.5, { duration: DURATION * 0.6 * 0.4, easing: easeOutBack }),
      withTiming(1, { duration: DURATION * 0.6 * 0.6, easing: easeInBack }),
    );
    progress.value = 0;
    progress.value = withSequence(
      withTiming(0, { duration: DURATION * 0.2 }),
      withTiming(1, { duration: DURATION * 0.8, easing: Easing.out(Easing.ease) }),
    );

    if (willBeFavorite) appNotification.success('Favorilere eklendi');
    else appNotification.show('Favorilerden çıkarıldı', { icon: 'favorite-border' });
  };

  const iconStyle = useAnimatedStyle(() => ({ transform: [{ scale: scale.value }] }));
  const burstSize = size * 3;

  return (
    <View style={styles.wrapper}>
      {isFav && (
        <View pointerEvents="none" style={[styles.burst, { width: burstSize, height: burstSize }]}>
          {Array.from({ length: PARTICLE_COUNT }, (_, i) => (
            <Particle key={i} index={i} progress={progress} radius={burstSize / 2} />
          ))}
        </View>
      )}
      <Pressable
        onPress={onPress}
        style={showBackground ? styles.background : undefined}
        hitSlop={showBackground ? 0 : 8}>
        <Animated.View style={iconStyle}>
          <MaterialIcons name={isFav ? 'favorite' : 'favorite-border'} size={size} color={isFav ? RED : color} />
        </Animated.View>
      </Pressable>
    </View>
  );
}

function Particle({ index, progress, radius }: { index: number; progress: SharedValue<number>; radius: number }) {
  const angle = (index * 2 * Math.PI) / PARTICLE_COUNT;
  const subAngle = angle + Math.PI / PARTICLE_COUNT;

  const mainStyle = useAnimatedStyle(() => {
    const p = progress.value;
    const visible = p > 0 && p < 1;
    const distance = radius * p * 1.1;
    const particleSize = (1 - p) * 3 + 1;
    return {
      opacity: visible ? interpolate(p, [0, 1], [1, 0]) : 0,
      width: particleSize * 2,
      height: particleSize * 2,
      borderRadius: particleSize,
      transform: [
        { translateX: radius + distance * Math.cos(angle) - particleSize },
        { translateY: radius + distance * Math.sin(angle) - particleSize },
      ],
    };
  });

  const subStyle = useAnimatedStyle(() => {
    const p = progress.value;
    const visible = p > 0 && p < 1;
    const distance = radius * p * 1.1 * 0.7;
    const particleSize = ((1 - p) * 3 + 1) * 0.6;
    return {
      opacity: visible ? interpolate(p, [0, 1], [0.7, 0]) : 0,
      width: particleSize * 2,
      height: particleSize * 2,
      borderRadius: particleSize,
      transform: [
        { translateX: radius + distance * Math.cos(subAngle) - particleSize },
        { translateY: radius + distance * Math.sin(subAngle) - particleSize },
      ],
    };
  });

  return (
    <>
      <Animated.View style={[styles.particle, mainStyle]} />
      <Animated.View style={[styles.particle, subStyle]} />
    </>
  );
}

const styles = StyleSheet.create({
  wrapper: {
    alignItems: 'center',
    justifyContent: 'center',
  },
  burst: {
    position: 'absolute',
  },
  particle: {
    position: 'absolute',
    left: 0,
    top: 0,
    backgroundColor: RED,
  },
  background: {
    margin: 8,
    padding: 8,
    borderRadius: 999,
    backgroundColor: 'rgba(0, 0, 0, 0.35)',
  },
});
