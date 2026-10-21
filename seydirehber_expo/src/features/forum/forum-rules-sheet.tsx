import { MaterialIcons } from '@expo/vector-icons';
import { type Href, router } from 'expo-router';
import type { ComponentProps } from 'react';
import { useState } from 'react';
import { Pressable, ScrollView, StyleSheet, Text, View } from 'react-native';
import { create } from 'zustand';

import { BottomSheet } from '@/components/bottom-sheet';
import { getItem, setItem, StorageKeys } from '@/services/storage';
import { colors, fonts, typography } from '@/theme';

// Flutter lib/features/forum/widgets/forum_rules_sheet.dart karşılığı: topluluk kuralları bir kez onaylanır.
// <ForumRulesSheetHost /> kök layout'ta durur; foruma `openForum()` ile girilir.
const RULES: [ComponentProps<typeof MaterialIcons>['name'], string][] = [
  ['block', 'Küfür, hakaret ve argo içerikler kesinlikle yasaktır.'],
  ['person-off', 'Başkalarının kişisel bilgilerini (isim, telefon vb.) paylaşmayın.'],
  ['campaign', 'Reklam ve spam içerikler paylaşmayın.'],
  ['fact-check', 'Yanlış veya yanıltıcı bilgi yaymayın.'],
  ['gavel', 'İhlaller; içerik gizleme veya hesap kısıtlamasıyla sonuçlanabilir.'],
];

const useRulesSheetStore = create<{ visible: boolean }>(() => ({ visible: false }));

/** Kurallar kabul edildiyse doğrudan foruma gider, değilse kurallar sayfasını açar. */
export async function openForum() {
  const accepted = (await getItem<boolean>(StorageKeys.forumRulesAccepted)) ?? false;
  if (accepted) router.push('/forum' as Href);
  else useRulesSheetStore.setState({ visible: true });
}

export function ForumRulesSheetHost() {
  const visible = useRulesSheetStore((s) => s.visible);
  const close = () => useRulesSheetStore.setState({ visible: false });
  return (
    <BottomSheet visible={visible} onClose={close}>
      {visible && <RulesContent onClose={close} />}
    </BottomSheet>
  );
}

function RulesContent({ onClose }: { onClose: () => void }) {
  const [accepted, setAccepted] = useState(false);

  const accept = async () => {
    await setItem(StorageKeys.forumRulesAccepted, true);
    onClose();
    router.push('/forum' as Href);
  };

  return (
    <View style={styles.sheet}>
      <ScrollView contentContainerStyle={{ padding: 24 }}>
        <View style={styles.handle} />
        <View style={styles.header}>
          <View style={styles.headerIcon}>
            <MaterialIcons name="forum" size={24} color={colors.primary} />
          </View>
          <Text style={[typography.heading3, { flex: 1 }]}>Seydi Rehber Forumu</Text>
        </View>
        <Text style={[typography.bodyMedium, styles.intro]}>
          Foruma hoş geldiniz! Devam etmeden önce lütfen topluluk kurallarımızı okuyun.
        </Text>
        {RULES.map(([icon, text]) => (
          <View key={text} style={styles.rule}>
            <MaterialIcons name={icon} size={18} color={colors.primary} />
            <Text style={styles.ruleText}>{text}</Text>
          </View>
        ))}
        <Pressable
          onPress={() => setAccepted((v) => !v)}
          style={[styles.acceptRow, { backgroundColor: accepted ? colors.primarySurface : '#FAFAFA' }]}>
          <View style={[styles.checkbox, accepted && styles.checkboxChecked]}>
            {accepted && <MaterialIcons name="check" size={14} color={colors.white} />}
          </View>
          <Text style={[typography.bodyMedium, { flex: 1, fontFamily: fonts.semiBold }]}>
            Topluluk kurallarını okudum ve kabul ediyorum.
          </Text>
        </Pressable>
        <Pressable
          disabled={!accepted}
          onPress={accept}
          style={[styles.button, { backgroundColor: accepted ? colors.primary : '#EEEEEE' }]}>
          <Text style={[typography.button, !accepted && { color: 'rgba(27, 27, 27, 0.38)' }]}>Foruma Giriş Yap</Text>
        </Pressable>
        <View style={{ height: 8 }} />
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  sheet: {
    maxHeight: '90%',
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
  header: {
    marginTop: 20,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 14,
  },
  headerIcon: {
    padding: 10,
    borderRadius: 12,
    backgroundColor: colors.primarySurface,
  },
  intro: {
    marginTop: 20,
    marginBottom: 20,
    color: colors.textSecondary,
  },
  rule: {
    marginBottom: 12,
    flexDirection: 'row',
    alignItems: 'flex-start',
    gap: 10,
  },
  ruleText: {
    ...typography.bodySmall,
    flex: 1,
    lineHeight: 16.8,
    color: colors.textSecondary,
  },
  acceptRow: {
    marginTop: 8,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 16,
    paddingHorizontal: 14,
    paddingVertical: 16,
    borderRadius: 14,
  },
  checkbox: {
    width: 18,
    height: 18,
    marginLeft: 6,
    alignItems: 'center',
    justifyContent: 'center',
    borderRadius: 5,
    borderWidth: 2,
    borderColor: colors.textSecondary,
  },
  checkboxChecked: {
    borderColor: colors.primary,
    backgroundColor: colors.primary,
  },
  button: {
    height: 52,
    marginTop: 16,
    alignItems: 'center',
    justifyContent: 'center',
    borderRadius: 16,
  },
});
