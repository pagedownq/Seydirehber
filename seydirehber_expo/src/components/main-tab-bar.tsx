import { MaterialCommunityIcons, MaterialIcons } from '@expo/vector-icons';
import type { BottomTabBarProps } from 'expo-router/js-tabs';
import type { ReactNode } from 'react';
import { Pressable, StyleSheet, Text, View } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';

import { haptics } from '@/services/haptics';
import { colors, fonts } from '@/theme';

// Flutter main_shell.dart içindeki Material 3 NavigationBar karşılığı:
// yükseklik 65, seçili ikonun arkasında primarySurface hap göstergesi, etiketler her zaman görünür.
const TABS: Record<string, { label: string; icon: ReactNode; selectedIcon: ReactNode }> = {
  index: {
    label: 'Ana Sayfa',
    icon: <MaterialCommunityIcons name="home-outline" size={24} color="#414941" />,
    selectedIcon: <MaterialIcons name="home" size={24} color={colors.primary} />,
  },
  news: {
    label: 'Haberler',
    icon: <MaterialIcons name="newspaper" size={24} color="#414941" />,
    selectedIcon: <MaterialIcons name="newspaper" size={24} color={colors.primary} />,
  },
  settings: {
    label: 'Ayarlar',
    icon: <MaterialCommunityIcons name="cog-outline" size={24} color="#414941" />,
    selectedIcon: <MaterialIcons name="settings" size={24} color={colors.primary} />,
  },
};

export function MainTabBar({ state, emitter, navigateToTab }: BottomTabBarProps) {
  const insets = useSafeAreaInsets();

  return (
    <View style={[styles.container, { paddingBottom: insets.bottom }]}>
      <View style={styles.bar}>
        {state.routes.map((route, index) => {
          const tab = TABS[route.name];
          if (!tab) return null;
          const focused = state.index === index;

          return (
            <Pressable
              key={route.key}
              style={styles.item}
              accessibilityRole="tab"
              accessibilityState={{ selected: focused }}
              onPress={() => {
                haptics.selection();
                // Aynı sekmeye basılınca tabPress olayı ekranı başa kaydırır (useScrollToTop).
                const event = emitter.emit({ type: 'tabPress', target: route.key, canPreventDefault: true });
                if (!focused && !event.defaultPrevented) navigateToTab(route.key);
              }}>
              <View style={[styles.indicator, focused && styles.indicatorActive]}>
                {focused ? tab.selectedIcon : tab.icon}
              </View>
              <Text style={[styles.label, focused && styles.labelActive]}>{tab.label}</Text>
            </Pressable>
          );
        })}
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    backgroundColor: colors.white,
    shadowColor: '#000000',
    shadowOpacity: 0.06,
    shadowRadius: 10,
    shadowOffset: { width: 0, height: -2 },
    elevation: 8,
  },
  bar: {
    height: 65,
    flexDirection: 'row',
  },
  item: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    gap: 4,
  },
  indicator: {
    width: 64,
    height: 32,
    alignItems: 'center',
    justifyContent: 'center',
    borderRadius: 16,
  },
  indicatorActive: {
    backgroundColor: colors.primarySurface,
  },
  label: {
    fontFamily: fonts.medium,
    fontSize: 12,
    color: '#414941',
  },
  labelActive: {
    color: '#191C19',
  },
});
