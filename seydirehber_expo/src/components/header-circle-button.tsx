import { MaterialIcons } from '@expo/vector-icons';
import type { ComponentProps } from 'react';
import { Pressable, StyleSheet } from 'react-native';

// Flutter detay ekranlarındaki AppBar düğmeleri: margin 8, siyah %30 daire içinde ikon.
type HeaderCircleButtonProps = {
  icon: ComponentProps<typeof MaterialIcons>['name'];
  color: string;
  size?: number;
  onPress: () => void;
  accessibilityLabel?: string;
};

export function HeaderCircleButton({ icon, color, size = 20, onPress, accessibilityLabel }: HeaderCircleButtonProps) {
  return (
    <Pressable accessibilityLabel={accessibilityLabel} onPress={onPress} style={styles.button}>
      <MaterialIcons name={icon} size={size} color={color} />
    </Pressable>
  );
}

const styles = StyleSheet.create({
  button: {
    width: 40,
    height: 40,
    margin: 8,
    alignItems: 'center',
    justifyContent: 'center',
    borderRadius: 20,
    backgroundColor: 'rgba(0, 0, 0, 0.3)',
  },
});
