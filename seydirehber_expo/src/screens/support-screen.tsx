import { MaterialIcons } from '@expo/vector-icons';
import { getMessaging, getToken } from '@react-native-firebase/messaging';
import { addDoc, collection, serverTimestamp } from '@react-native-firebase/firestore';
import { type Href, router } from 'expo-router';
import { type ComponentProps, type ComponentRef, useRef, useState } from 'react';
import {
  ActivityIndicator,
  KeyboardAvoidingView,
  type KeyboardTypeOptions,
  Modal,
  Platform,
  Pressable,
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  View,
} from 'react-native';

import { AppBar } from '@/components/app-bar';
import { showSnackbar, snackbarColors } from '@/components/snackbar';
import { useIsGuest, useUser } from '@/features/auth/auth-store';
import { db } from '@/services/firebase';
import { haptics } from '@/services/haptics';
import { showLocalNotification } from '@/services/notifications';
import { colors, fonts, typography } from '@/theme';

// Flutter lib/features/support/screens/support_screen.dart karşılığı (koleksiyon: yardim_destek).
type IconName = ComponentProps<typeof MaterialIcons>['name'];

const CATEGORIES = [
  'Mekan / Firma Ekleme Talebi',
  'Öneri',
  'Şikayet',
  'Hata Bildirimi',
  'İş Birliği & Reklam',
  'Diğer',
];

export function SupportScreen() {
  const user = useUser();
  const isGuest = useIsGuest();
  // Giriş yapmış kullanıcının adı ve e-postası önceden doldurulur.
  const [name, setName] = useState(user?.displayName ?? '');
  const [email, setEmail] = useState(user?.email ?? '');
  const [phone, setPhone] = useState('');
  const [message, setMessage] = useState('');
  const [category, setCategory] = useState(CATEGORIES[0]);
  const [sending, setSending] = useState(false);
  const [errors, setErrors] = useState<{ name: string | null; message: string | null }>({ name: null, message: null });

  const submit = async () => {
    const nextErrors = {
      name: name.trim() ? null : 'Lütfen adınızı girin',
      message: message.length < 5 ? 'Lütfen en az 5 karakterlik bir mesaj yazın' : null,
    };
    setErrors(nextErrors);
    if (nextErrors.name || nextErrors.message) return;

    const trimmedEmail = email.trim();
    const trimmedPhone = phone.trim();
    if (!trimmedEmail && !trimmedPhone) {
      showSnackbar({
        message: 'Lütfen size ulaşabileceğimiz bir e-posta veya telefon numarası girin.',
        backgroundColor: snackbarColors.orange,
      });
      return;
    }

    setSending(true);
    try {
      // Hedefli bildirim için FCM token
      let fcmToken: string | null = null;
      try {
        fcmToken = await getToken(getMessaging());
      } catch (error) {
        console.warn('FCM Token get error:', error);
      }

      await addDoc(collection(db, 'yardim_destek'), {
        ad_soyad: name.trim(),
        email: trimmedEmail,
        telefon: trimmedPhone,
        kategori: category,
        mesaj: message.trim(),
        uid: user?.uid ?? 'guest',
        is_guest: user == null || isGuest,
        tarih: serverTimestamp(),
        durum: 'Bekliyor',
        fcm_token: fcmToken ?? '',
      });

      showLocalNotification(
        'Destek Talebi Alındı 📩',
        'Yardım & Destek talebiniz gönderilmiştir. En kısa zamanda dönüş yapılacaktır. Teşekkürler!',
      );
      await new Promise((resolve) => setTimeout(resolve, 500));
      // Flutter context.go('/'): Ana Sayfa'ya döner.
      router.dismissTo('/' as Href);
    } catch (error) {
      showSnackbar({ message: `Hata oluştu: ${String(error)}`, backgroundColor: colors.error });
    } finally {
      setSending(false);
    }
  };

  return (
    <View style={styles.container}>
      <AppBar title="Yardım & Destek" />
      <KeyboardAvoidingView style={{ flex: 1 }} behavior={Platform.OS === 'ios' ? 'padding' : undefined}>
        <ScrollView contentContainerStyle={styles.content} keyboardShouldPersistTaps="handled">
          <Text style={typography.heading2}>Size nasıl yardımcı olabiliriz?</Text>
          <Text style={[typography.bodySmall, { marginTop: 8 }]}>
            Görüşleriniz bizim için çok değerli. Lütfen formu eksiksiz doldurun.
          </Text>
          <View style={{ height: 24 }} />

          <Label text="Ad Soyad" />
          <Field
            value={name}
            onChangeText={setName}
            placeholder="Adınızı ve soyadınızı girin"
            icon="person-outline"
            error={errors.name}
          />
          <View style={{ height: 18 }} />

          {/* E-posta alanı yalnızca misafirlere gösterilir */}
          {isGuest && (
            <>
              <Label text="E-posta Adresi" />
              <Field
                value={email}
                onChangeText={setEmail}
                placeholder="E-posta adresiniz"
                icon="mail-outline"
                keyboardType="email-address"
              />
              <View style={{ height: 18 }} />
            </>
          )}

          <Label text="Telefon Numarası" />
          <Field
            value={phone}
            onChangeText={setPhone}
            placeholder="Telefon numaranız"
            icon="phone"
            keyboardType="phone-pad"
          />
          <Text style={[typography.bodySmall, { marginTop: 4, fontSize: 12, color: '#757575' }]}>
            Size ulaşabilmemiz için e-posta veya telefon numaranızdan en az birini doldurmalısınız.
          </Text>
          <View style={{ height: 18 }} />

          <Label text="Kategori" />
          <Dropdown
            value={category}
            options={CATEGORIES}
            onChange={(value) => {
              haptics.selection();
              setCategory(value);
            }}
          />
          <View style={{ height: 18 }} />

          <Label text="Mesajınız" />
          <Field
            value={message}
            onChangeText={setMessage}
            placeholder="Düşüncelerinizi veya sorununuzu buraya yazın..."
            error={errors.message}
            multiline
          />
          <View style={{ height: 24 }} />

          <Pressable
            disabled={sending}
            onPress={() => {
              haptics.selection();
              submit();
            }}
            style={[styles.submit, sending && { backgroundColor: 'rgba(29, 27, 32, 0.12)' }]}>
            {sending ? (
              <ActivityIndicator size={24} color={colors.white} />
            ) : (
              <Text style={typography.button}>Gönder</Text>
            )}
          </Pressable>
        </ScrollView>
      </KeyboardAvoidingView>
    </View>
  );
}

function Label({ text }: { text: string }) {
  return <Text style={[typography.bodyMedium, { marginBottom: 8, fontFamily: fonts.semiBold }]}>{text}</Text>;
}

function Field({
  value,
  onChangeText,
  placeholder,
  icon,
  error = null,
  keyboardType,
  multiline = false,
}: {
  value: string;
  onChangeText: (value: string) => void;
  placeholder: string;
  icon?: IconName;
  error?: string | null;
  keyboardType?: KeyboardTypeOptions;
  multiline?: boolean;
}) {
  const [focused, setFocused] = useState(false);
  const borderColor = error ? colors.error : focused ? colors.primary : colors.border;
  return (
    <View>
      <View style={[styles.field, { borderColor, borderWidth: focused ? 2 : 1 }]}>
        {icon && <MaterialIcons name={icon} size={20} color="#49454F" style={styles.fieldIcon} />}
        <TextInput
          value={value}
          onChangeText={onChangeText}
          placeholder={placeholder}
          placeholderTextColor={colors.textSecondary}
          keyboardType={keyboardType}
          autoCapitalize={keyboardType === 'email-address' ? 'none' : 'sentences'}
          multiline={multiline}
          numberOfLines={multiline ? 6 : 1}
          textAlignVertical={multiline ? 'top' : 'center'}
          onFocus={() => setFocused(true)}
          onBlur={() => setFocused(false)}
          style={[styles.input, !icon && { paddingLeft: 16 }, multiline && { height: 6 * 22 + 28 }]}
        />
      </View>
      {error && <Text style={styles.errorText}>{error}</Text>}
    </View>
  );
}

/** Flutter DropdownButtonFormField: alanın üstünde açılan seçenek menüsü. */
function Dropdown({ value, options, onChange }: { value: string; options: string[]; onChange: (value: string) => void }) {
  const ref = useRef<ComponentRef<typeof View>>(null);
  const [menu, setMenu] = useState<{ x: number; y: number; width: number } | null>(null);
  const ITEM_HEIGHT = 48;

  return (
    <>
      <Pressable
        ref={ref}
        onPress={() =>
          ref.current?.measureInWindow((x, y, width) => {
            // Seçili öğe alanın hizasında açılır.
            const selectedIndex = options.indexOf(value);
            setMenu({ x, y: Math.max(24, y - selectedIndex * ITEM_HEIGHT), width });
          })
        }
        style={[styles.field, { borderColor: colors.border, borderWidth: 1 }]}>
        <MaterialIcons name="category" size={20} color="#49454F" style={styles.fieldIcon} />
        <Text style={[typography.bodyLarge, styles.dropdownText]} numberOfLines={1}>
          {value}
        </Text>
        <MaterialIcons name="arrow-drop-down" size={24} color="#49454F" style={{ marginRight: 12 }} />
      </Pressable>
      <Modal visible={menu != null} transparent animationType="fade" onRequestClose={() => setMenu(null)}>
        <Pressable style={StyleSheet.absoluteFill} onPress={() => setMenu(null)} />
        {menu && (
          <View style={[styles.menu, { left: menu.x, top: menu.y, width: menu.width }]}>
            {options.map((option) => (
              <Pressable
                key={option}
                onPress={() => {
                  setMenu(null);
                  onChange(option);
                }}
                style={({ pressed }) => [
                  styles.menuItem,
                  { height: ITEM_HEIGHT },
                  (pressed || option === value) && { backgroundColor: 'rgba(0, 0, 0, 0.06)' },
                ]}>
                <Text style={typography.bodyLarge} numberOfLines={1}>
                  {option}
                </Text>
              </Pressable>
            ))}
          </View>
        )}
      </Modal>
    </>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.background,
  },
  content: {
    padding: 20,
  },
  field: {
    minHeight: 48,
    flexDirection: 'row',
    alignItems: 'center',
    borderRadius: 12,
    backgroundColor: colors.white,
  },
  fieldIcon: {
    marginLeft: 14,
    marginRight: 2,
  },
  input: {
    flex: 1,
    minHeight: 48,
    paddingHorizontal: 12,
    paddingVertical: 14,
    fontFamily: fonts.regular,
    fontSize: 16,
    color: colors.textPrimary,
  },
  dropdownText: {
    flex: 1,
    paddingHorizontal: 12,
    paddingVertical: 14,
  },
  errorText: {
    marginTop: 4,
    marginLeft: 12,
    fontFamily: fonts.regular,
    fontSize: 12,
    color: colors.error,
  },
  menu: {
    position: 'absolute',
    paddingVertical: 8,
    borderRadius: 4,
    backgroundColor: colors.white,
    shadowColor: '#000000',
    shadowOpacity: 0.2,
    shadowRadius: 8,
    shadowOffset: { width: 0, height: 4 },
    elevation: 8,
  },
  menuItem: {
    paddingHorizontal: 16,
    justifyContent: 'center',
  },
  submit: {
    height: 54,
    alignItems: 'center',
    justifyContent: 'center',
    borderRadius: 12,
    backgroundColor: colors.primary,
  },
});
