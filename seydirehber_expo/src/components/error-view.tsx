import { MaterialIcons } from '@expo/vector-icons';
import type { ComponentProps } from 'react';
import { Pressable, StyleSheet, Text, View } from 'react-native';

import { colors, fonts, radius, typography } from '@/theme';

// Flutter lib/core/widgets/error_view.dart karşılığı.
type ErrorViewProps = {
  title?: string;
  message?: string;
  icon?: ComponentProps<typeof MaterialIcons>['name'];
  onRetry: () => void;
};

export function ErrorView({
  title = 'İnternet Bağlantısı Yok',
  message = 'Lütfen internet bağlantınızı kontrol edin ve tekrar deneyin.',
  icon = 'wifi-off',
  onRetry,
}: ErrorViewProps) {
  return (
    <View style={styles.container}>
      <View style={styles.iconCircle}>
        <MaterialIcons name={icon} size={60} color={colors.primary} />
      </View>
      <Text style={styles.title}>{title}</Text>
      <Text style={styles.message}>{message}</Text>
      <Pressable
        onPress={onRetry}
        style={({ pressed }) => [styles.button, pressed && styles.pressed]}>
        <MaterialIcons name="refresh" size={18} color={colors.white} />
        <Text style={styles.buttonText}>Tekrar Dene</Text>
      </Pressable>
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
    backgroundColor: 'rgba(76, 175, 80, 0.1)',
  },
  title: {
    marginTop: 24,
    fontFamily: fonts.bold,
    fontSize: 20,
    color: colors.textPrimary,
    textAlign: 'center',
  },
  message: {
    marginTop: 12,
    fontFamily: fonts.regular,
    fontSize: 14,
    lineHeight: 21,
    color: colors.textLight,
    textAlign: 'center',
  },
  button: {
    marginTop: 32,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    paddingHorizontal: 24,
    paddingVertical: 12,
    borderRadius: radius.button,
    backgroundColor: colors.primary,
  },
  pressed: {
    opacity: 0.85,
  },
  buttonText: {
    ...typography.button,
    color: colors.white,
  },
});
