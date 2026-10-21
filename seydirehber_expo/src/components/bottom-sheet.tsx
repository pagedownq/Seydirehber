import type { ReactNode } from 'react';
import { KeyboardAvoidingView, Modal, Platform, Pressable, StyleSheet, View } from 'react-native';
import Animated, { SlideInDown } from 'react-native-reanimated';
import { useSafeAreaInsets } from 'react-native-safe-area-context';

import { colors } from '@/theme';

// Flutter showModalBottomSheet(backgroundColor: transparent) karşılığı: alttan kayan, dışına dokununca kapanan sayfa.
// İçeriğin arka planı ve köşe yuvarlaklığı çağıran tarafta verilir (Flutter'daki gibi).
type BottomSheetProps = {
  visible: boolean;
  onClose: () => void;
  children: ReactNode;
  /** Klavye açılınca içerik yukarı itilsin (isScrollControlled + viewInsets). */
  avoidKeyboard?: boolean;
  /** Alt güvenli alan beyazla doldurulsun mu? Kenarlardan boşluklu (yüzen) kartlarda false. */
  fillBottomInset?: boolean;
};

export function BottomSheet({
  visible,
  onClose,
  children,
  avoidKeyboard = false,
  fillBottomInset = true,
}: BottomSheetProps) {
  const insets = useSafeAreaInsets();

  const content = (
    <View style={styles.container}>
      <Pressable style={styles.barrier} onPress={onClose} />
      <Animated.View entering={SlideInDown.duration(250)} style={{ paddingBottom: 0 }}>
        {children}
        {fillBottomInset && <View style={{ height: insets.bottom, backgroundColor: colors.white }} />}
      </Animated.View>
    </View>
  );

  return (
    <Modal visible={visible} transparent animationType="fade" statusBarTranslucent onRequestClose={onClose}>
      {avoidKeyboard ? (
        <KeyboardAvoidingView style={{ flex: 1 }} behavior={Platform.OS === 'ios' ? 'padding' : 'height'}>
          {content}
        </KeyboardAvoidingView>
      ) : (
        content
      )}
    </Modal>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'flex-end',
  },
  barrier: {
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
    bottom: 0,
    backgroundColor: colors.barrier,
  },
});
