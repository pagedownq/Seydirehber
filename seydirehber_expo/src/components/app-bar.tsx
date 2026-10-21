import { MaterialIcons } from '@expo/vector-icons';
import { StatusBar } from 'expo-status-bar';
import type { ReactNode } from 'react';
import { Platform, Pressable, type StyleProp, StyleSheet, Text, type TextStyle, View } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';

import { colors, typography } from '@/theme';
import { goBack } from '@/utils/navigation';

// Flutter'daki varsayılan AppBar (tema: beyaz arka plan, başlık appBarTitle, centerTitle false) karşılığı.
// Geri butonu Flutter BackButton gibi platforma göre: iOS'ta ok başı, Android'de ok.
type AppBarProps = {
  title: string;
  titleColor?: string;
  centerTitle?: boolean;
  /** Başlık yerine özel içerik (ör. ikonlu başlık). */
  titleContent?: ReactNode;
  /** Başlık stilini değiştirmek için (ör. yazı boyutu). */
  titleStyle?: StyleProp<TextStyle>;
  actions?: ReactNode;
};

export function AppBar({
  title,
  titleColor = colors.primary,
  centerTitle = false,
  titleContent,
  titleStyle,
  actions,
}: AppBarProps) {
  const insets = useSafeAreaInsets();

  return (
    <View style={[styles.container, { paddingTop: insets.top }]}>
      <StatusBar style="dark" />
      <View style={styles.toolbar}>
        <Pressable hitSlop={8} style={styles.iconButton} onPress={goBack} accessibilityLabel="Geri">
          <MaterialIcons
            name={Platform.OS === 'ios' ? 'arrow-back-ios-new' : 'arrow-back'}
            size={24}
            color={colors.textPrimary}
          />
        </Pressable>
        {titleContent ? (
          <View style={[styles.title, styles.titleRow]}>{titleContent}</View>
        ) : (
          <Text
            style={[typography.appBarTitle, styles.title, { color: titleColor }, centerTitle && styles.centered, titleStyle]}
            numberOfLines={1}>
            {title}
          </Text>
        )}
        <View style={[styles.actions, centerTitle && { minWidth: 48 }]}>{actions}</View>
      </View>
    </View>
  );
}

export function AppBarIconButton({ icon, onPress }: { icon: React.ComponentProps<typeof MaterialIcons>['name']; onPress: () => void }) {
  return (
    <Pressable hitSlop={8} style={styles.iconButton} onPress={onPress}>
      <MaterialIcons name={icon} size={24} color={colors.textPrimary} />
    </Pressable>
  );
}

const styles = StyleSheet.create({
  container: {
    backgroundColor: colors.white,
  },
  toolbar: {
    height: 56,
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 4,
  },
  iconButton: {
    width: 48,
    height: 48,
    alignItems: 'center',
    justifyContent: 'center',
  },
  title: {
    flex: 1,
    marginLeft: 12,
  },
  titleRow: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  centered: {
    marginLeft: 0,
    textAlign: 'center',
  },
  actions: {
    flexDirection: 'row',
    alignItems: 'center',
  },
});
