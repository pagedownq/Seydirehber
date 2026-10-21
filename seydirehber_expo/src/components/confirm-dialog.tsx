import { MaterialIcons } from '@expo/vector-icons';
import type { ComponentProps } from 'react';
import { Modal, Pressable, StyleSheet, Text, View } from 'react-native';
import { create } from 'zustand';

import { haptics } from '@/services/haptics';
import { colors, fonts } from '@/theme';

// Flutter lib/core/widgets/modern_confirm_dialog.dart karşılığı.
// Kullanım: const ok = await showConfirmDialog({...}); — <ConfirmDialogHost /> kök layout'ta bir kez durur.
type ConfirmOptions = {
  title: string;
  content: string;
  confirmLabel: string;
  cancelLabel: string;
  icon: ComponentProps<typeof MaterialIcons>['name'];
  iconColor: string;
  isDestructive?: boolean;
};

type DialogState = {
  options: ConfirmOptions | null;
  resolve: ((value: boolean) => void) | null;
};

const useDialogStore = create<DialogState>(() => ({ options: null, resolve: null }));

export function showConfirmDialog(options: ConfirmOptions): Promise<boolean> {
  haptics.medium();
  return new Promise((resolve) => {
    useDialogStore.getState().resolve?.(false);
    useDialogStore.setState({ options, resolve });
  });
}

function close(result: boolean) {
  const { resolve } = useDialogStore.getState();
  useDialogStore.setState({ options: null, resolve: null });
  resolve?.(result);
}

const withOpacity = (hex: string, opacity: number) =>
  `${hex}${Math.round(opacity * 255)
    .toString(16)
    .padStart(2, '0')}`;

export function ConfirmDialogHost() {
  const options = useDialogStore((state) => state.options);

  return (
    <Modal
      visible={options != null}
      transparent
      animationType="fade"
      statusBarTranslucent
      onRequestClose={() => close(false)}>
      <Pressable style={styles.barrier} onPress={() => close(false)}>
        {options && (
          <Pressable style={styles.dialog}>
            <View style={[styles.iconCircle, { backgroundColor: withOpacity(options.iconColor, 0.08) }]}>
              <MaterialIcons name={options.icon} size={32} color={options.iconColor} />
            </View>
            <Text style={styles.title}>{options.title}</Text>
            <Text style={styles.content}>{options.content}</Text>
            <View style={styles.buttons}>
              <Pressable
                onPress={() => {
                  haptics.selection();
                  close(false);
                }}
                style={({ pressed }) => [styles.button, styles.cancel, pressed && styles.pressed]}>
                <Text style={styles.cancelText}>{options.cancelLabel}</Text>
              </Pressable>
              <Pressable
                onPress={() => {
                  haptics.selection();
                  close(true);
                }}
                style={({ pressed }) => [
                  styles.button,
                  { backgroundColor: options.isDestructive ? colors.error : colors.primary },
                  pressed && styles.pressed,
                ]}>
                <Text style={styles.confirmText}>{options.confirmLabel}</Text>
              </Pressable>
            </View>
          </Pressable>
        )}
      </Pressable>
    </Modal>
  );
}

const styles = StyleSheet.create({
  barrier: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    paddingHorizontal: 40,
    paddingVertical: 24,
    backgroundColor: colors.barrier,
  },
  dialog: {
    width: '100%',
    maxWidth: 560,
    alignItems: 'center',
    paddingTop: 28,
    paddingHorizontal: 24,
    paddingBottom: 24,
    borderRadius: 28,
    backgroundColor: colors.white,
    elevation: 16,
  },
  iconCircle: {
    padding: 18,
    borderRadius: 999,
  },
  title: {
    marginTop: 20,
    fontFamily: fonts.black,
    fontSize: 18,
    letterSpacing: -0.3,
    color: colors.black87,
    textAlign: 'center',
  },
  content: {
    marginTop: 12,
    fontFamily: fonts.medium,
    fontSize: 14,
    lineHeight: 21,
    color: colors.grey600,
    textAlign: 'center',
  },
  buttons: {
    marginTop: 28,
    flexDirection: 'row',
    gap: 12,
    alignSelf: 'stretch',
  },
  button: {
    flex: 1,
    alignItems: 'center',
    paddingVertical: 14,
    borderRadius: 16,
  },
  cancel: {
    borderWidth: 1.5,
    borderColor: colors.grey200,
  },
  pressed: {
    opacity: 0.85,
  },
  cancelText: {
    fontFamily: fonts.bold,
    fontSize: 14,
    color: colors.black87,
  },
  confirmText: {
    fontFamily: fonts.bold,
    fontSize: 14,
    color: colors.white,
  },
});
