import { MaterialIcons } from '@expo/vector-icons';
import { DateTimePicker } from '@expo/ui/community/datetime-picker';
import { type ComponentProps, useState } from 'react';
import {
  ActivityIndicator,
  Keyboard,
  Modal,
  Platform,
  Pressable,
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  View,
} from 'react-native';

import { BottomSheet } from '@/components/bottom-sheet';
import { showSnackbar } from '@/components/snackbar';
import {
  createReport,
  REPORT_CATEGORIES,
  type ReportCategory,
  type ReportCategoryValue,
} from '@/features/reports/report-service';
import { colors, fonts, typography } from '@/theme';
import { formatLongTr, formatTime } from '@/utils/date';

// Flutter lib/features/reports/widgets/add_report_sheet.dart karşılığı ("Anlık Durum Bildir").
const DAY_MS = 24 * 60 * 60 * 1000;

export function AddReportSheet({ visible, onClose }: { visible: boolean; onClose: () => void }) {
  return (
    <BottomSheet visible={visible} onClose={onClose} avoidKeyboard>
      {visible && <AddReportForm onClose={onClose} />}
    </BottomSheet>
  );
}

function AddReportForm({ onClose }: { onClose: () => void }) {
  const [category, setCategory] = useState<ReportCategoryValue>('kaza');
  const [address, setAddress] = useState('');
  const [description, setDescription] = useState('');
  const [dateTime, setDateTime] = useState(() => new Date());
  const [loading, setLoading] = useState(false);
  const [errors, setErrors] = useState<{ address: string | null; description: string | null }>({
    address: null,
    description: null,
  });
  const [picking, setPicking] = useState(false);

  const submit = async () => {
    const nextErrors = {
      address: address ? null : 'Lütfen bir adres girin.',
      description: description ? null : 'Lütfen durum açıklaması girin.',
    };
    setErrors(nextErrors);
    if (nextErrors.address || nextErrors.description) return;

    setLoading(true);
    try {
      await createReport({ category, address: address.trim(), description: description.trim(), dateTime });
      onClose();
      showSnackbar({ message: 'Bildiriminiz başarıyla yayınlandı.', backgroundColor: colors.success });
    } catch (error) {
      showSnackbar({ message: `Hata: ${String(error)}`, backgroundColor: colors.error });
    } finally {
      setLoading(false);
    }
  };

  const categoryRows: ReportCategory[][] = [
    [REPORT_CATEGORIES[0], REPORT_CATEGORIES[1]],
    [REPORT_CATEGORIES[2], REPORT_CATEGORIES[3]],
    [REPORT_CATEGORIES[4]],
  ];

  return (
    <Pressable onPress={Keyboard.dismiss} style={styles.sheet}>
      <ScrollView keyboardShouldPersistTaps="handled" bounces={false}>
        <View style={styles.handle} />
        <Text style={[typography.heading2, { color: colors.primary, textAlign: 'center' }]}>Anlık Durum Bildir</Text>
        <View style={{ height: 16 }} />

        <Text style={typography.bodyLarge}>Kategori Seçin</Text>
        <View style={{ height: 8 }} />
        {categoryRows.map((row, index) => (
          <View key={index} style={[styles.categoryRow, index > 0 && { marginTop: 8 }]}>
            {row.map((cat) => {
              const selected = cat.value === category;
              return (
                <Pressable
                  key={cat.value}
                  onPress={() => setCategory(cat.value)}
                  style={[
                    styles.categoryItem,
                    {
                      backgroundColor: selected ? 'rgba(76, 175, 80, 0.1)' : '#FAFAFA',
                      borderColor: selected ? colors.primary : '#E0E0E0',
                    },
                  ]}>
                  <Text style={{ fontSize: 18 }}>{cat.emoji}</Text>
                  <Text
                    style={[
                      typography.bodyMedium,
                      {
                        marginLeft: 8,
                        fontFamily: selected ? fonts.bold : fonts.regular,
                        color: selected ? colors.primary : colors.textPrimary,
                      },
                    ]}>
                    {cat.label}
                  </Text>
                </Pressable>
              );
            })}
          </View>
        ))}
        <View style={{ height: 16 }} />

        <OutlinedField
          label="Konum / Adres"
          hint="Örn: Seyyid Harun Bulvarı, Belediye Önü"
          icon="location-on"
          value={address}
          onChangeText={setAddress}
          error={errors.address}
        />
        <View style={{ height: 16 }} />
        <OutlinedField
          label="Açıklama"
          hint="Durum hakkında kısa bilgi yazın..."
          icon="info-outline"
          value={description}
          onChangeText={setDescription}
          error={errors.description}
          multiline
        />
        <View style={{ height: 16 }} />

        <Pressable onPress={() => setPicking(true)} style={styles.dateRow}>
          <MaterialIcons name="access-time" size={24} color={colors.primary} />
          <View style={{ flex: 1, marginLeft: 12 }}>
            <Text style={[typography.caption, { color: '#757575' }]}>Olay Tarihi & Saati</Text>
            <Text style={[typography.bodyLarge, { fontFamily: fonts.bold }]}>
              {`${formatLongTr(dateTime)}, ${formatTime(dateTime)}`}
            </Text>
          </View>
          <MaterialIcons name="edit-calendar" size={24} color={colors.primary} />
        </Pressable>
        <View style={{ height: 24 }} />

        <Pressable
          disabled={loading}
          onPress={submit}
          style={[styles.submit, loading && { backgroundColor: 'rgba(29, 27, 32, 0.12)' }]}>
          {loading ? (
            <ActivityIndicator size={20} color={colors.white} />
          ) : (
            <Text style={[typography.button, { color: colors.white }]}>Yayınla</Text>
          )}
        </Pressable>
      </ScrollView>

      {picking && (
        <DateTimeFlow
          initial={dateTime}
          onDone={(value) => {
            setPicking(false);
            if (value) setDateTime(value);
          }}
        />
      )}
    </Pressable>
  );
}

/** Flutter showDatePicker + showTimePicker: önce gün, sonra saat; ikisinden biri iptal edilirse değişmez. */
function DateTimeFlow({ initial, onDone }: { initial: Date; onDone: (value: Date | null) => void }) {
  const [step, setStep] = useState<'date' | 'time'>('date');
  const [value, setValue] = useState(initial);
  const [now] = useState(() => Date.now());
  const minimumDate = new Date(now - 7 * DAY_MS);
  const maximumDate = new Date(now + DAY_MS);

  if (Platform.OS === 'android') {
    return (
      <DateTimePicker
        key={step}
        value={value}
        mode={step}
        is24Hour
        accentColor={colors.primary}
        minimumDate={step === 'date' ? minimumDate : undefined}
        maximumDate={step === 'date' ? maximumDate : undefined}
        onValueChange={(_, date) => {
          if (step === 'date') {
            setValue(date);
            setStep('time');
          } else {
            const result = new Date(value);
            result.setHours(date.getHours(), date.getMinutes(), 0, 0);
            onDone(result);
          }
        }}
        onDismiss={() => onDone(null)}
      />
    );
  }

  // iOS: satır içi seçici bir diyalog kartında.
  return (
    <Modal transparent animationType="fade" onRequestClose={() => onDone(null)}>
      <View style={styles.pickerBarrier}>
        <View style={styles.pickerCard}>
          <DateTimePicker
            value={value}
            mode={step}
            display={step === 'date' ? 'inline' : 'spinner'}
            locale="tr_TR"
            accentColor={colors.primary}
            themeVariant="light"
            minimumDate={step === 'date' ? minimumDate : undefined}
            maximumDate={step === 'date' ? maximumDate : undefined}
            onValueChange={(_, date) => {
              if (step === 'date') setValue(date);
              else {
                const result = new Date(value);
                result.setHours(date.getHours(), date.getMinutes(), 0, 0);
                setValue(result);
              }
            }}
          />
          <View style={styles.pickerActions}>
            <Pressable style={styles.pickerButton} onPress={() => onDone(null)}>
              <Text style={styles.pickerButtonText}>İptal</Text>
            </Pressable>
            <Pressable
              style={styles.pickerButton}
              onPress={() => (step === 'date' ? setStep('time') : onDone(value))}>
              <Text style={styles.pickerButtonText}>Tamam</Text>
            </Pressable>
          </View>
        </View>
      </View>
    </Modal>
  );
}

function OutlinedField({
  label,
  hint,
  icon,
  value,
  onChangeText,
  error,
  multiline = false,
}: {
  label: string;
  hint: string;
  icon: ComponentProps<typeof MaterialIcons>['name'];
  value: string;
  onChangeText: (value: string) => void;
  error: string | null;
  multiline?: boolean;
}) {
  const [focused, setFocused] = useState(false);
  const floating = focused || value.length > 0;
  const borderColor = error ? colors.error : focused ? colors.primary : '#79747E';

  return (
    <View>
      <View style={[styles.field, { borderColor, borderWidth: focused ? 2 : 1 }, multiline && { minHeight: 72 }]}>
        <MaterialIcons name={icon} size={24} color={colors.primary} style={styles.fieldIcon} />
        <TextInput
          value={value}
          onChangeText={onChangeText}
          placeholder={focused ? hint : label}
          placeholderTextColor={focused ? colors.textLight : colors.textSecondary}
          multiline={multiline}
          numberOfLines={multiline ? 2 : 1}
          onFocus={() => setFocused(true)}
          onBlur={() => setFocused(false)}
          style={[styles.fieldInput, multiline && { minHeight: 48, textAlignVertical: 'top' }]}
        />
        {floating && (
          <Text style={[styles.floatingLabel, { color: error ? colors.error : focused ? colors.primary : colors.textSecondary }]}>
            {label}
          </Text>
        )}
      </View>
      {error && <Text style={styles.errorText}>{error}</Text>}
    </View>
  );
}

const styles = StyleSheet.create({
  sheet: {
    maxHeight: '90%',
    paddingTop: 16,
    paddingHorizontal: 16,
    paddingBottom: 24,
    borderTopLeftRadius: 20,
    borderTopRightRadius: 20,
    backgroundColor: colors.white,
  },
  handle: {
    alignSelf: 'center',
    width: 40,
    height: 4,
    marginBottom: 16,
    borderRadius: 2,
    backgroundColor: '#E0E0E0',
  },
  categoryRow: {
    flexDirection: 'row',
    gap: 8,
  },
  categoryItem: {
    flex: 1,
    height: 48,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    borderRadius: 12,
    borderWidth: 1.5,
  },
  field: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    borderRadius: 12,
  },
  fieldIcon: {
    marginTop: 16,
    marginHorizontal: 12,
  },
  fieldInput: {
    flex: 1,
    minHeight: 56,
    paddingTop: 16,
    paddingBottom: 16,
    paddingRight: 12,
    fontFamily: fonts.regular,
    fontSize: 16,
    color: colors.textPrimary,
  },
  floatingLabel: {
    position: 'absolute',
    top: -9,
    left: 44,
    paddingHorizontal: 4,
    backgroundColor: colors.white,
    fontFamily: fonts.regular,
    fontSize: 12,
  },
  errorText: {
    marginTop: 4,
    marginLeft: 12,
    fontFamily: fonts.regular,
    fontSize: 12,
    color: colors.error,
  },
  dateRow: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 12,
    paddingVertical: 14,
    borderRadius: 12,
    borderWidth: 1,
    borderColor: '#BDBDBD',
  },
  submit: {
    paddingVertical: 14,
    alignItems: 'center',
    justifyContent: 'center',
    borderRadius: 12,
    backgroundColor: colors.primary,
  },
  pickerBarrier: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    paddingHorizontal: 24,
    backgroundColor: colors.barrier,
  },
  pickerCard: {
    alignSelf: 'stretch',
    padding: 16,
    borderRadius: 28,
    backgroundColor: colors.white,
  },
  pickerActions: {
    marginTop: 8,
    flexDirection: 'row',
    justifyContent: 'flex-end',
  },
  pickerButton: {
    paddingHorizontal: 12,
    paddingVertical: 10,
  },
  pickerButtonText: {
    fontFamily: fonts.semiBold,
    fontSize: 14,
    color: colors.primary,
  },
});
