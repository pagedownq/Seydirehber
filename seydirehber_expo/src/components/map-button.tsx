import { MaterialIcons } from '@expo/vector-icons';
import { Pressable, StyleSheet, Text } from 'react-native';

import { haptics } from '@/services/haptics';
import { colors, radius, typography } from '@/theme';
import { openMapWithAddress } from '@/utils/map';

// Flutter lib/core/widgets/map_button.dart karşılığı.
type MapButtonProps = {
  locationUrl: string;
  label?: string;
};

export function MapButton({ locationUrl, label = 'Harita Üzerinden Göster' }: MapButtonProps) {
  return (
    <Pressable
      onPress={() => {
        haptics.vibrate();
        openMapWithAddress(locationUrl);
      }}
      style={({ pressed }) => [styles.button, pressed && styles.pressed]}>
      <MaterialIcons name="map" size={20} color={colors.textOnPrimary} />
      <Text style={styles.label}>{label}</Text>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  button: {
    width: '100%',
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 8,
    paddingVertical: 14,
    borderRadius: radius.button,
    backgroundColor: colors.primary,
  },
  pressed: {
    opacity: 0.85,
  },
  label: typography.button,
});
