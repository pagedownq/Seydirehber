import { MaterialIcons } from '@expo/vector-icons';
import {
  addDoc,
  collection,
  deleteDoc,
  doc,
  limit,
  onSnapshot,
  orderBy,
  query,
  serverTimestamp,
} from '@react-native-firebase/firestore';
import { useEffect, useState } from 'react';
import { ActivityIndicator, FlatList, Pressable, StyleSheet, Text, TextInput, View } from 'react-native';

import { AppBar } from '@/components/app-bar';
import { appNotification } from '@/components/app-notification';
import { BottomSheet } from '@/components/bottom-sheet';
import { sendBroadcast } from '@/features/admin/fcm-sender';
import type { LiveDoc } from '@/features/firestore/live-query';
import { db } from '@/services/firebase';
import { colors, fonts } from '@/theme';
import { alertConfirm } from '@/utils/alert-confirm';
import { formatDots, formatTime } from '@/utils/date';
import { isTimestamp } from '@/utils/firestore-values';

// Flutter lib/features/admin/screens/admin_notifications_screen.dart karşılığı.
type State = { status: 'loading' } | { status: 'error'; error: Error } | { status: 'ready'; docs: LiveDoc[] };

export function AdminNotificationsScreen() {
  const [state, setState] = useState<State>({ status: 'loading' });
  const [sheetVisible, setSheetVisible] = useState(false);

  useEffect(
    () =>
      onSnapshot(
        query(collection(db, 'duyurular'), orderBy('tarih', 'desc'), limit(20)),
        (snapshot) =>
          setState({
            status: 'ready',
            docs: snapshot.docs.map((d) => ({ id: d.id, data: d.data() as Record<string, unknown> })),
          }),
        (error) => setState({ status: 'error', error }),
      ),
    [],
  );

  let body;
  if (state.status === 'error') {
    body = (
      <View style={styles.center}>
        <Text style={styles.plain}>{`Hata: ${String(state.error)}`}</Text>
      </View>
    );
  } else if (state.status === 'loading') {
    body = (
      <View style={styles.center}>
        <ActivityIndicator size="large" color={colors.primary} />
      </View>
    );
  } else if (state.docs.length === 0) {
    body = (
      <View style={styles.center}>
        <MaterialIcons name="notifications-off" size={80} color="#E0E0E0" />
        <Text style={styles.emptyText}>Henüz gönderilmiş bildirim yok.</Text>
      </View>
    );
  } else {
    body = (
      <View style={{ flex: 1 }}>
        <View style={styles.historyHeader}>
          <MaterialIcons name="history" size={18} color="#FFA000" />
          <Text style={styles.historyTitle}>Bildirim Geçmişi (Son 20)</Text>
        </View>
        <FlatList
          data={state.docs}
          keyExtractor={(item) => item.id}
          contentContainerStyle={{ paddingHorizontal: 16, paddingBottom: 96 }}
          renderItem={({ item }) => <HistoryItem item={item} />}
        />
      </View>
    );
  }

  return (
    <View style={styles.container}>
      <AppBar title="Bildirim Yönetimi" centerTitle />
      <View style={{ flex: 1 }}>{body}</View>
      <Pressable onPress={() => setSheetVisible(true)} style={styles.fab}>
        <MaterialIcons name="send" size={24} color={colors.white} />
        <Text style={styles.fabLabel}>Yeni Gönder</Text>
      </Pressable>
      <BottomSheet visible={sheetVisible} onClose={() => setSheetVisible(false)} avoidKeyboard>
        {sheetVisible && <SendForm onClose={() => setSheetVisible(false)} />}
      </BottomSheet>
    </View>
  );
}

function HistoryItem({ item }: { item: LiveDoc }) {
  const [expanded, setExpanded] = useState(false);
  const title = typeof item.data.baslik === 'string' ? item.data.baslik : 'Başlıksız';
  const body = typeof item.data.icerik === 'string' ? item.data.icerik : '';
  const date = isTimestamp(item.data.tarih) ? item.data.tarih.toDate() : null;

  return (
    <View style={styles.card}>
      <Pressable onPress={() => setExpanded((v) => !v)} style={styles.cardHeader}>
        <View style={styles.cardIcon}>
          <MaterialIcons name="notifications-active" size={20} color="#FFA000" />
        </View>
        <View style={{ flex: 1, marginHorizontal: 16 }}>
          <Text style={styles.cardTitle}>{title}</Text>
          {date && <Text style={styles.cardDate}>{`${formatDots(date)} ${formatTime(date)}`}</Text>}
        </View>
        <Pressable
          hitSlop={8}
          onPress={async () => {
            const confirmed = await alertConfirm({
              title: 'Sil?',
              content: 'Bu bildirim kaydını geçmişten silmek istediğinize emin misiniz?',
              cancelText: 'İptal',
              confirmText: 'Sil',
              isDestructive: true,
            });
            if (confirmed) await deleteDoc(doc(db, 'duyurular', item.id));
          }}>
          <MaterialIcons name="delete-outline" size={22} color="#FF5252" />
        </Pressable>
      </Pressable>
      {expanded && (
        <View style={styles.cardBodyWrap}>
          <View style={styles.cardBody}>
            <Text style={styles.cardBodyText}>{body}</Text>
          </View>
        </View>
      )}
    </View>
  );
}

function SendForm({ onClose }: { onClose: () => void }) {
  const [title, setTitle] = useState('');
  const [body, setBody] = useState('');
  const [sending, setSending] = useState(false);

  const send = async () => {
    if (!title || !body) {
      appNotification.error('Lütfen tüm alanları doldurun!');
      return;
    }
    try {
      // 1. FCM ile gönder
      setSending(true);
      try {
        await sendBroadcast(title, body);
      } finally {
        setSending(false);
      }
      // 2. Geçmişe kaydet
      await addDoc(collection(db, 'duyurular'), { baslik: title, icerik: body, tarih: serverTimestamp() });
      onClose();
      appNotification.success('Bildirim başarıyla tüm kullanıcılara gönderildi!');
    } catch (error) {
      appNotification.error(`Hata oluştu: ${String(error)}`);
    }
  };

  return (
    <View style={styles.sheet}>
      <View style={styles.handle} />
      <View style={styles.sheetHeader}>
        <View style={styles.sheetIcon}>
          <MaterialIcons name="send" size={24} color={colors.primary} />
        </View>
        <Text style={styles.sheetTitle}>Yeni Bildirim Gönder</Text>
      </View>
      <FilledField label="Bildirim Başlığı" hint="Örn: Yeni Etkinlik Duyurusu" value={title} onChange={setTitle} />
      <View style={{ height: 16 }} />
      <FilledField
        label="Bildirim İçeriği"
        hint="Bildirim metnini buraya yazın..."
        value={body}
        onChange={setBody}
        multiline
      />
      <Pressable disabled={sending} onPress={send} style={[styles.sendButton, sending && { opacity: 0.6 }]}>
        {sending ? (
          <ActivityIndicator size={20} color={colors.white} />
        ) : (
          <Text style={styles.sendText}>Şimdi Tüm Cihazlara Gönder</Text>
        )}
      </Pressable>
    </View>
  );
}

function FilledField({
  label,
  hint,
  value,
  onChange,
  multiline = false,
}: {
  label: string;
  hint: string;
  value: string;
  onChange: (value: string) => void;
  multiline?: boolean;
}) {
  const [focused, setFocused] = useState(false);
  const floating = focused || value.length > 0;
  return (
    <View style={[styles.filled, focused && { borderColor: colors.primary, borderWidth: 2 }]}>
      <TextInput
        value={value}
        onChangeText={onChange}
        placeholder={focused ? hint : label}
        placeholderTextColor={colors.textSecondary}
        multiline={multiline}
        numberOfLines={multiline ? 3 : 1}
        textAlignVertical={multiline ? 'top' : 'center'}
        onFocus={() => setFocused(true)}
        onBlur={() => setFocused(false)}
        style={[styles.filledInput, multiline && { minHeight: 3 * 22 + 30 }]}
      />
      {floating && (
        <Text style={[styles.floatingLabel, { color: focused ? colors.primary : colors.textSecondary }]}>{label}</Text>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#FAFAFA',
  },
  center: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
  plain: {
    fontFamily: fonts.regular,
    fontSize: 14,
    color: colors.textPrimary,
  },
  emptyText: {
    marginTop: 16,
    fontFamily: fonts.regular,
    fontSize: 16,
    color: '#9E9E9E',
  },
  historyHeader: {
    padding: 16,
    flexDirection: 'row',
    alignItems: 'center',
  },
  historyTitle: {
    marginLeft: 8,
    fontFamily: fonts.bold,
    fontSize: 14,
    color: '#616161',
  },
  card: {
    marginBottom: 16,
    borderRadius: 16,
    backgroundColor: colors.white,
    shadowColor: '#000000',
    shadowOpacity: 0.03,
    shadowRadius: 10,
    shadowOffset: { width: 0, height: 4 },
    elevation: 1,
  },
  cardHeader: {
    minHeight: 64,
    paddingHorizontal: 16,
    paddingVertical: 8,
    flexDirection: 'row',
    alignItems: 'center',
  },
  cardIcon: {
    padding: 8,
    borderRadius: 10,
    backgroundColor: '#FFF8E1',
  },
  cardTitle: {
    fontFamily: fonts.bold,
    fontSize: 16,
    color: colors.textPrimary,
  },
  cardDate: {
    fontFamily: fonts.regular,
    fontSize: 12,
    color: '#9E9E9E',
  },
  cardBodyWrap: {
    paddingHorizontal: 16,
    paddingBottom: 16,
  },
  cardBody: {
    padding: 12,
    borderRadius: 12,
    backgroundColor: '#FAFAFA',
  },
  cardBodyText: {
    fontFamily: fonts.regular,
    fontSize: 14,
    lineHeight: 21,
    color: '#424242',
  },
  fab: {
    position: 'absolute',
    right: 16,
    bottom: 32,
    height: 56,
    paddingHorizontal: 20,
    flexDirection: 'row',
    alignItems: 'center',
    borderRadius: 16,
    backgroundColor: colors.primary,
    shadowColor: '#000000',
    shadowOpacity: 0.2,
    shadowRadius: 5,
    shadowOffset: { width: 0, height: 3 },
    elevation: 4,
  },
  fabLabel: {
    marginLeft: 8,
    fontFamily: fonts.bold,
    fontSize: 14,
    color: colors.white,
  },
  sheet: {
    padding: 24,
    borderTopLeftRadius: 32,
    borderTopRightRadius: 32,
    backgroundColor: colors.white,
  },
  handle: {
    alignSelf: 'center',
    width: 40,
    height: 4,
    borderRadius: 2,
    backgroundColor: '#E0E0E0',
  },
  sheetHeader: {
    marginTop: 24,
    marginBottom: 24,
    flexDirection: 'row',
    alignItems: 'center',
  },
  sheetIcon: {
    padding: 8,
    borderRadius: 12,
    backgroundColor: 'rgba(76, 175, 80, 0.1)',
  },
  sheetTitle: {
    marginLeft: 12,
    fontFamily: fonts.bold,
    fontSize: 20,
    color: colors.textPrimary,
  },
  filled: {
    borderRadius: 16,
    borderWidth: 1,
    borderColor: '#EEEEEE',
    backgroundColor: '#FAFAFA',
  },
  filledInput: {
    minHeight: 52,
    paddingHorizontal: 16,
    paddingVertical: 14,
    fontFamily: fonts.regular,
    fontSize: 16,
    color: colors.textPrimary,
  },
  floatingLabel: {
    position: 'absolute',
    top: -9,
    left: 12,
    paddingHorizontal: 4,
    backgroundColor: '#FAFAFA',
    fontFamily: fonts.regular,
    fontSize: 12,
  },
  sendButton: {
    marginTop: 24,
    paddingVertical: 18,
    alignItems: 'center',
    justifyContent: 'center',
    borderRadius: 16,
    backgroundColor: colors.primary,
  },
  sendText: {
    fontFamily: fonts.bold,
    fontSize: 16,
    color: colors.white,
  },
});
