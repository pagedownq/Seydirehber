import { MaterialIcons } from '@expo/vector-icons';
import { Pressable, StyleSheet, Text, View } from 'react-native';

import { haptics } from '@/services/haptics';
import { colors, fonts, typography } from '@/theme';

// Flutter lib/core/widgets/see_all_button.dart karşılığı: bölüm başlığı + "Tümünü Gör".
type SeeAllButtonProps = {
  title: string;
  onPress: () => void;
};

export function SeeAllButton({ title, onPress }: SeeAllButtonProps) {
  return (
    <View style={styles.row}>
      <Text style={styles.title} numberOfLines={1}>
        {title}
      </Text>
      <Pressable
        onPress={() => {
          haptics.selection();
          onPress();
        }}
        hitSlop={4}
        style={({ pressed }) => [styles.button, pressed && styles.pressed]}>
        <Text style={styles.label}>Tümünü Gör</Text>
        <MaterialIcons name="arrow-forward-ios" size={12} color={colors.primary} />
      </Pressable>
    </View>
  );
}

const styles = StyleSheet.create({
  row: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
  },
  title: {
    ...typography.sectionTitle,
    flex: 1,
  },
  button: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 20,
  },
  pressed: {
    backgroundColor: 'rgba(76, 175, 80, 0.1)',
  },
  label: {
    ...typography.bodySmall,
    fontFamily: fonts.semiBold,
    color: colors.primary,
  },
});
