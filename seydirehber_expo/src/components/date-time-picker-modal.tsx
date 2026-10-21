import { DateTimePicker } from '@expo/ui/community/datetime-picker';
import { useState } from 'react';
import { Modal, Platform, Pressable, StyleSheet, Text, View } from 'react-native';

import { colors, fonts } from '@/theme';

// Flutter showDatePicker / showTimePicker karşılığı. Android'de sistem diyaloğu, iOS'ta satır içi seçici
// bir diyalog kartında. Seçimde onDone(tarih), vazgeçince onDone(null).
type DateTimePickerModalProps = {
  mode: 'date' | 'time';
  initial: Date;
  minimumDate?: Date;
  maximumDate?: Date;
  onDone: (value: Date | null) => void;
};

export function DateTimePickerModal({ mode, initial, minimumDate, maximumDate, onDone }: DateTimePickerModalProps) {
  const [value, setValue] = useState(initial);

  if (Platform.OS === 'android') {
    return (
      <DateTimePicker
        value={value}
        mode={mode}
        is24Hour
        accentColor={colors.primary}
        minimumDate={minimumDate}
        maximumDate={maximumDate}
        onValueChange={(_, date) => onDone(date)}
        onDismiss={() => onDone(null)}
      />
    );
  }

  return (
    <Modal transparent animationType="fade" onRequestClose={() => onDone(null)}>
      <View style={styles.barrier}>
        <View style={styles.card}>
          <DateTimePicker
            value={value}
            mode={mode}
            display={mode === 'date' ? 'inline' : 'spinner'}
            locale="tr_TR"
            accentColor={colors.primary}
            themeVariant="light"
            minimumDate={minimumDate}
            maximumDate={maximumDate}
            onValueChange={(_, date) => setValue(date)}
          />
          <View style={styles.actions}>
            <Pressable style={styles.button} onPress={() => onDone(null)}>
              <Text style={styles.buttonText}>İptal</Text>
            </Pressable>
            <Pressable style={styles.button} onPress={() => onDone(value)}>
              <Text style={styles.buttonText}>Tamam</Text>
            </Pressable>
          </View>
        </View>
      </View>
    </Modal>
  );
}

const styles = StyleSheet.create({
  barrier: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    paddingHorizontal: 24,
    backgroundColor: colors.barrier,
  },
  card: {
    alignSelf: 'stretch',
    padding: 16,
    borderRadius: 28,
    backgroundColor: colors.white,
  },
  actions: {
    marginTop: 8,
    flexDirection: 'row',
    justifyContent: 'flex-end',
  },
  button: {
    paddingHorizontal: 12,
    paddingVertical: 10,
  },
  buttonText: {
    fontFamily: fonts.semiBold,
    fontSize: 14,
    color: colors.primary,
  },
});
