import { MaterialIcons } from '@expo/vector-icons';
import type { ComponentProps } from 'react';
import { useState } from 'react';
import { ActivityIndicator, Pressable, StyleSheet, Text, View } from 'react-native';

import { BottomSheet } from '@/components/bottom-sheet';
import { showSnackbar } from '@/components/snackbar';
import { colors, fonts, typography } from '@/theme';

// Flutter lib/features/forum/widgets/forum_report_sheet.dart karşılığı. Neden seçmek zorunlu;
// Flutter'daki gibi seçilen neden kaydedilmez, sadece rapor sayılır.
const REASONS: { label: string; icon: ComponentProps<typeof MaterialIcons>['name'] }[] = [
  { label: 'Hakaret / Argo / Küfür', icon: 'sentiment-very-dissatisfied' },
  { label: 'Yanlış / Yanıltıcı Bilgi', icon: 'info-outline' },
  { label: 'Reklam / Spam', icon: 'campaign' },
  { label: 'Kişisel Verilerin İfşası', icon: 'person-off' },
];

const capitalize = (text: string) => (text ? text[0].toUpperCase() + text.slice(1) : text);

type ForumReportSheetProps = {
  visible: boolean;
  onClose: () => void;
  /** "gönderi" ya da "yanıt" */
  contentType: string;
  /** Rapor kabul edilirse true, daha önce raporlandıysa false. */
  onReport: () => Promise<boolean>;
};

export function ForumReportSheet(props: ForumReportSheetProps) {
  return (
    <BottomSheet visible={props.visible} onClose={props.onClose}>
      {props.visible && <ReportForm {...props} />}
    </BottomSheet>
  );
}

function ReportForm({ onClose, contentType, onReport }: ForumReportSheetProps) {
  const [selected, setSelected] = useState<number | null>(null);
  const [loading, setLoading] = useState(false);

  const submit = async () => {
    if (selected == null) return;
    setLoading(true);
    try {
      const success = await onReport();
      onClose();
      showSnackbar({
        message: success ? `${capitalize(contentType)} bildirildi. Teşekkürler!` : 'Bu içeriği zaten bildirdiniz.',
        borderRadius: 12,
      });
    } finally {
      setLoading(false);
    }
  };

  const enabled = selected != null && !loading;

  return (
    <View style={styles.sheet}>
      <View style={styles.handle} />
      <Text style={[typography.heading3, { marginTop: 20 }]}>{capitalize(contentType)} Bildir</Text>
      <Text style={[typography.bodySmall, { marginTop: 6 }]}>Neden bildirmek istiyorsunuz?</Text>
      <View style={{ height: 16 }} />
      {REASONS.map((reason, index) => {
        const isSelected = selected === index;
        return (
          <Pressable
            key={reason.label}
            onPress={() => setSelected(index)}
            style={[
              styles.reason,
              {
                backgroundColor: isSelected ? '#FFF3F3' : '#FAFAFA',
                borderColor: isSelected ? colors.error : colors.border,
                borderWidth: isSelected ? 1.5 : 1,
              },
            ]}>
            <MaterialIcons name={reason.icon} size={20} color={isSelected ? colors.error : colors.textLight} />
            <Text
              style={[
                typography.bodyMedium,
                { flex: 1, color: isSelected ? colors.error : colors.textPrimary },
                isSelected && { fontFamily: fonts.semiBold },
              ]}>
              {reason.label}
            </Text>
            {isSelected && <MaterialIcons name="check-circle" size={18} color={colors.error} />}
          </Pressable>
        );
      })}
      <Pressable
        disabled={!enabled}
        onPress={submit}
        style={[styles.submit, { backgroundColor: enabled || loading ? colors.error : '#EEEEEE' }]}>
        {loading ? (
          <ActivityIndicator color={colors.white} size="small" />
        ) : (
          <Text style={[typography.button, !enabled && { color: 'rgba(27, 27, 27, 0.38)' }]}>Bildir</Text>
        )}
      </Pressable>
      <View style={{ height: 8 }} />
    </View>
  );
}

const styles = StyleSheet.create({
  sheet: {
    padding: 24,
    borderTopLeftRadius: 28,
    borderTopRightRadius: 28,
    backgroundColor: colors.white,
  },
  handle: {
    alignSelf: 'center',
    width: 40,
    height: 4,
    borderRadius: 2,
    backgroundColor: '#E0E0E0',
  },
  reason: {
    marginBottom: 10,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
    paddingHorizontal: 16,
    paddingVertical: 14,
    borderRadius: 14,
  },
  submit: {
    height: 52,
    marginTop: 10,
    alignItems: 'center',
    justifyContent: 'center',
    borderRadius: 16,
  },
});
