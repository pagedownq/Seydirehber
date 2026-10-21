import { MaterialIcons } from '@expo/vector-icons';
import { collection, deleteDoc, doc, onSnapshot, orderBy, query } from '@react-native-firebase/firestore';
import { useEffect, useState } from 'react';
import { ActivityIndicator, FlatList, Pressable, StyleSheet, Text, View } from 'react-native';

import { AppBar } from '@/components/app-bar';
import { PopupMenu } from '@/components/popup-menu';
import { showSnackbar } from '@/components/snackbar';
import type { LiveDoc } from '@/features/firestore/live-query';
import { deleteReview } from '@/features/reviews/review-service';
import { db } from '@/services/firebase';
import { colors, fonts, typography } from '@/theme';
import { alertConfirm } from '@/utils/alert-confirm';
import { formatDots, formatTime } from '@/utils/date';
import { isTimestamp } from '@/utils/firestore-values';

// Flutter admin_reviews_screen.dart + admin_reports_screen.dart karşılığı.

function useCollection(name: string, orderField: string) {
  const [docs, setDocs] = useState<LiveDoc[] | null>(null);
  useEffect(
    () =>
      onSnapshot(query(collection(db, name), orderBy(orderField, 'desc')), (snapshot) =>
        setDocs(snapshot.docs.map((d) => ({ id: d.id, data: d.data() as Record<string, unknown> }))),
      ),
    [name, orderField],
  );
  return docs;
}

const dateText = (value: unknown) => {
  const date = isTimestamp(value) ? value.toDate() : new Date();
  return `${formatDots(date)} ${formatTime(date)}`;
};

function ListBody({ docs, empty, render }: { docs: LiveDoc[] | null; empty: string; render: (item: LiveDoc) => React.ReactElement }) {
  if (docs == null) {
    return (
      <View style={styles.center}>
        <ActivityIndicator size="large" color={colors.primary} />
      </View>
    );
  }
  if (docs.length === 0) {
    return (
      <View style={styles.center}>
        <Text style={typography.bodyMedium}>{empty}</Text>
      </View>
    );
  }
  return (
    <FlatList
      data={docs}
      keyExtractor={(item) => item.id}
      contentContainerStyle={{ padding: 16 }}
      ItemSeparatorComponent={() => <View style={{ height: 12 }} />}
      renderItem={({ item }) => render(item)}
    />
  );
}

export function AdminReviewsScreen() {
  const docs = useCollection('reviews', 'createdAt');

  const confirmDelete = async (reviewId: string) => {
    const confirmed = await alertConfirm({
      title: 'Yorumu Sil',
      content: 'Bu yorumu silmek istediğinize emin misiniz? Bu işlem geri alınamaz.',
      confirmText: 'Sil',
      isDestructive: true,
    });
    if (!confirmed) return;
    try {
      await deleteReview(reviewId);
      showSnackbar({ message: 'Yorum başarıyla silindi' });
    } catch (error) {
      showSnackbar({ message: `Hata: ${String(error)}` });
    }
  };

  return (
    <View style={styles.container}>
      <AppBar title="Yorum Yönetimi" />
      <ListBody
        docs={docs}
        empty="Henüz yorum yapılmamış."
        render={({ id, data }) => (
          <View style={styles.card}>
            <View style={styles.row}>
              <View style={{ flex: 1 }}>
                <Text style={styles.name}>{typeof data.userName === 'string' ? data.userName : 'İsimsiz Kullanıcı'}</Text>
                <Text style={styles.date}>{dateText(data.createdAt)}</Text>
              </View>
              <MaterialIcons name="star" size={20} color="#FFC107" />
              <Text style={[styles.rating, { marginLeft: 4 }]}>{formatRating(data.rating)}</Text>
              <Pressable hitSlop={8} onPress={() => confirmDelete(id)} style={{ marginLeft: 12 }}>
                <MaterialIcons name="delete-outline" size={24} color="#F44336" />
              </Pressable>
            </View>
            <View style={styles.targetBadge}>
              <Text style={styles.targetText}>{`Target: ${String(data.targetId)}`}</Text>
            </View>
            <Text style={styles.comment}>{typeof data.comment === 'string' ? data.comment : ''}</Text>
          </View>
        )}
      />
    </View>
  );
}

/** Dart num.toString: 5 → "5", 4.5 → "4.5"; alan yoksa 0.0 → "0.0". */
function formatRating(value: unknown) {
  if (typeof value !== 'number') return '0.0';
  return String(value);
}

export function AdminReportsScreen() {
  const docs = useCollection('sikayetler', 'timestamp');

  const confirmDeleteReview = async (reviewId: unknown, reportId: string) => {
    if (typeof reviewId !== 'string') return;
    const confirmed = await alertConfirm({
      title: 'Yorumu Sil',
      content: 'Bu yorumu silmek istediğinize emin misiniz? Şikayet de otomatik olarak kapatılacaktır.',
      confirmText: 'Sil',
      isDestructive: true,
    });
    if (!confirmed) return;
    try {
      await deleteReview(reviewId);
      await deleteDoc(doc(db, 'sikayetler', reportId));
      showSnackbar({ message: 'Yorum silindi ve şikayet kapatıldı.' });
    } catch (error) {
      showSnackbar({ message: `Hata: ${String(error)}` });
    }
  };

  const dismissReport = async (reportId: string) => {
    try {
      await deleteDoc(doc(db, 'sikayetler', reportId));
      showSnackbar({ message: 'Şikayet kapatıldı ve silindi.' });
    } catch (error) {
      showSnackbar({ message: `Hata: ${String(error)}` });
    }
  };

  return (
    <View style={styles.container}>
      <AppBar title="Yorum Şikayetleri" />
      <ListBody
        docs={docs}
        empty="Henüz şikayet bulunmuyor."
        render={({ id, data }) => (
          <View style={styles.card}>
            <View style={styles.row}>
              <View style={{ flex: 1 }}>
                <Text style={styles.name}>
                  {`Şikayet Edilen: ${typeof data.userName === 'string' ? data.userName : 'Bilinmiyor'}`}
                </Text>
                <Text style={styles.date}>{dateText(data.timestamp)}</Text>
              </View>
              <PopupMenu
                icon="more-vert"
                iconSize={24}
                iconColor="#49454F"
                items={[
                  { value: 'delete', label: 'Yorumu Sil', icon: null, labelStyle: { color: '#F44336' } },
                  { value: 'dismiss', label: 'Şikayeti Kapat', icon: null },
                ]}
                onSelect={(value) =>
                  value === 'delete' ? confirmDeleteReview(data.reviewId, id) : dismissReport(id)
                }
              />
            </View>
            <View style={styles.reportBox}>
              <Text style={styles.reportLabel}>Yorum İçeriği:</Text>
              <Text style={[styles.comment, { marginTop: 4 }]}>{typeof data.content === 'string' ? data.content : ''}</Text>
            </View>
            <View style={[styles.row, { marginTop: 12 }]}>
              <MaterialIcons name="info-outline" size={14} color={colors.textLight} />
              <Text style={styles.targetInfo}>{`Hedef: ${String(data.targetType)} / ${String(data.targetId)}`}</Text>
            </View>
          </View>
        )}
      />
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
    padding: 16,
    borderRadius: 16,
    backgroundColor: colors.white,
    shadowColor: '#000000',
    shadowOpacity: 0.02,
    shadowRadius: 10,
    shadowOffset: { width: 0, height: 4 },
    elevation: 1,
  },
  row: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  name: {
    fontFamily: fonts.bold,
    fontSize: 16,
    color: colors.textPrimary,
  },
  date: {
    fontFamily: fonts.regular,
    fontSize: 12,
    color: colors.textLight,
  },
  rating: {
    fontFamily: fonts.bold,
    fontSize: 14,
    color: colors.textPrimary,
  },
  targetBadge: {
    alignSelf: 'flex-start',
    marginTop: 8,
    paddingHorizontal: 8,
    paddingVertical: 4,
    borderRadius: 6,
    backgroundColor: colors.primarySurface,
  },
  targetText: {
    fontFamily: fonts.regular,
    fontSize: 10,
    color: colors.primaryDark,
  },
  comment: {
    marginTop: 12,
    fontFamily: fonts.regular,
    fontSize: 14,
    color: colors.black87,
  },
  reportBox: {
    marginTop: 12,
    padding: 12,
    borderRadius: 12,
    borderWidth: 1,
    borderColor: 'rgba(244, 67, 54, 0.1)',
    backgroundColor: 'rgba(244, 67, 54, 0.05)',
  },
  reportLabel: {
    fontFamily: fonts.bold,
    fontSize: 11,
    color: '#F44336',
  },
  targetInfo: {
    marginLeft: 4,
    fontFamily: fonts.regular,
    fontSize: 11,
    color: colors.textLight,
  },
});
