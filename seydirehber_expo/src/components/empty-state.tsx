import { MaterialIcons } from '@expo/vector-icons';
import type { ComponentProps } from 'react';
import { Pressable, StyleSheet, Text, View } from 'react-native';

import { colors, fonts, typography } from '@/theme';

// Flutter lib/core/widgets/empty_state_widget.dart karşılığı.
type EmptyStateProps = {
  icon: ComponentProps<typeof MaterialIcons>['name'];
  title: string;
  subtitle: string;
  actionLabel?: string;
  onActionPress?: () => void;
};

export function EmptyState({ icon, title, subtitle, actionLabel, onActionPress }: EmptyStateProps) {
  return (
    <View style={styles.container}>
      <View style={styles.iconCircle}>
        <MaterialIcons name={icon} size={64} color={colors.primary} style={styles.icon} />
      </View>
      <Text style={styles.title}>{title}</Text>
      <Text style={styles.subtitle}>{subtitle}</Text>
      {onActionPress && actionLabel ? (
        <Pressable
          onPress={onActionPress}
          style={({ pressed }) => [styles.button, pressed && styles.pressed]}>
          <Text style={styles.buttonText}>{actionLabel}</Text>
        </Pressable>
      ) : null}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    paddingHorizontal: 40,
  },
  iconCircle: {
    padding: 24,
    borderRadius: 999,
    backgroundColor: 'rgba(76, 175, 80, 0.05)',
  },
  icon: {
    opacity: 0.4,
  },
  title: {
    ...typography.heading2,
    marginTop: 24,
    fontFamily: fonts.extraBold,
    fontSize: 20,
    textAlign: 'center',
  },
  subtitle: {
    ...typography.bodyMedium,
    marginTop: 12,
    lineHeight: 21,
    textAlign: 'center',
  },
  button: {
    marginTop: 32,
    paddingHorizontal: 32,
    paddingVertical: 12,
    borderRadius: 50,
    backgroundColor: colors.primary,
    shadowColor: colors.primary,
    shadowOpacity: 0.4,
    shadowRadius: 4,
    shadowOffset: { width: 0, height: 2 },
    elevation: 4,
  },
  pressed: {
    opacity: 0.85,
  },
  buttonText: {
    fontFamily: fonts.bold,
    fontSize: 16,
    color: colors.white,
  },
});
