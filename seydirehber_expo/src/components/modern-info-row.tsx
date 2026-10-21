import { MaterialCommunityIcons, MaterialIcons } from '@expo/vector-icons';
import type { ComponentProps } from 'react';
import { StyleSheet, Text, View } from 'react-native';

import { colors, fonts } from '@/theme';

// Flutter etkinlik/firma detayındaki _buildModernInfoRow karşılığı.
type ModernInfoRowProps = {
  icon: ComponentProps<typeof MaterialIcons>['name'] | { community: ComponentProps<typeof MaterialCommunityIcons>['name'] };
  label: string;
  value: string;
  /** Etkinlikte 20 / 15, firmada 25 / 16. */
  bottomSpacing?: number;
  valueSize?: number;
};

export function ModernInfoRow({ icon, label, value, bottomSpacing = 20, valueSize = 15 }: ModernInfoRowProps) {
  return (
    <View style={[styles.row, { marginBottom: bottomSpacing }]}>
      <View style={styles.iconBox}>
        {typeof icon === 'string' ? (
          <MaterialIcons name={icon} size={24} color={colors.primaryDark} />
        ) : (
          <MaterialCommunityIcons name={icon.community} size={24} color={colors.primaryDark} />
        )}
      </View>
      <View style={styles.texts}>
        <Text style={styles.label}>{label}</Text>
        <Text style={[styles.value, { fontSize: valueSize }]}>{value}</Text>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  row: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  iconBox: {
    padding: 12,
    borderRadius: 15,
    backgroundColor: colors.primarySurface,
  },
  texts: {
    flex: 1,
    marginLeft: 20,
  },
  label: {
    fontFamily: fonts.extraBold,
    fontSize: 11,
    letterSpacing: 1.2,
    color: '#9E9E9E',
  },
  value: {
    marginTop: 4,
    fontFamily: fonts.bold,
    color: colors.black87,
  },
});
