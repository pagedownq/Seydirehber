import { MaterialIcons } from '@expo/vector-icons';
import { collection, doc, onSnapshot, orderBy, query, updateDoc } from '@react-native-firebase/firestore';
import { useEffect, useState } from 'react';
import { ActivityIndicator, FlatList, StyleSheet, Switch, Text, View } from 'react-native';

import { AppBar } from '@/components/app-bar';
import { showSnackbar, snackbarColors } from '@/components/snackbar';
import { sendToToken } from '@/features/admin/fcm-sender';
import type { LiveDoc } from '@/features/firestore/live-query';
import { db } from '@/services/firebase';
import { colors, fonts, typography } from '@/theme';
import { formatDots, formatTime } from '@/utils/date';
import { isTimestamp } from '@/utils/firestore-values';

// Flutter lib/features/admin/screens/admin_support_screen.dart karşılığı (yardim_destek).
export function AdminSupportScreen() {
  const [docs, setDocs] = useState<LiveDoc[] | null>(null);

  useEffect(
    () =>
      onSnapshot(query(collection(db, 'yardim_destek'), orderBy('tarih', 'desc')), (snapshot) =>
        setDocs(snapshot.docs.map((d) => ({ id: d.id, data: d.data() as Record<string, unknown> }))),
      ),
    [],
  );

  let body;
  if (docs == null) {
    body = (
      <View style={styles.center}>
        <ActivityIndicator size="large" color={colors.primary} />
      </View>
    );
  } else if (docs.length === 0) {
    body = (
      <View style={styles.center}>
        <Text style={typography.bodyMedium}>Henüz mesaj yok</Text>
      </View>
    );
  } else {
    body = (
      <FlatList
        data={docs}
        keyExtractor={(item) => item.id}
        contentContainerStyle={{ padding: 16 }}
        renderItem={({ item }) => <SupportCard item={item} />}
      />
    );
  }

  return (
    <View style={styles.container}>
      <AppBar title="Yardım ve Destek Mesajları" />
      <View style={{ flex: 1 }}>{body}</View>
    </View>
  );
}

function SupportCard({ item }: { item: LiveDoc }) {
  const { data } = item;
  const str = (key: string, fallback = '') => (typeof data[key] === 'string' ? (data[key] as string) : fallback);
  const name = str('ad_soyad', 'İsimsiz');
  const category = str('kategori', 'Genel');
  const message = str('mesaj');
  const email = str('email');
  const phone = str('telefon');
  const status = str('durum', 'Bekliyor');
  const date = isTimestamp(data.tarih) ? data.tarih.toDate() : null;
  const isSolved = status === 'Çözüldü';
  const accent = isSolved ? colors.success : colors.primary;

  const onToggle = async (value: boolean) => {
    try {
      await updateDoc(doc(db, 'yardim_destek', item.id), { durum: value ? 'Çözüldü' : 'Bekliyor' });
      if (!value) return;

      const token = data.fcm_token;
      if (token != null && String(token).length > 0) {
        try {
          await sendToToken(
            String(token),
            'Destek Talebiniz Çözüldü ✅',
            `${String(data.kategori)} konulu destek talebiniz başarıyla çözülmüştür. Teşekkürler!`,
          );
        } catch (error) {
          // Flutter gönderim hatasını sadece loglar; mesaj yine "gönderildi" der.
          console.warn('FCM Targeted Error:', error);
        }
        showSnackbar({ message: 'Kullanıcıya bildirim gönderildi.', backgroundColor: snackbarColors.green });
      } else {
        showSnackbar({
          message: 'Bu mesajın bildirim anahtarı (Token) bulunamadı. (Eski bir kayıt olabilir)',
          backgroundColor: snackbarColors.orange,
        });
      }
    } catch (error) {
      showSnackbar({ message: `Hata: ${String(error)}`, backgroundColor: '#F44336' });
    }
  };

  return (
    <View style={styles.card}>
      <View style={[styles.cardHeader, { backgroundColor: isSolved ? 'rgba(67, 160, 71, 0.1)' : 'rgba(76, 175, 80, 0.1)' }]}>
        <View style={[styles.categoryBadge, { backgroundColor: accent }]}>
          <Text style={styles.categoryText}>{category.toUpperCase()}</Text>
        </View>
        <View style={{ flex: 1 }} />
        <Text style={typography.caption}>{date ? `${formatDots(date)} ${formatTime(date)}` : ''}</Text>
      </View>
      <View style={{ padding: 16 }}>
        <InfoRow icon="person" text={name} bold />
        <View style={{ height: 4 }} />
        <InfoRow icon="email" text={email} />
        {phone.length > 0 && (
          <>
            <View style={{ height: 4 }} />
            <InfoRow icon="phone" text={phone} />
          </>
        )}
        <View style={styles.divider} />
        <Text style={typography.bodyMedium}>{message}</Text>
        <View style={styles.statusRow}>
          <Text style={[styles.statusText, { color: accent }]}>{`Durum: ${status}`}</Text>
          <Switch
            value={isSolved}
            onValueChange={onToggle}
            trackColor={{ true: colors.success, false: '#E0E0E0' }}
            thumbColor={colors.white}
          />
        </View>
      </View>
    </View>
  );
}

function InfoRow({ icon, text, bold = false }: { icon: 'person' | 'email' | 'phone'; text: string; bold?: boolean }) {
  return (
    <View style={styles.infoRow}>
      <MaterialIcons name={icon} size={18} color={colors.textLight} />
      <Text style={[bold ? typography.bodyMedium : typography.bodySmall, { flex: 1, marginLeft: 8 }, bold && { fontFamily: fonts.bold }]}>
        {text}
      </Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.background,
  },
  center: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
  card: {
    marginBottom: 16,
    borderRadius: 16,
    overflow: 'hidden',
    backgroundColor: colors.white,
    elevation: 1,
    shadowColor: '#000000',
    shadowOpacity: 0.12,
    shadowRadius: 2,
    shadowOffset: { width: 0, height: 1 },
  },
  cardHeader: {
    paddingHorizontal: 16,
    paddingVertical: 10,
    flexDirection: 'row',
    alignItems: 'center',
  },
  categoryBadge: {
    paddingHorizontal: 10,
    paddingVertical: 4,
    borderRadius: 8,
  },
  categoryText: {
    fontFamily: fonts.bold,
    fontSize: 10,
    color: colors.white,
  },
  infoRow: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  divider: {
    height: 1,
    marginVertical: 11.5,
    backgroundColor: colors.divider,
  },
  statusRow: {
    marginTop: 20,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
  },
  statusText: {
    fontFamily: fonts.bold,
    fontSize: 14,
  },
});
