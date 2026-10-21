import { MaterialIcons } from '@expo/vector-icons';
import { useState } from 'react';
import {
  ActivityIndicator,
  Keyboard,
  KeyboardAvoidingView,
  Platform,
  Pressable,
  ScrollView,
  StyleSheet,
  Switch,
  Text,
  TextInput,
  View,
} from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';

import { AppBar } from '@/components/app-bar';
import { showSnackbar } from '@/components/snackbar';
import { useUser } from '@/features/auth/auth-store';
import { createPost } from '@/features/forum/forum-service';
import { FORUM_CATEGORIES } from '@/features/forum/forum-types';
import { haptics } from '@/services/haptics';
import { colors, fonts, typography } from '@/theme';
import { goBack } from '@/utils/navigation';

// Flutter lib/features/forum/screens/forum_create_screen.dart karşılığı.
function validateTitle(value: string) {
  if (!value.trim()) return 'Başlık boş bırakılamaz.';
  if (value.trim().length < 5) return 'Başlık en az 5 karakter olmalıdır.';
  return null;
}

function validateContent(value: string) {
  if (!value.trim()) return 'İçerik boş bırakılamaz.';
  if (value.trim().length < 20) return 'İçerik en az 20 karakter olmalıdır.';
  return null;
}

export function ForumCreateScreen() {
  const insets = useSafeAreaInsets();
  const user = useUser();
  const [category, setCategory] = useState('genel');
  const [title, setTitle] = useState('');
  const [content, setContent] = useState('');
  const [isAnonymous, setIsAnonymous] = useState(false);
  const [submitting, setSubmitting] = useState(false);
  const [errors, setErrors] = useState<{ title: string | null; content: string | null }>({ title: null, content: null });

  const submit = async () => {
    const nextErrors = { title: validateTitle(title), content: validateContent(content) };
    setErrors(nextErrors);
    if (nextErrors.title || nextErrors.content) return;
    Keyboard.dismiss();
    if (!user) return;

    setSubmitting(true);
    try {
      await createPost({
        userId: user.uid,
        displayName: user.displayName ?? 'Kullanıcı',
        photoUrl: user.photoURL ?? null,
        isAnonymous,
        title: title.trim(),
        content: content.trim(),
        category,
      });
      goBack();
      showSnackbar({ message: 'Gönderiniz paylaşıldı! 🎉', backgroundColor: colors.success, borderRadius: 12 });
    } catch (error) {
      showSnackbar({
        message: `Gönderi paylaşılamadı: ${error instanceof Error ? error.message : String(error)}`,
        floating: false,
      });
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <View style={styles.container}>
      <AppBar title="Yeni Gönderi" centerTitle titleStyle={{ fontSize: 18, fontFamily: fonts.extraBold }} />
      <KeyboardAvoidingView style={{ flex: 1 }} behavior={Platform.OS === 'ios' ? 'padding' : undefined}>
        <ScrollView contentContainerStyle={styles.content} keyboardShouldPersistTaps="handled">
          <Text style={styles.label}>Kategori Seçin</Text>
          <View style={styles.categories}>
            {FORUM_CATEGORIES.filter((c) => c.value !== 'tumu').map((cat) => {
              const selected = category === cat.value;
              return (
                <Pressable
                  key={cat.value}
                  onPress={() => {
                    haptics.selection();
                    setCategory(cat.value);
                  }}
                  style={[styles.categoryChip, selected ? styles.categorySelected : styles.categoryIdle]}>
                  <Text
                    style={{
                      fontFamily: selected ? fonts.bold : fonts.semiBold,
                      fontSize: 13,
                      color: selected ? colors.white : colors.textSecondary,
                    }}>
                    {`${cat.emoji} ${cat.label}`}
                  </Text>
                </Pressable>
              );
            })}
          </View>

          <Text style={[styles.label, { marginTop: 28 }]}>Başlık</Text>
          <FormInput
            value={title}
            onChangeText={setTitle}
            placeholder="Konuyu kısaca özetleyin..."
            maxLength={200}
            error={errors.title}
            inputStyle={{ fontFamily: fonts.semiBold }}
          />

          <Text style={[styles.label, { marginTop: 20 }]}>İçerik</Text>
          <FormInput
            value={content}
            onChangeText={setContent}
            placeholder="Sorunuzu veya paylaşmak istediğiniz bilgiyi detaylıca yazın..."
            maxLength={2000}
            error={errors.content}
            multiline
          />

          <Pressable
            onPress={() => {
              haptics.selection();
              setIsAnonymous((v) => !v);
            }}
            style={[
              styles.anonymousCard,
              {
                backgroundColor: isAnonymous ? 'rgba(76, 175, 80, 0.08)' : '#FAFAFA',
                borderColor: isAnonymous ? 'rgba(76, 175, 80, 0.5)' : 'rgba(158, 158, 158, 0.2)',
              },
            ]}>
            <View style={[styles.anonymousIcon, { backgroundColor: isAnonymous ? 'rgba(76, 175, 80, 0.2)' : '#EEEEEE' }]}>
              <MaterialIcons
                name={isAnonymous ? 'person-off' : 'person'}
                size={20}
                color={isAnonymous ? colors.primary : '#757575'}
              />
            </View>
            <View style={{ flex: 1, marginLeft: 14 }}>
              <Text style={[typography.bodyMedium, { fontFamily: fonts.bold }]}>Anonim Olarak Paylaş</Text>
              <Text style={[typography.caption, { marginTop: 2, color: colors.textSecondary }]}>Gönderide isminiz gizlenir</Text>
            </View>
            <Switch
              value={isAnonymous}
              onValueChange={(v) => {
                haptics.selection();
                setIsAnonymous(v);
              }}
              trackColor={{ true: colors.primary, false: '#E0E0E0' }}
              thumbColor={colors.white}
            />
          </Pressable>

          <View style={styles.notice}>
            <MaterialIcons name="info" size={20} color="#F57F17" />
            <Text style={styles.noticeText}>
              Topluluk kurallarına uygun paylaşım yapmanız önemlidir. İhlaller içerik gizlenmesine yol açabilir.
            </Text>
          </View>
        </ScrollView>

        <View style={[styles.bottom, { paddingBottom: 16 + insets.bottom }]}>
          <Pressable
            disabled={submitting}
            onPress={() => {
              haptics.selection();
              submit();
            }}
            style={[styles.submit, submitting && { backgroundColor: 'rgba(76, 175, 80, 0.5)', elevation: 0, shadowOpacity: 0 }]}>
            {submitting ? (
              <ActivityIndicator color={colors.white} />
            ) : (
              <Text style={[typography.button, { fontSize: 16, fontFamily: fonts.bold }]}>Gönderiyi Paylaş</Text>
            )}
          </Pressable>
        </View>
      </KeyboardAvoidingView>
    </View>
  );
}

function FormInput({
  value,
  onChangeText,
  placeholder,
  maxLength,
  error,
  multiline = false,
  inputStyle,
}: {
  value: string;
  onChangeText: (value: string) => void;
  placeholder: string;
  maxLength: number;
  error: string | null;
  multiline?: boolean;
  inputStyle?: object;
}) {
  const [focused, setFocused] = useState(false);
  return (
    <View>
      <TextInput
        value={value}
        onChangeText={onChangeText}
        placeholder={placeholder}
        placeholderTextColor={colors.textLight}
        maxLength={maxLength}
        multiline={multiline}
        numberOfLines={multiline ? 8 : 1}
        textAlignVertical={multiline ? 'top' : 'center'}
        onFocus={() => setFocused(true)}
        onBlur={() => setFocused(false)}
        style={[
          styles.input,
          multiline && { minHeight: 180 },
          inputStyle,
          focused && styles.inputFocused,
          error != null && !focused && styles.inputError,
        ]}
      />
      <View style={styles.helperRow}>
        <Text style={styles.errorText}>{error ?? ''}</Text>
        <Text style={styles.counter}>
          {value.length}/{maxLength}
        </Text>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.white,
  },
  content: {
    paddingHorizontal: 20,
    paddingVertical: 12,
    paddingBottom: 20,
  },
  label: {
    ...typography.bodyMedium,
    marginBottom: 8,
    fontFamily: fonts.bold,
  },
  categories: {
    marginTop: 4,
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 10,
  },
  categoryChip: {
    paddingHorizontal: 16,
    paddingVertical: 10,
    borderRadius: 20,
  },
  categorySelected: {
    backgroundColor: colors.primary,
    shadowColor: colors.primary,
    shadowOpacity: 0.3,
    shadowRadius: 8,
    shadowOffset: { width: 0, height: 4 },
    elevation: 4,
  },
  categoryIdle: {
    backgroundColor: '#F5F5F5',
  },
  input: {
    ...typography.bodyMedium,
    paddingHorizontal: 18,
    paddingVertical: 16,
    borderRadius: 16,
    borderWidth: 2,
    borderColor: 'transparent',
    backgroundColor: '#F8F9FA',
  },
  inputFocused: {
    borderColor: colors.primary,
  },
  inputError: {
    borderWidth: 1,
    borderColor: colors.error,
  },
  helperRow: {
    marginTop: 4,
    paddingHorizontal: 12,
    flexDirection: 'row',
    justifyContent: 'space-between',
  },
  errorText: {
    flex: 1,
    fontFamily: fonts.regular,
    fontSize: 12,
    color: colors.error,
  },
  counter: {
    fontFamily: fonts.regular,
    fontSize: 12,
    color: colors.textSecondary,
  },
  anonymousCard: {
    marginTop: 20,
    flexDirection: 'row',
    alignItems: 'center',
    padding: 16,
    borderRadius: 16,
    borderWidth: 1,
  },
  anonymousIcon: {
    padding: 10,
    borderRadius: 999,
  },
  notice: {
    marginTop: 16,
    flexDirection: 'row',
    alignItems: 'flex-start',
    gap: 10,
    padding: 14,
    borderRadius: 16,
    borderWidth: 1,
    borderColor: 'rgba(251, 192, 45, 0.3)',
    backgroundColor: 'rgba(255, 253, 231, 0.5)',
  },
  noticeText: {
    ...typography.caption,
    flex: 1,
    lineHeight: 15.4,
    fontFamily: fonts.semiBold,
    color: '#F57F17',
  },
  bottom: {
    paddingHorizontal: 20,
    paddingTop: 16,
    backgroundColor: colors.white,
    shadowColor: '#000000',
    shadowOpacity: 0.03,
    shadowRadius: 10,
    shadowOffset: { width: 0, height: -4 },
    elevation: 4,
  },
  submit: {
    height: 56,
    alignItems: 'center',
    justifyContent: 'center',
    borderRadius: 16,
    backgroundColor: colors.primary,
    shadowColor: colors.primary,
    shadowOpacity: 0.4,
    shadowRadius: 4,
    shadowOffset: { width: 0, height: 2 },
    elevation: 4,
  },
});
