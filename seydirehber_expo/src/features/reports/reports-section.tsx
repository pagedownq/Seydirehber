import { MaterialIcons } from '@expo/vector-icons';
import { useState } from 'react';
import { ActivityIndicator, FlatList, Pressable, StyleSheet, Text, View } from 'react-native';

import { showConfirmDialog } from '@/components/confirm-dialog';
import { showSnackbar } from '@/components/snackbar';
import { useIsAdmin } from '@/features/auth/admin-permissions';
import { useIsGuest, useUser } from '@/features/auth/auth-store';
import { AddReportSheet } from '@/features/reports/add-report-sheet';
import {
  deleteReport,
  reportCategory,
  toggleConfirmReport,
  toggleUnconfirmReport,
  type TrafficReport,
  toTrafficReport,
  useActiveReports,
} from '@/features/reports/report-service';
import { haptics } from '@/services/haptics';
import { colors, fonts, typography } from '@/theme';
import { formatTime } from '@/utils/date';

// Flutter home_screen.dart'taki "Anlık Durum Bildirimleri" bölümü karşılığı.
// NOT: Flutter'da bu bölüm yorum satırına alınmış durumda (canlıda görünmüyor); bu yüzden Ana Sayfa'ya
// eklenmedi. Açılmak istenirse HomeScreen'de BannerSlider'dan hemen sonra <ReportsSection /> eklenir.
export function ReportsSection() {
  const reports = useActiveReports();
  const user = useUser();
  const isGuest = useIsGuest();
  const isAdmin = useIsAdmin();
  const [sheetVisible, setSheetVisible] = useState(false);

  let body;
  if (reports.status === 'loading') {
    body = (
      <View style={[styles.center, { height: 130 }]}>
        <ActivityIndicator size="large" color={colors.primary} />
      </View>
    );
  } else if (reports.status === 'error') {
    body = (
      <View style={[styles.center, { height: 60 }]}>
        <Text style={typography.bodyMedium}>Bildirimler yüklenemedi.</Text>
      </View>
    );
  } else if (reports.docs.length === 0) {
    body = (
      <View style={styles.emptyCard}>
        <Text style={{ fontSize: 24 }}>🌟</Text>
        <View style={{ flex: 1, marginLeft: 12 }}>
          <Text style={[typography.bodyMedium, { fontFamily: fonts.bold }]}>Yollar Temiz!</Text>
          <Text style={[typography.bodySmall, { color: colors.textLight }]}>
            Şu an aktif bildirilen bir yol çalışması veya kaza bulunmuyor.
          </Text>
        </View>
      </View>
    );
  } else {
    body = (
      <FlatList
        horizontal
        data={reports.docs.map(toTrafficReport)}
        keyExtractor={(report) => report.id}
        showsHorizontalScrollIndicator={false}
        style={{ height: 180 }}
        contentContainerStyle={{ paddingHorizontal: 16 }}
        renderItem={({ item }) => (
          <ReportCard report={item} uid={user?.uid ?? null} canDelete={user != null && (item.userId === user.uid || isAdmin)} />
        )}
      />
    );
  }

  return (
    <View>
      <View style={{ height: 24 }} />
      <View style={styles.header}>
        <Text style={[typography.heading3, { fontFamily: fonts.bold }]}>Anlık Durum Bildirimleri</Text>
        <Pressable
          onPress={() => {
            if (isGuest) {
              showSnackbar({ message: 'Bildirimde bulunmak için lütfen giriş yapın.', backgroundColor: colors.error });
              return;
            }
            setSheetVisible(true);
          }}
          style={styles.addButton}>
          <MaterialIcons name="add-alert" size={16} color={colors.white} />
          <Text style={[typography.button, { marginLeft: 8, fontSize: 13 }]}>Durum Bildir</Text>
        </Pressable>
      </View>
      <View style={{ height: 12 }} />
      {body}
      <AddReportSheet visible={sheetVisible} onClose={() => setSheetVisible(false)} />
    </View>
  );
}

function ReportCard({ report, uid, canDelete }: { report: TrafficReport; uid: string | null; canDelete: boolean }) {
  const category = reportCategory(report.category);
  const isConfirmed = uid != null && report.confirmedUserIds.includes(uid);
  const isUnconfirmed = uid != null && report.unconfirmedUserIds.includes(uid);

  const onDelete = async () => {
    haptics.selection();
    const confirmed = await showConfirmDialog({
      title: 'Bildirimi Sil',
      content: 'Bu anlık durum bildirimini silmek istediğinize emin misiniz?',
      confirmLabel: 'Sil',
      cancelLabel: 'Vazgeç',
      icon: 'delete-outline',
      iconColor: colors.error,
      isDestructive: true,
    });
    if (!confirmed) return;
    try {
      await deleteReport(report.id);
      showSnackbar({ message: 'Bildirim silindi.', backgroundColor: colors.success });
    } catch (error) {
      showSnackbar({ message: String(error), backgroundColor: colors.error });
    }
  };

  return (
    <View style={styles.card}>
      <View style={styles.cardHeader}>
        <View style={styles.categoryBadge}>
          <Text>{category.emoji}</Text>
          <Text style={[typography.caption, { marginLeft: 4, fontFamily: fonts.bold, color: colors.primary }]}>
            {category.label}
          </Text>
        </View>
        <View style={{ flex: 1 }} />
        <Text style={typography.caption}>{formatTime(report.dateTime)}</Text>
        {canDelete && (
          <Pressable hitSlop={8} onPress={onDelete} style={{ marginLeft: 8 }}>
            <MaterialIcons name="delete-outline" size={16} color={colors.error} />
          </Pressable>
        )}
      </View>
      <View style={{ flex: 1, marginTop: 8 }}>
        <Text style={[typography.bodyMedium, { fontFamily: fonts.bold }]} numberOfLines={2}>
          {report.description}
        </Text>
        <View style={styles.addressRow}>
          <MaterialIcons name="location-on" size={12} color={colors.textLight} />
          <Text style={[typography.caption, { flex: 1, marginLeft: 4 }]} numberOfLines={1}>
            {report.address}
          </Text>
        </View>
      </View>
      <View style={styles.divider} />
      <View style={styles.footer}>
        <View style={{ flex: 1 }}>
          <Text
            style={[
              typography.caption,
              {
                fontFamily: fonts.bold,
                color: report.confirmedUserIds.length === 0 ? colors.textLight : colors.success,
              },
            ]}>
            {report.confirmedUserIds.length === 0 ? 'Henüz doğrulanmadı' : `${report.confirmedUserIds.length} Doğrulama`}
          </Text>
          {report.unconfirmedUserIds.length > 0 && (
            <Text style={[typography.caption, { fontFamily: fonts.bold, color: colors.error }]}>
              {`${report.unconfirmedUserIds.length} Yanlış Bildirimi`}
            </Text>
          )}
        </View>
        <VoteButton
          label="Doğrula"
          active={isConfirmed}
          activeColor={colors.success}
          icon={isConfirmed ? 'check-circle' : 'check-circle-outline'}
          spinnerColor={colors.primary}
          onToggle={() => toggleConfirmReport(report.id)}
        />
        <View style={{ width: 6 }} />
        <VoteButton
          label="Yanlış"
          active={isUnconfirmed}
          activeColor={colors.error}
          icon={isUnconfirmed ? 'cancel' : 'highlight-off'}
          spinnerColor={colors.error}
          onToggle={() => toggleUnconfirmReport(report.id)}
        />
      </View>
    </View>
  );
}

function VoteButton({
  label,
  active,
  activeColor,
  icon,
  spinnerColor,
  onToggle,
}: {
  label: string;
  active: boolean;
  activeColor: string;
  icon: 'check-circle' | 'check-circle-outline' | 'cancel' | 'highlight-off';
  spinnerColor: string;
  onToggle: () => Promise<void>;
}) {
  const isGuest = useIsGuest();
  const [loading, setLoading] = useState(false);
  const foreground = active ? colors.white : colors.textSecondary;

  return (
    <Pressable
      disabled={loading}
      onPress={async () => {
        if (isGuest) {
          showSnackbar({ message: 'Doğrulamak için lütfen giriş yapın.', backgroundColor: colors.error });
          return;
        }
        haptics.light();
        setLoading(true);
        try {
          await onToggle();
        } catch (error) {
          showSnackbar({ message: String(error), backgroundColor: colors.error });
        } finally {
          setLoading(false);
        }
      }}
      style={[styles.voteButton, { backgroundColor: active ? activeColor : '#F5F5F5' }]}>
      {loading ? (
        <ActivityIndicator size={14} color={spinnerColor} />
      ) : (
        <MaterialIcons name={icon} size={14} color={foreground} />
      )}
      <Text style={[typography.caption, { marginLeft: 4, fontFamily: fonts.bold, color: foreground }]}>{label}</Text>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  center: {
    alignItems: 'center',
    justifyContent: 'center',
  },
  header: {
    paddingHorizontal: 16,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
  },
  addButton: {
    paddingHorizontal: 14,
    paddingVertical: 8,
    flexDirection: 'row',
    alignItems: 'center',
    borderRadius: 20,
    backgroundColor: colors.primary,
    elevation: 2,
    shadowColor: '#000000',
    shadowOpacity: 0.15,
    shadowRadius: 2,
    shadowOffset: { width: 0, height: 1 },
  },
  emptyCard: {
    marginHorizontal: 16,
    padding: 16,
    flexDirection: 'row',
    alignItems: 'center',
    borderRadius: 16,
    borderWidth: 1,
    borderColor: '#EEEEEE',
    backgroundColor: '#FAFAFA',
  },
  card: {
    width: 280,
    marginRight: 12,
    padding: 12,
    borderRadius: 16,
    borderWidth: 1,
    borderColor: '#EEEEEE',
    backgroundColor: colors.white,
    shadowColor: '#000000',
    shadowOpacity: 0.03,
    shadowRadius: 10,
    shadowOffset: { width: 0, height: 4 },
    elevation: 1,
  },
  cardHeader: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  categoryBadge: {
    paddingHorizontal: 8,
    paddingVertical: 4,
    flexDirection: 'row',
    alignItems: 'center',
    borderRadius: 8,
    backgroundColor: 'rgba(76, 175, 80, 0.08)',
  },
  addressRow: {
    marginTop: 4,
    flexDirection: 'row',
    alignItems: 'center',
  },
  divider: {
    height: 1,
    marginVertical: 7.5,
    backgroundColor: '#E0E0E0',
  },
  footer: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  voteButton: {
    paddingHorizontal: 10,
    paddingVertical: 6,
    flexDirection: 'row',
    alignItems: 'center',
    borderRadius: 8,
  },
});
