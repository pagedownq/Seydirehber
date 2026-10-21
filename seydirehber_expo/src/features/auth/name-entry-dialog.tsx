import { useState } from 'react';
import { KeyboardAvoidingView, Modal, Platform, Pressable, StyleSheet, Text, TextInput, View } from 'react-native';
import { create } from 'zustand';

import { colors, fonts } from '@/theme';

// Flutter onboarding _showNameEntryDialog karşılığı: kapatılamaz, en az 3 karakter girilmeden "Kaydet" çalışmaz.
// iOS'ta CupertinoAlertDialog, Android'de Material AlertDialog görünümü.
// Kullanım: const name = await askForName(); — <NameEntryDialogHost /> onboarding ekranında durur.
const useNameDialogStore = create<{ resolve: ((name: string) => void) | null }>(() => ({ resolve: null }));

export function askForName(): Promise<string> {
  return new Promise((resolve) => useNameDialogStore.setState({ resolve }));
}

export function NameEntryDialogHost() {
  const resolve = useNameDialogStore((state) => state.resolve);
  const [name, setName] = useState('');
  const isIOS = Platform.OS === 'ios';

  const save = () => {
    const trimmed = name.trim();
    if (trimmed.length < 3) return;
    useNameDialogStore.setState({ resolve: null });
    setName('');
    resolve?.(trimmed);
  };

  return (
    <Modal visible={resolve != null} transparent animationType="fade" statusBarTranslucent onRequestClose={() => {}}>
      <KeyboardAvoidingView behavior={isIOS ? 'padding' : undefined} style={styles.barrier}>
        {isIOS ? (
          <View style={styles.iosDialog}>
            <View style={styles.iosBody}>
              <Text style={styles.iosTitle}>Profilini Tamamla</Text>
              <Text style={styles.iosMessage}>Uygulama içinde görünecek adınızı ve soyadınızı giriniz.</Text>
              <TextInput
                value={name}
                onChangeText={setName}
                placeholder="Ad Soyad"
                placeholderTextColor="#C2C2C2"
                autoFocus
                autoCapitalize="words"
                style={styles.iosInput}
              />
            </View>
            <Pressable onPress={save} style={({ pressed }) => [styles.iosAction, pressed && styles.iosPressed]}>
              <Text style={styles.iosActionText}>Kaydet</Text>
            </Pressable>
          </View>
        ) : (
          <View style={styles.androidDialog}>
            <Text style={styles.androidTitle}>Profilini Tamamla</Text>
            <Text style={styles.androidMessage}>Uygulama içinde görünecek adınızı ve soyadınızı giriniz.</Text>
            <View style={styles.androidField}>
              <Text style={styles.androidLabel}>Ad Soyad</Text>
              <TextInput
                value={name}
                onChangeText={setName}
                placeholder="Örn: Ahmet Yılmaz"
                placeholderTextColor={colors.textLight}
                autoFocus
                autoCapitalize="words"
                style={styles.androidInput}
              />
            </View>
            <Pressable onPress={save} style={styles.androidAction} hitSlop={8}>
              <Text style={styles.androidActionText}>KAYDET</Text>
            </Pressable>
          </View>
        )}
      </KeyboardAvoidingView>
    </Modal>
  );
}

const styles = StyleSheet.create({
  barrier: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: colors.barrier,
  },
  iosDialog: {
    width: 270,
    borderRadius: 14,
    overflow: 'hidden',
    backgroundColor: 'rgba(242, 242, 242, 0.97)',
  },
  iosBody: {
    paddingTop: 19,
    paddingHorizontal: 16,
    paddingBottom: 16,
    alignItems: 'center',
  },
  iosTitle: {
    fontSize: 17,
    fontWeight: '600',
    color: '#000000',
    textAlign: 'center',
  },
  iosMessage: {
    marginTop: 8,
    fontSize: 13,
    color: '#000000',
    textAlign: 'center',
  },
  iosInput: {
    alignSelf: 'stretch',
    marginTop: 16,
    padding: 12,
    borderRadius: 8,
    borderWidth: 1,
    borderColor: '#BCBCC0',
    backgroundColor: colors.white,
    fontSize: 17,
    color: '#000000',
  },
  iosAction: {
    height: 44,
    alignItems: 'center',
    justifyContent: 'center',
    borderTopWidth: StyleSheet.hairlineWidth,
    borderTopColor: 'rgba(60, 60, 67, 0.36)',
  },
  iosPressed: {
    backgroundColor: 'rgba(0, 0, 0, 0.05)',
  },
  iosActionText: {
    fontSize: 17,
    color: '#007AFF',
  },
  androidDialog: {
    width: '80%',
    maxWidth: 560,
    padding: 24,
    borderRadius: 28,
    backgroundColor: '#F7FBF2',
  },
  androidTitle: {
    fontFamily: fonts.regular,
    fontSize: 24,
    color: colors.textPrimary,
  },
  androidMessage: {
    marginTop: 16,
    fontFamily: fonts.regular,
    fontSize: 14,
    color: colors.textSecondary,
  },
  androidField: {
    marginTop: 16,
    borderWidth: 1,
    borderColor: colors.textSecondary,
    borderRadius: 4,
    paddingHorizontal: 12,
    paddingTop: 6,
    paddingBottom: 4,
  },
  androidLabel: {
    fontFamily: fonts.regular,
    fontSize: 12,
    color: colors.primary,
  },
  androidInput: {
    paddingVertical: 6,
    fontFamily: fonts.regular,
    fontSize: 16,
    color: colors.textPrimary,
  },
  androidAction: {
    alignSelf: 'flex-end',
    marginTop: 24,
    paddingHorizontal: 12,
    paddingVertical: 10,
  },
  androidActionText: {
    fontFamily: fonts.medium,
    fontSize: 14,
    color: colors.primary,
  },
});
