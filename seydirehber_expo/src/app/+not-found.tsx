import { usePathname } from 'expo-router';
import { Pressable, StyleSheet, Text } from 'react-native';

import { PendingScreen } from '@/components/pending-screen';
import { colors, radius, typography } from '@/theme';
import { goBack } from '@/utils/navigation';

// Taşıma sürerken henüz yazılmamış route'lara gidildiğinde gösterilir.
export default function NotFound() {
  const pathname = usePathname();

  return (
    <PendingScreen title={pathname}>
      <Text style={typography.bodySmall}>Bu ekran henüz taşınmadı.</Text>
      <Pressable
        style={styles.button}
        onPress={() => goBack()}>
        <Text style={typography.button}>Geri Dön</Text>
      </Pressable>
    </PendingScreen>
  );
}

const styles = StyleSheet.create({
  button: {
    paddingHorizontal: 24,
    paddingVertical: 12,
    borderRadius: radius.button,
    backgroundColor: colors.primary,
  },
});
