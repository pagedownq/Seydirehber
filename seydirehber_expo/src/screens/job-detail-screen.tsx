import { MaterialCommunityIcons, MaterialIcons } from '@expo/vector-icons';
import { type Href, router } from 'expo-router';
import type { ComponentProps } from 'react';
import { Linking, Pressable, ScrollView, StyleSheet, Text, View } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';

import { AppBar } from '@/components/app-bar';
import { EmptyState } from '@/components/empty-state';
import { MapButton } from '@/components/map-button';
import { ShareButton } from '@/components/share-button';
import { DetailShimmer } from '@/components/shimmer';
import { useDocument } from '@/features/firestore/use-document';
import {
  createdAt,
  daysLeft,
  isJobVisible,
  JOBS_COLLECTION,
  jobFields,
  timeAgo,
  whatsappNumber,
} from '@/features/jobs/jobs';
import { haptics } from '@/services/haptics';
import { colors, fonts, typography } from '@/theme';

// İş ilanı detayı (Expo'ya özgü, Flutter'da yok). Başvuru telefon ya da WhatsApp ile.
type IconName = ComponentProps<typeof MaterialIcons>['name'];

async function openUrl(url: string) {
  try {
    if (await Linking.canOpenURL(url)) await Linking.openURL(url);
  } catch {}
}

export function JobDetailScreen({ jobId }: { jobId: string }) {
  const insets = useSafeAreaInsets();
  const document = useDocument(JOBS_COLLECTION, jobId);

  if (document.status === 'loading') {
    return (
      <View style={styles.container}>
        <AppBar title="İş İlanı" />
        <DetailShimmer />
      </View>
    );
  }

  if (document.status !== 'ready' || !isJobVisible(document.data)) {
    return (
      <View style={styles.container}>
        <AppBar title="İş İlanı" />
        <EmptyState icon="work-off" title="İlan bulunamadı" subtitle="Bu ilan yayından kaldırılmış ya da süresi dolmuş olabilir." />
      </View>
    );
  }

  const { data } = document;
  const fields = jobFields(data);
  const remaining = daysLeft(data);
  const shareText = [fields.title, fields.employer, fields.phone ? `İletişim: ${fields.phone}` : '']
    .filter(Boolean)
    .join('\n');

  return (
    <View style={styles.container}>
      <AppBar title="İş İlanı" actions={<ShareButton content={shareText} subject={fields.title} />} />
      <ScrollView contentContainerStyle={{ padding: 16, paddingBottom: 24 }}>
        {/* Başlık */}
        <View style={styles.headerCard}>
          <View style={styles.headerIcon}>
            <MaterialIcons name="work" size={28} color={colors.white} />
          </View>
          <Text style={styles.title}>{fields.title}</Text>
          {fields.employer ? (
            fields.companyId ? (
              <Pressable
                onPress={() => {
                  haptics.selection();
                  router.push(`/companies/${fields.companyId}` as Href);
                }}
                style={styles.employerLink}>
                <Text style={[styles.employer, { color: colors.primary }]}>{fields.employer}</Text>
                <MaterialIcons name="chevron-right" size={18} color={colors.primary} />
              </Pressable>
            ) : (
              <Text style={styles.employer}>{fields.employer}</Text>
            )
          ) : null}
          <View style={styles.metaRow}>
            <Text style={styles.metaText}>{timeAgo(createdAt(data))}</Text>
            <View style={styles.metaDot} />
            <Text style={styles.metaText}>{remaining <= 1 ? 'Son gün' : `${remaining} gün daha yayında`}</Text>
          </View>
        </View>

        {/* Özet bilgiler */}
        {(fields.workType || fields.hours || fields.salary || fields.address) && (
          <View style={styles.section}>
            {fields.workType ? <InfoRow icon="badge" label="Çalışma şekli" value={fields.workType} /> : null}
            {fields.hours ? <InfoRow icon="schedule" label="Çalışma saatleri" value={fields.hours} /> : null}
            {fields.salary ? <InfoRow icon="payments" label="Ücret" value={fields.salary} /> : null}
            {fields.address ? <InfoRow icon="location-on" label="Adres" value={fields.address} /> : null}
          </View>
        )}

        {fields.description ? (
          <View style={styles.section}>
            <Text style={styles.sectionTitle}>İş Tanımı</Text>
            <Text style={styles.description}>{fields.description}</Text>
          </View>
        ) : null}

        {fields.location ? (
          <View style={{ marginTop: 16 }}>
            <MapButton locationUrl={fields.location} label="Yol Tarifi Al" />
          </View>
        ) : null}

        <View style={styles.notice}>
          <MaterialIcons name="info-outline" size={16} color={colors.textSecondary} />
          <Text style={styles.noticeText}>
            Başvurunuzu doğrudan işverene iletiyorsunuz. Seydi Rehber, ilanlardaki bilgilerin doğruluğundan sorumlu
            değildir; ücret veya belge talep eden ilanlara karşı dikkatli olun.
          </Text>
        </View>
      </ScrollView>

      {/* Başvuru butonları */}
      {fields.phone ? (
        <View style={[styles.actions, { paddingBottom: 12 + insets.bottom }]}>
          <Pressable
            onPress={() => {
              haptics.vibrate();
              openUrl(`tel:${fields.phone.replace(/\s/g, '')}`);
            }}
            style={({ pressed }) => [styles.actionButton, styles.callButton, pressed && { opacity: 0.85 }]}>
            <MaterialIcons name="phone" size={20} color={colors.white} />
            <Text style={styles.actionText}>Ara</Text>
          </Pressable>
          {fields.hasWhatsapp && (
            <Pressable
              onPress={() => {
                haptics.vibrate();
                const message = `Merhaba, Seydi Rehber'deki "${fields.title}" ilanı için yazıyorum.`;
                openUrl(`https://wa.me/${whatsappNumber(fields.phone)}?text=${encodeURIComponent(message)}`);
              }}
              style={({ pressed }) => [styles.actionButton, styles.whatsappButton, pressed && { opacity: 0.85 }]}>
              <MaterialCommunityIcons name="whatsapp" size={20} color={colors.white} />
              <Text style={styles.actionText}>WhatsApp</Text>
            </Pressable>
          )}
        </View>
      ) : null}
    </View>
  );
}

function InfoRow({ icon, label, value }: { icon: IconName; label: string; value: string }) {
  return (
    <View style={styles.infoRow}>
      <View style={styles.infoIcon}>
        <MaterialIcons name={icon} size={18} color={colors.primary} />
      </View>
      <View style={{ flex: 1 }}>
        <Text style={styles.infoLabel}>{label}</Text>
        <Text style={styles.infoValue}>{value}</Text>
      </View>
    </View>
  );
}

const WHATSAPP_GREEN = '#25D366';

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.background,
  },
  headerCard: {
    alignItems: 'center',
    padding: 20,
    borderRadius: 20,
    backgroundColor: colors.white,
    shadowColor: '#000000',
    shadowOpacity: 0.05,
    shadowRadius: 10,
    shadowOffset: { width: 0, height: 3 },
    elevation: 2,
  },
  headerIcon: {
    width: 56,
    height: 56,
    alignItems: 'center',
    justifyContent: 'center',
    borderRadius: 16,
    backgroundColor: '#6D4C41',
  },
  title: {
    marginTop: 14,
    textAlign: 'center',
    fontFamily: fonts.bold,
    fontSize: 20,
    lineHeight: 26,
    color: colors.textPrimary,
  },
  employerLink: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  employer: {
    marginTop: 4,
    textAlign: 'center',
    fontFamily: fonts.semiBold,
    fontSize: 14,
    color: colors.textSecondary,
  },
  metaRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    marginTop: 10,
  },
  metaText: {
    ...typography.caption,
    fontSize: 12,
  },
  metaDot: {
    width: 3,
    height: 3,
    borderRadius: 2,
    backgroundColor: colors.textLight,
  },
  section: {
    marginTop: 16,
    padding: 16,
    borderRadius: 16,
    backgroundColor: colors.white,
    gap: 14,
  },
  sectionTitle: {
    fontFamily: fonts.bold,
    fontSize: 15,
    color: colors.textPrimary,
  },
  description: {
    ...typography.bodyMedium,
    lineHeight: 22,
    color: colors.textPrimary,
  },
  infoRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
  },
  infoIcon: {
    width: 36,
    height: 36,
    alignItems: 'center',
    justifyContent: 'center',
    borderRadius: 10,
    backgroundColor: colors.primarySurface,
  },
  infoLabel: {
    ...typography.caption,
  },
  infoValue: {
    fontFamily: fonts.semiBold,
    fontSize: 14,
    color: colors.textPrimary,
  },
  notice: {
    flexDirection: 'row',
    gap: 8,
    marginTop: 16,
    padding: 12,
    borderRadius: 12,
    backgroundColor: 'rgba(158, 158, 158, 0.08)',
  },
  noticeText: {
    ...typography.bodySmall,
    flex: 1,
    lineHeight: 17,
  },
  actions: {
    flexDirection: 'row',
    gap: 12,
    paddingHorizontal: 16,
    paddingTop: 12,
    backgroundColor: colors.white,
    borderTopWidth: 1,
    borderTopColor: colors.divider,
  },
  actionButton: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 8,
    paddingVertical: 14,
    borderRadius: 12,
  },
  callButton: {
    backgroundColor: colors.primary,
  },
  whatsappButton: {
    backgroundColor: WHATSAPP_GREEN,
  },
  actionText: {
    ...typography.button,
    fontSize: 15,
  },
});
