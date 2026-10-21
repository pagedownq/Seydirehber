import { MaterialCommunityIcons } from '@expo/vector-icons';
import { useState } from 'react';
import { KeyboardAvoidingView, Modal, Platform, Pressable, StyleSheet, Text, TextInput, View } from 'react-native';

import { colors, fonts, typography } from '@/theme';

// Flutter lib/features/auth/widgets/name_request_dialog.dart karşılığı. Ana kabukta, giriş yapmış ama
// adı olmayan kullanıcıya gösterilir; kapatılamaz.
type NameRequestDialogProps = {
  visible: boolean;
  onSave: (fullName: string) => void;
};

export function NameRequestDialog({ visible, onSave }: NameRequestDialogProps) {
  const [name, setName] = useState('');
  const [error, setError] = useState<string | null>(null);

  const save = () => {
    if (name.trim().length < 3) {
      setError('Lütfen geçerli bir ad soyad girin');
      return;
    }
    setError(null);
    onSave(name.trim());
  };

  return (
    <Modal visible={visible} transparent animationType="fade" statusBarTranslucent onRequestClose={() => {}}>
      <KeyboardAvoidingView behavior={Platform.OS === 'ios' ? 'padding' : undefined} style={styles.barrier}>
        <View style={styles.dialog}>
          <View style={styles.iconCircle}>
            <MaterialCommunityIcons name="account-plus-outline" size={32} color={colors.primary} />
          </View>
          <Text style={[typography.heading3, styles.title]}>Adınız ve Soyadınız</Text>
          <Text style={[typography.bodySmall, styles.subtitle]}>
            Size hitap edebilmemiz ve yorumlarınızda isminizin görünmesi için lütfen bilgilerinizi girin.
          </Text>
          <TextInput
            value={name}
            onChangeText={(value) => {
              setName(value);
              if (error) setError(null);
            }}
            placeholder="Ad Soyad"
            placeholderTextColor={colors.textLight}
            autoFocus
            autoCapitalize="words"
            style={[styles.input, error != null && styles.inputError]}
          />
          {error && <Text style={styles.errorText}>{error}</Text>}
          <Pressable onPress={save} style={({ pressed }) => [styles.button, pressed && styles.pressed]}>
            <Text style={typography.button}>Kaydet ve Başla</Text>
          </Pressable>
        </View>
      </KeyboardAvoidingView>
    </Modal>
  );
}

const styles = StyleSheet.create({
  barrier: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    paddingHorizontal: 40,
    backgroundColor: colors.barrier,
  },
  dialog: {
    width: '100%',
    maxWidth: 560,
    alignItems: 'center',
    padding: 24,
    borderRadius: 24,
    backgroundColor: colors.white,
    elevation: 6,
  },
  iconCircle: {
    padding: 16,
    borderRadius: 999,
    backgroundColor: colors.primarySurface,
  },
  title: {
    marginTop: 20,
    textAlign: 'center',
  },
  subtitle: {
    marginTop: 12,
    textAlign: 'center',
  },
  input: {
    alignSelf: 'stretch',
    marginTop: 24,
    paddingHorizontal: 16,
    paddingVertical: 14,
    borderRadius: 16,
    backgroundColor: '#F5F5F5',
    fontFamily: fonts.regular,
    fontSize: 16,
    color: colors.textPrimary,
  },
  inputError: {
    borderWidth: 1,
    borderColor: colors.error,
  },
  errorText: {
    alignSelf: 'stretch',
    marginTop: 8,
    marginLeft: 12,
    fontFamily: fonts.regular,
    fontSize: 12,
    color: colors.error,
  },
  button: {
    alignSelf: 'stretch',
    height: 52,
    marginTop: 24,
    alignItems: 'center',
    justifyContent: 'center',
    borderRadius: 16,
    backgroundColor: colors.primary,
  },
  pressed: {
    opacity: 0.85,
  },
});
