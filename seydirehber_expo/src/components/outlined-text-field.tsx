import { type ReactNode, useState } from 'react';
import { type KeyboardTypeOptions, Pressable, StyleSheet, Text, TextInput, View } from 'react-native';

import { colors, fonts } from '@/theme';

// Flutter TextField + uygulama teması inputDecorationTheme karşılığı: beyaz dolgu, #E0E0E0 çerçeve,
// odakta 2 px yeşil, radius 12; labelText boşken alanın içinde, odakta/doluyken çerçevenin üstünde.
type OutlinedTextFieldProps = {
  label: string;
  value: string;
  onChangeText?: (value: string) => void;
  /** Odaktayken ve boşken gösterilen ipucu (Flutter hintText). Verilmezse label kullanılır. */
  hint?: string;
  multiline?: boolean;
  lines?: number;
  keyboardType?: KeyboardTypeOptions;
  readOnly?: boolean;
  /** Salt okunur alanlarda dokunma (tarih/firma seçici gibi). */
  onPress?: () => void;
  suffix?: ReactNode;
  borderRadius?: number;
  autoCapitalize?: 'none' | 'sentences' | 'words' | 'characters';
};

export function OutlinedTextField({
  label,
  value,
  onChangeText,
  hint,
  multiline = false,
  lines = 4,
  keyboardType,
  readOnly = false,
  onPress,
  suffix,
  borderRadius = 12,
  autoCapitalize,
}: OutlinedTextFieldProps) {
  const [focused, setFocused] = useState(false);
  const floating = focused || value.length > 0;

  const box = (
    <View
      style={[
        styles.box,
        { borderRadius, borderColor: focused ? colors.primary : colors.border, borderWidth: focused ? 2 : 1 },
        multiline && { minHeight: lines * 22 + 30, alignItems: 'flex-start' },
      ]}>
      {onPress ? (
        <Text style={[styles.input, multiline && styles.multiline, !value && { color: colors.textSecondary }]}>
          {value || label}
        </Text>
      ) : (
        <TextInput
          value={value}
          onChangeText={onChangeText}
          editable={!readOnly}
          placeholder={focused ? (hint ?? label) : label}
          placeholderTextColor={colors.textSecondary}
          multiline={multiline}
          numberOfLines={multiline ? lines : 1}
          textAlignVertical={multiline ? 'top' : 'center'}
          keyboardType={keyboardType}
          autoCapitalize={autoCapitalize}
          onFocus={() => setFocused(true)}
          onBlur={() => setFocused(false)}
          style={[styles.input, multiline && styles.multiline]}
        />
      )}
      {suffix && <View style={styles.suffix}>{suffix}</View>}
      {floating && (
        <Text style={[styles.floatingLabel, { color: focused ? colors.primary : colors.textSecondary }]}>{label}</Text>
      )}
    </View>
  );

  return onPress ? <Pressable onPress={onPress}>{box}</Pressable> : box;
}

const styles = StyleSheet.create({
  box: {
    minHeight: 52,
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.white,
  },
  input: {
    flex: 1,
    paddingHorizontal: 16,
    paddingVertical: 14,
    fontFamily: fonts.regular,
    fontSize: 16,
    color: colors.textPrimary,
  },
  multiline: {
    alignSelf: 'stretch',
  },
  suffix: {
    paddingRight: 12,
    alignSelf: 'center',
  },
  floatingLabel: {
    position: 'absolute',
    top: -9,
    left: 12,
    paddingHorizontal: 4,
    backgroundColor: colors.white,
    fontFamily: fonts.regular,
    fontSize: 12,
  },
});
