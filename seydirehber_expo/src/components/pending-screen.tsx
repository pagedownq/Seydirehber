import { MaterialIcons } from '@expo/vector-icons';
import type { ReactNode } from 'react';
import { ScrollView, StyleSheet, Text, View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';

import { colors, fonts, typography } from '@/theme';

// Taşıma sürerken henüz yazılmamış ekranların yerinde duran geçici görünüm (mağaza build'ine girmeden kalkacak).
export function PendingScreen({ title, step, children }: { title: string; step?: number; children?: ReactNode }) {
  return (
    <SafeAreaView style={styles.container} edges={['top']}>
      <ScrollView contentContainerStyle={styles.content}>
        <View style={styles.iconCircle}>
          <MaterialIcons name="construction" size={40} color={colors.primary} />
        </View>
        <Text style={styles.title}>{title}</Text>
        {step != null && (
          <Text style={styles.subtitle}>Bu ekran taşıma planının {step}. adımında eklenecek.</Text>
        )}
        {children}
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.background,
  },
  content: {
    flexGrow: 1,
    alignItems: 'center',
    justifyContent: 'center',
    padding: 32,
    gap: 12,
  },
  iconCircle: {
    padding: 20,
    borderRadius: 999,
    backgroundColor: colors.primarySurface,
  },
  title: {
    fontFamily: fonts.bold,
    fontSize: 20,
    color: colors.textPrimary,
  },
  subtitle: {
    ...typography.bodyMedium,
    color: colors.textSecondary,
    textAlign: 'center',
  },
});
