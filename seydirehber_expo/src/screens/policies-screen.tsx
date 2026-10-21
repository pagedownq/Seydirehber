import { MaterialCommunityIcons, MaterialIcons } from '@expo/vector-icons';
import { type ReactNode, useState } from 'react';
import { Pressable, ScrollView, StyleSheet, Text, View } from 'react-native';

import { AppBar } from '@/components/app-bar';
import { PolicySheet } from '@/components/policy-sheet';
import { KVKK_CONTENT, PRIVACY_POLICY_CONTENT, TERMS_OF_SERVICE_CONTENT } from '@/features/policies/content';
import { colors, fonts, typography } from '@/theme';

// Flutter lib/features/settings/screens/policies_screen.dart karşılığı.
export function PoliciesScreen() {
  const [policy, setPolicy] = useState<{ title: string; content: string } | null>(null);

  const items: { icon: ReactNode; title: string; content: string }[] = [
    {
      icon: <MaterialIcons name="privacy-tip" size={24} color={colors.primary} />,
      title: 'Gizlilik Politikası',
      content: PRIVACY_POLICY_CONTENT,
    },
    {
      icon: <MaterialCommunityIcons name="clipboard-text-outline" size={24} color={colors.primary} />,
      title: 'Kullanım Koşulları',
      content: TERMS_OF_SERVICE_CONTENT,
    },
    {
      icon: <MaterialIcons name="gavel" size={24} color={colors.primary} />,
      title: 'KVKK Aydınlatma Metni',
      content: KVKK_CONTENT,
    },
  ];

  return (
    <View style={styles.container}>
      <AppBar title="Politikalar" />
      <ScrollView contentContainerStyle={{ padding: 16 }}>
        {items.map((item, index) => (
          <Pressable
            key={item.title}
            onPress={() => setPolicy({ title: item.title, content: item.content })}
            style={({ pressed }) => [styles.item, index > 0 && { marginTop: 12 }, pressed && { backgroundColor: '#F5F5F5' }]}>
            <View style={styles.icon}>{item.icon}</View>
            <Text style={[typography.bodyMedium, styles.title]}>{item.title}</Text>
            <MaterialIcons name="arrow-forward-ios" size={16} color={colors.textLight} />
          </Pressable>
        ))}
      </ScrollView>
      <PolicySheet policy={policy} onClose={() => setPolicy(null)} />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.background,
  },
  item: {
    minHeight: 56,
    paddingLeft: 16,
    paddingRight: 24,
    paddingVertical: 8,
    flexDirection: 'row',
    alignItems: 'center',
    borderRadius: 16,
    backgroundColor: colors.white,
  },
  icon: {
    padding: 8,
    borderRadius: 10,
    backgroundColor: colors.primarySurface,
  },
  title: {
    flex: 1,
    marginHorizontal: 16,
    fontFamily: fonts.bold,
  },
});
