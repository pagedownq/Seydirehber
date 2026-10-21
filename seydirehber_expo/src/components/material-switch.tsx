import { Pressable, StyleSheet, View } from 'react-native';
import Animated, { useAnimatedStyle, withTiming } from 'react-native-reanimated';

import { colors } from '@/theme';

// Flutter SwitchListTile(activeColor) içindeki Material 3 Switch karşılığı (iOS'ta da aynı görünüm):
// açıkken başparmak activeColor, iz activeColor %50; kapalıyken gri çerçeveli iz ve küçük gri başparmak.
type MaterialSwitchProps = {
  value: boolean;
  onValueChange: (value: boolean) => void;
  activeColor?: string;
};

const OFF_TRACK = '#DEE5D9';
const OUTLINE = '#72796F';

export function MaterialSwitch({ value, onValueChange, activeColor = colors.primary }: MaterialSwitchProps) {
  const thumbStyle = useAnimatedStyle(() => ({
    width: withTiming(value ? 24 : 16, { duration: 150 }),
    height: withTiming(value ? 24 : 16, { duration: 150 }),
    // Çerçeve içi koordinat (iç genişlik 48): kapalı başparmak merkezi 14, açık 34.
    transform: [{ translateX: withTiming(value ? 22 : 6, { duration: 150 }) }],
  }));

  return (
    <Pressable
      accessibilityRole="switch"
      accessibilityState={{ checked: value }}
      hitSlop={8}
      onPress={() => onValueChange(!value)}>
      <View
        style={[
          styles.track,
          value
            ? { backgroundColor: withAlpha(activeColor, 0.5), borderColor: 'transparent' }
            : { backgroundColor: OFF_TRACK, borderColor: OUTLINE },
        ]}>
        <Animated.View style={[styles.thumb, { backgroundColor: value ? activeColor : OUTLINE }, thumbStyle]} />
      </View>
    </Pressable>
  );
}

function withAlpha(hex: string, alpha: number) {
  const r = parseInt(hex.slice(1, 3), 16);
  const g = parseInt(hex.slice(3, 5), 16);
  const b = parseInt(hex.slice(5, 7), 16);
  return `rgba(${r}, ${g}, ${b}, ${alpha})`;
}

const styles = StyleSheet.create({
  track: {
    width: 52,
    height: 32,
    justifyContent: 'center',
    borderRadius: 16,
    borderWidth: 2,
  },
  thumb: {
    borderRadius: 12,
  },
});
