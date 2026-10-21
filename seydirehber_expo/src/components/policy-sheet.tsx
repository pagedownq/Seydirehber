import { MaterialIcons } from '@expo/vector-icons';
import { Modal, Pressable, ScrollView, StyleSheet, Text, useWindowDimensions, View } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';

import { colors, typography } from '@/theme';

// Flutter _showPolicyDetail (onboarding + politikalar ekranı) karşılığı: ekranın %80'i kadar alt sayfa.
type PolicySheetProps = {
  policy: { title: string; content: string } | null;
  onClose: () => void;
};

export function PolicySheet({ policy, onClose }: PolicySheetProps) {
  const { height } = useWindowDimensions();
  const insets = useSafeAreaInsets();

  return (
    <Modal
      visible={policy != null}
      transparent
      animationType="slide"
      statusBarTranslucent
      onRequestClose={onClose}>
      <Pressable style={styles.barrier} onPress={onClose} />
      {policy && (
        <View style={[styles.sheet, { height: height * 0.8, paddingBottom: 24 + insets.bottom }]}>
          <View style={styles.header}>
            <Text style={[typography.heading2, styles.title]}>{policy.title}</Text>
            <Pressable onPress={onClose} hitSlop={8} style={styles.close}>
              <MaterialIcons name="close" size={24} color={colors.textPrimary} />
            </Pressable>
          </View>
          <View style={styles.divider} />
          <ScrollView style={{ flex: 1 }}>
            <Text style={styles.content}>{policy.content}</Text>
          </ScrollView>
        </View>
      )}
    </Modal>
  );
}

const styles = StyleSheet.create({
  barrier: {
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
    bottom: 0,
    backgroundColor: colors.barrier,
  },
  sheet: {
    position: 'absolute',
    left: 0,
    right: 0,
    bottom: 0,
    padding: 24,
    borderTopLeftRadius: 24,
    borderTopRightRadius: 24,
    backgroundColor: colors.white,
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
  },
  title: {
    flex: 1,
  },
  close: {
    padding: 8,
  },
  divider: {
    height: 1,
    marginVertical: 16,
    backgroundColor: colors.divider,
  },
  content: {
    ...typography.bodyMedium,
    lineHeight: 22.4,
  },
});
