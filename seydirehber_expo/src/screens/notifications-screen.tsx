import { MaterialIcons } from '@expo/vector-icons';
import { collection, onSnapshot, orderBy, query, Timestamp, where } from '@react-native-firebase/firestore';
import { useEffect, useState } from 'react';
import { ActivityIndicator, FlatList, Pressable, StyleSheet, Text, View } from 'react-native';

import { AppBar } from '@/components/app-bar';
import type { FirestoreData } from '@/features/firestore/live-query';
import { auth, db } from '@/services/firebase';
import { haptics } from '@/services/haptics';
import { getInstallationDate } from '@/services/notifications';
import { colors, fonts } from '@/theme';
import { formatDots, formatTime } from '@/utils/date';
import { isTimestamp } from '@/utils/firestore-values';

// Flutter lib/features/notifications/screens/user_notifications_screen.dart karşılığı:
// uygulamanın ilk açıldığı tarihten sonraki duyurular (genel olanlar + bu kullanıcıya özel olanlar).
type Announcement = { id: string; data: FirestoreData };
type State =
  | { status: 'loading' }
  | { status: 'error'; error: Error }
  | { status: 'success'; docs: Announcement[] };

export function NotificationsScreen() {
  const [installation, setInstallation] = useState<{ loading: boolean; date: Date | null }>({
    loading: true,
    date: null,
  });

  useEffect(() => {
    getInstallationDate().then((date) => setInstallation({ loading: false, date }));
  }, []);

  if (installation.loading) {
    return (
      <View style={[styles.container, styles.center, { backgroundColor: colors.white }]}>
        <ActivityIndicator size="large" color={colors.primary} />
      </View>
    );
  }

  return (
    <View style={styles.container}>
      <AppBar title="Bildirimler" centerTitle />
      {installation.date == null ? (
        <View style={styles.center}>
          <Text style={styles.plainText}>Bildirim geçmişi yüklenemedi.</Text>
        </View>
      ) : (
        <AnnouncementList since={installation.date} />
      )}
    </View>
  );
}

function AnnouncementList({ since }: { since: Date }) {
  const [state, setState] = useState<State>({ status: 'loading' });
  const currentUserId = auth.currentUser?.uid ?? null;

  useEffect(
    () =>
      onSnapshot(
        query(
          collection(db, 'duyurular'),
          where('tarih', '>', Timestamp.fromDate(since)),
          orderBy('tarih', 'desc'),
        ),
        (snapshot) =>
          setState({
            status: 'success',
            docs: snapshot.docs.map((d) => ({ id: d.id, data: d.data() as FirestoreData })),
          }),
        (error) => setState({ status: 'error', error }),
      ),
    [since],
  );

  if (state.status === 'error') {
    return (
      <View style={[styles.center, { padding: 24 }]}>
        <Text style={styles.plainText}>{`Hata: ${String(state.error)}`}</Text>
      </View>
    );
  }
  if (state.status === 'loading') {
    return (
      <View style={styles.center}>
        <ActivityIndicator size="large" color={colors.primary} />
      </View>
    );
  }

  // Genel duyurular (targetUserId yok) + bu kullanıcıya özel olanlar
  const docs = state.docs.filter(({ data }) => {
    const targetId = data.targetUserId;
    return targetId == null || (currentUserId != null && targetId === currentUserId);
  });

  if (docs.length === 0) {
    return (
      <View style={styles.center}>
        <MaterialIcons name="notifications-off" size={80} color="#E0E0E0" />
        <Text style={styles.emptyText}>Henüz yeni bir bildirim yok.</Text>
      </View>
    );
  }

  return (
    <FlatList
      data={docs}
      keyExtractor={(item) => item.id}
      contentContainerStyle={{ padding: 16 }}
      renderItem={({ item }) => {
        const title = typeof item.data.baslik === 'string' ? item.data.baslik : 'Duyuru';
        const body = typeof item.data.icerik === 'string' ? item.data.icerik : '';
        const date = isTimestamp(item.data.tarih) ? item.data.tarih.toDate() : null;
        return (
          <Pressable onPress={() => haptics.selection()} style={styles.card}>
            <View style={styles.icon}>
              <MaterialIcons name="notifications-none" size={24} color={colors.primary} />
            </View>
            <View style={{ flex: 1, marginLeft: 16 }}>
              <Text style={styles.title}>{title}</Text>
              <Text style={styles.body}>{body}</Text>
              {date && <Text style={styles.date}>{`${formatDots(date)} ${formatTime(date)}`}</Text>}
            </View>
          </Pressable>
        );
      }}
    />
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
  plainText: {
    fontFamily: fonts.regular,
    fontSize: 14,
    color: colors.textPrimary,
    textAlign: 'center',
  },
  emptyText: {
    marginTop: 16,
    fontFamily: fonts.regular,
    fontSize: 16,
    color: '#9E9E9E',
  },
  card: {
    marginBottom: 12,
    padding: 16,
    flexDirection: 'row',
    alignItems: 'flex-start',
    borderRadius: 16,
    backgroundColor: colors.white,
    shadowColor: '#000000',
    shadowOpacity: 0.04,
    shadowRadius: 10,
    shadowOffset: { width: 0, height: 4 },
    elevation: 2,
  },
  icon: {
    padding: 10,
    borderRadius: 999,
    backgroundColor: 'rgba(76, 175, 80, 0.1)',
  },
  title: {
    fontFamily: fonts.bold,
    fontSize: 16,
    color: colors.textPrimary,
  },
  body: {
    marginTop: 6,
    fontFamily: fonts.regular,
    fontSize: 14,
    lineHeight: 19.6,
    color: '#616161',
  },
  date: {
    marginTop: 8,
    fontFamily: fonts.regular,
    fontSize: 12,
    color: '#BDBDBD',
  },
});
