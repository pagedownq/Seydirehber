import { MaterialIcons } from '@expo/vector-icons';
import { type Href, router } from 'expo-router';
import type { ComponentProps } from 'react';
import { ActivityIndicator, Pressable, ScrollView, StyleSheet, Text, View } from 'react-native';

import { AppBar } from '@/components/app-bar';
import { showSnackbar } from '@/components/snackbar';
import { purgeInactiveTokens, syncAllReviewStats, useAppStats } from '@/features/admin/admin-service';
import { type AdminPermission, useAdminPermissions } from '@/features/auth/admin-permissions';
import { colors, fonts, typography } from '@/theme';
import { alertConfirm } from '@/utils/alert-confirm';

// Flutter lib/features/admin/screens/admin_screen.dart karşılığı.
type IconName = ComponentProps<typeof MaterialIcons>['name'];

type AdminEntry = {
  permission: AdminPermission;
  icon: IconName;
  title: string;
  color: string;
  href: Href;
};

const manage = (collection: string, title: string, bucket: string | null): Href =>
  ({ pathname: '/admin/manage', params: { collection, title, bucket: bucket ?? '' } }) as unknown as Href;

const ENTRIES: AdminEntry[] = [
  { permission: 'canManageBanners', icon: 'photo-library', title: 'Banner Yönetimi', color: '#7B1FA2', href: manage('banners', 'Banner Yönetimi', 'banner') },
  { permission: 'canManageEvents', icon: 'event', title: 'Etkinlik Yönetimi', color: '#E53935', href: manage('etkinlikler', 'Etkinlik Yönetimi', 'etkinlikler') },
  { permission: 'canManageNotaries', icon: 'gavel', title: 'Noter Yönetimi', color: '#5C6BC0', href: manage('noterler', 'Noter Yönetimi', 'noter') },
  { permission: 'canManageMarkets', icon: 'storefront', title: 'Pazar Yönetimi', color: '#FF8F00', href: manage('pazarlar', 'Pazar Yönetimi', 'pazar') },
  { permission: 'canManageBuses', icon: 'directions-bus', title: 'Otobüs Saatleri Yönetimi', color: '#00897B', href: manage('otobus_saatleri', 'Otobüs Saatleri', null) },
  { permission: 'canManagePlaces', icon: 'place', title: 'Gezilecek Yerler Yönetimi', color: '#43A047', href: manage('gezilecek_yerler', 'Gezilecek Yerler', 'gezilcek_yerler') },
  { permission: 'canManageCompanies', icon: 'business', title: 'Firma Yönetimi', color: '#1565C0', href: manage('firmalar', 'Firma Yönetimi', 'firmalar') },
  { permission: 'canManageSupport', icon: 'support-agent', title: 'Yardım & Destek Mesajları', color: '#D32F2F', href: '/admin/support' as Href },
  { permission: 'canManageReviews', icon: 'rate-review', title: 'Yorum Yönetimi', color: '#FBC02D', href: '/admin/reviews' as Href },
  { permission: 'canManageReports', icon: 'report-problem', title: 'Yorum Şikayetleri', color: '#D32F2F', href: '/admin/reports' as Href },
  { permission: 'canManageForum', icon: 'forum', title: 'Forum Moderasyonu', color: '#5C35CC', href: '/admin/forum' as Href },
  { permission: 'canManageNotifications', icon: 'notifications-active', title: 'Bildirim Yönetimi', color: '#0288D1', href: '/admin/notifications' as Href },
  { permission: 'canManageEsnaf', icon: 'people', title: 'Esnaf Hesapları', color: '#7E57C2', href: manage('esnaf_users', 'Esnaf Hesapları', null) },
  { permission: 'canManageCoupons', icon: 'confirmation-number', title: 'Kupon Yönetimi', color: '#EC407A', href: manage('coupons', 'Kupon Yönetimi', null) },
  { permission: 'canManageJobs', icon: 'work', title: 'İş İlanı Yönetimi', color: '#6D4C41', href: manage('is_ilanlari', 'İş İlanı Yönetimi', null) },
  { permission: 'canManageSurveys', icon: 'assignment', title: 'Anket Yönetimi', color: '#2E7D32', href: manage('surveys', 'Anket Yönetimi', null) },
  { permission: 'canManageAdmins', icon: 'admin-panel-settings', title: 'Admin Yönetimi', color: '#263238', href: manage('admins', 'Admin Yönetimi', null) },
];

function withOpacity(hex: string, opacity: number) {
  const r = parseInt(hex.slice(1, 3), 16);
  const g = parseInt(hex.slice(3, 5), 16);
  const b = parseInt(hex.slice(5, 7), 16);
  return `rgba(${r}, ${g}, ${b}, ${opacity})`;
}

export function AdminScreen() {
  const permissions = useAdminPermissions();
  const isAdmin = Object.keys(permissions).length > 0;

  if (!isAdmin) {
    return (
      <View style={[styles.container, styles.center, { backgroundColor: colors.white }]}>
        <Text style={typography.bodyMedium}>Yetkiniz yok</Text>
      </View>
    );
  }

  return (
    <View style={styles.container}>
      <AppBar title="Yönetim Paneli" />
      <ScrollView contentContainerStyle={{ padding: 16 }}>
        <StatsCard />
        {ENTRIES.filter((entry) => permissions[entry.permission]).map((entry) => (
          <AdminCard
            key={entry.title}
            icon={entry.icon}
            title={entry.title}
            color={entry.color}
            onPress={() => router.push(entry.href)}
          />
        ))}
        {permissions.canManageAdmins && (
          <AdminCard
            icon="sync"
            title="Yorum İstatistiklerini Eşitle"
            color="#455A64"
            onPress={async () => {
              const confirmed = await alertConfirm({
                title: 'İstatistikleri Eşitle',
                content:
                  'Tüm firma ve yerlerin yorum sayılarını ve puanlarını yeniden hesaplamak istediğinize emin misiniz? Bu işlem biraz zaman alabilir.',
                cancelText: 'İptal',
                confirmText: 'Evet, Başlat',
              });
              if (!confirmed) return;
              showSnackbar({ message: 'Eşitleme işlemi başlatıldı...' });
              try {
                await syncAllReviewStats();
                showSnackbar({ message: 'Eşitleme başarıyla tamamlandı!' });
              } catch (error) {
                showSnackbar({ message: `Hata oluştu: ${String(error)}` });
              }
            }}
          />
        )}
      </ScrollView>
    </View>
  );
}

function StatsCard() {
  const state = useAppStats();

  if (state.status === 'loading') {
    return (
      <View style={{ padding: 20, alignItems: 'center' }}>
        <ActivityIndicator size="large" color={colors.primary} />
      </View>
    );
  }
  if (state.status === 'error') {
    return (
      <View style={{ padding: 16, alignItems: 'center' }}>
        <Text style={{ fontFamily: fonts.regular, fontSize: 12, color: '#F44336' }}>
          {`İstatistik hatası: ${String(state.error)}`}
        </Text>
      </View>
    );
  }

  const { stats } = state;
  return (
    <View style={styles.statsCard}>
      <View style={styles.row}>
        <MaterialIcons name="analytics" size={20} color={colors.primary} />
        <Text style={[typography.heading3, { marginLeft: 8, fontSize: 16, flex: 1 }]}>Canlı İstatistikler</Text>
        <View style={styles.activeBadge}>
          <View style={styles.activeDot} />
          <Text style={styles.activeText}>{`${stats.activeNow} Aktif`}</Text>
        </View>
        <Pressable
          accessibilityLabel="Gereksiz Cihazları Temizle"
          hitSlop={8}
          style={{ marginLeft: 8, padding: 8 }}
          onPress={async () => {
            const confirmed = await alertConfirm({
              title: 'Veritabanı Temizliği',
              content:
                'Son 30 gündür uygulamayı hiç açmamış olan cihaz kayıtlarını silmek istediğinize emin misiniz? (Bu işlem sadece çöp verileri temizler)',
              confirmText: 'Temizle',
            });
            if (!confirmed) return;
            try {
              const count = await purgeInactiveTokens();
              showSnackbar({ message: `${count} adet geçersiz cihaz kaydı temizlendi.` });
            } catch (error) {
              showSnackbar({ message: `Hata: ${String(error)}` });
            }
          }}>
          <MaterialIcons name="cleaning-services" size={20} color="#9E9E9E" />
        </Pressable>
      </View>
      <View style={[styles.row, { marginTop: 16 }]}>
        <StatItem label="Toplam Cihaz" value={stats.totalCount} icon="devices" color={colors.primary} />
        <StatItem label="Bugün Aktif" value={stats.activeToday} icon="bolt" color="#FF9800" />
      </View>
      <View style={[styles.row, { marginTop: 12 }]}>
        <StatItem label="Misafir" value={stats.guestCount} icon="person-outline" color="#9E9E9E" />
        <StatItem label="Üye" value={stats.registeredCount} icon="person" color="#2196F3" />
      </View>
    </View>
  );
}

function StatItem({ label, value, icon, color }: { label: string; value: number; icon: IconName; color: string }) {
  return (
    <View style={{ flex: 1 }}>
      <View style={styles.row}>
        <MaterialIcons name={icon} size={16} color={withOpacity(color, 0.7)} />
        <Text style={[typography.caption, { marginLeft: 6 }]}>{label}</Text>
      </View>
      <Text style={[typography.heading2, { marginTop: 4, fontSize: 24, color }]}>{String(value)}</Text>
    </View>
  );
}

function AdminCard({
  icon,
  title,
  color,
  onPress,
}: {
  icon: IconName;
  title: string;
  color: string;
  onPress: () => void;
}) {
  return (
    <Pressable onPress={onPress} style={({ pressed }) => [styles.card, pressed && { backgroundColor: '#F5F5F5' }]}>
      <View style={[styles.cardIcon, { backgroundColor: withOpacity(color, 0.1) }]}>
        <MaterialIcons name={icon} size={24} color={color} />
      </View>
      <Text style={[typography.bodyMedium, { flex: 1, marginLeft: 14, fontFamily: fonts.semiBold }]}>{title}</Text>
      <MaterialIcons name="arrow-forward-ios" size={14} color={colors.textLight} />
    </Pressable>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.background,
  },
  center: {
    alignItems: 'center',
    justifyContent: 'center',
  },
  row: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  statsCard: {
    marginBottom: 20,
    padding: 16,
    borderRadius: 20,
    backgroundColor: colors.white,
    shadowColor: '#000000',
    shadowOpacity: 0.05,
    shadowRadius: 10,
    shadowOffset: { width: 0, height: 4 },
    elevation: 2,
  },
  activeBadge: {
    paddingHorizontal: 8,
    paddingVertical: 4,
    flexDirection: 'row',
    alignItems: 'center',
    borderRadius: 10,
    backgroundColor: 'rgba(76, 175, 80, 0.1)',
  },
  activeDot: {
    width: 8,
    height: 8,
    borderRadius: 4,
    backgroundColor: '#4CAF50',
  },
  activeText: {
    marginLeft: 6,
    fontFamily: fonts.bold,
    fontSize: 12,
    color: '#4CAF50',
  },
  card: {
    marginBottom: 12,
    padding: 16,
    flexDirection: 'row',
    alignItems: 'center',
    borderRadius: 16,
    backgroundColor: colors.white,
    shadowColor: '#000000',
    shadowOpacity: 0.12,
    shadowRadius: 2,
    shadowOffset: { width: 0, height: 1 },
    elevation: 1,
  },
  cardIcon: {
    padding: 10,
    borderRadius: 12,
  },
});
