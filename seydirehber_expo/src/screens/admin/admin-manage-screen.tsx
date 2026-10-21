import { MaterialIcons } from '@expo/vector-icons';
import {
  collection,
  deleteDoc,
  doc,
  getDocs,
  onSnapshot,
  orderBy,
  query,
  where,
  writeBatch,
} from '@react-native-firebase/firestore';
import { useEffect, useState } from 'react';
import { ActivityIndicator, FlatList, Pressable, StyleSheet, Text, View } from 'react-native';
import ReorderableList, { reorderItems, useReorderableDrag } from 'react-native-reorderable-list';

import { AppBar } from '@/components/app-bar';
import { CachedImage } from '@/components/cached-image';
import { PopupMenu } from '@/components/popup-menu';
import { showSnackbar } from '@/components/snackbar';
import { AdminEditSheet, type EditTarget } from '@/features/admin/admin-edit-sheet';
import { displayName, isReorderable, sortDocs } from '@/features/admin/manage-config';
import type { LiveDoc } from '@/features/firestore/live-query';
import { db } from '@/services/firebase';
import { supabase } from '@/services/supabase';
import { colors, fonts, typography } from '@/theme';
import { alertConfirm } from '@/utils/alert-confirm';
import { isTimestamp } from '@/utils/firestore-values';

// Flutter lib/features/admin/screens/admin_manage_screen.dart karşılığı (koleksiyon bazlı CRUD).
type DocsState = { status: 'loading' } | { status: 'ready'; docs: LiveDoc[] };

/** created_at'e göre yeniden eskiye; sorgu hata verirse (ör. index) sırasız sorguya düşer. */
function useCollectionDocs(collectionName: string): DocsState {
  const [state, setState] = useState<DocsState>({ status: 'loading' });
  const [fallback, setFallback] = useState(false);

  useEffect(() => {
    const ref = collection(db, collectionName);
    return onSnapshot(
      fallback ? ref : query(ref, orderBy('created_at', 'desc')),
      (snapshot) =>
        setState({
          status: 'ready',
          docs: snapshot.docs.map((d) => ({ id: d.id, data: d.data() as Record<string, unknown> })),
        }),
      (error) => {
        console.warn(`Ordered query failed for ${collectionName}:`, error);
        if (!fallback) {
          setState({ status: 'loading' });
          setFallback(true);
        } else {
          setState({ status: 'ready', docs: [] });
        }
      },
    );
  }, [collectionName, fallback]);

  return state;
}

export function AdminManageScreen({
  collectionName,
  title,
  bucket,
}: {
  collectionName: string;
  title: string;
  bucket: string | null;
}) {
  const state = useCollectionDocs(collectionName);
  const [editing, setEditing] = useState<EditTarget | null>(null);
  // Sürükleme sonrası Firestore yanıtı gelene kadar yeni sıra gösterilir.
  const [optimistic, setOptimistic] = useState<{ source: LiveDoc[]; docs: LiveDoc[] } | null>(null);
  const reorderable = isReorderable(collectionName);

  const deleteDocument = async (docId: string, data: Record<string, unknown>) => {
    const confirmed = await alertConfirm({
      title: 'Silme Onayı',
      content: 'Bu veriyi silmek istediğinize emin misiniz?',
      cancelText: 'İptal',
      confirmText: 'Sil',
      isDestructive: true,
    });
    if (!confirmed) return;

    try {
      // Storage'daki görseller
      const images = Array.isArray(data.images) ? data.images.map(String) : [];
      if (images.length === 0 && typeof data.image_url === 'string') images.push(data.image_url);
      if (bucket && images.length > 0) {
        try {
          await supabase.storage.from(bucket).remove(images.map((url) => url.split('/').pop() ?? ''));
        } catch (storageError) {
          console.warn('Storage delete error:', storageError);
        }
      }

      // 1. Bağlı veriler (zincirleme silme)
      const batch = writeBatch(db);
      let hasBatchWork = false;
      const deleteWhere = async (target: string, conditions: Record<string, string>) => {
        const snapshot = await getDocs(
          query(
            collection(db, target),
            ...Object.entries(conditions).map(([field, value]) => where(field, '==', value)),
          ),
        );
        snapshot.docs.forEach((d) => {
          batch.delete(d.ref);
          hasBatchWork = true;
        });
      };
      if (collectionName === 'firmalar') {
        await deleteWhere('coupons', { companyId: docId });
        await deleteWhere('esnaf_users', { companyId: docId });
        await deleteWhere('reviews', { targetId: docId, targetType: 'company' });
      } else if (collectionName === 'gezilecek_yerler') {
        await deleteWhere('reviews', { targetId: docId, targetType: 'place' });
      }
      if (hasBatchWork) await batch.commit();

      // 2. Belgenin kendisi
      await deleteDoc(doc(db, collectionName, docId));
      showSnackbar({ message: 'Başarıyla silindi!', backgroundColor: colors.success });
    } catch (error) {
      showSnackbar({ message: `Silme hatası: ${String(error)}`, backgroundColor: colors.error });
    }
  };

  let body;
  if (state.status === 'loading') {
    body = (
      <View style={styles.center}>
        <ActivityIndicator size="large" color={colors.primary} />
      </View>
    );
  } else if (state.docs.length === 0) {
    body = (
      <View style={styles.center}>
        <Text style={typography.bodyMedium}>Henüz veri yok</Text>
      </View>
    );
  } else {
    const sorted = sortDocs(collectionName, state.docs);
    const docs = optimistic && optimistic.source === state.docs ? optimistic.docs : sorted;
    const renderItem = ({ item }: { item: LiveDoc }) => (
      <AdminListItem
        item={item}
        collectionName={collectionName}
        reorderable={reorderable}
        onEdit={() => setEditing({ docId: item.id, data: item.data })}
        onDelete={() => deleteDocument(item.id, item.data)}
      />
    );

    body = reorderable ? (
      <ReorderableList
        data={docs}
        keyExtractor={(item) => item.id}
        contentContainerStyle={styles.list}
        renderItem={renderItem}
        onReorder={async ({ from, to }) => {
          const next = reorderItems(docs, from, to);
          setOptimistic({ source: state.docs, docs: next });
          const batch = writeBatch(db);
          next.forEach((item, index) => batch.update(doc(db, collectionName, item.id), { order: index }));
          await batch.commit();
        }}
      />
    ) : (
      <FlatList data={docs} keyExtractor={(item) => item.id} contentContainerStyle={styles.list} renderItem={renderItem} />
    );
  }

  return (
    <View style={styles.container}>
      <AppBar title={title} />
      <View style={{ flex: 1 }}>{body}</View>
      <Pressable onPress={() => setEditing({ docId: null, data: null })} style={styles.fab}>
        <MaterialIcons name="add" size={24} color={colors.white} />
        <Text style={styles.fabLabel}>Ekle</Text>
      </Pressable>
      <AdminEditSheet
        target={editing}
        collectionName={collectionName}
        bucket={bucket}
        onClose={() => setEditing(null)}
      />
    </View>
  );
}

function AdminListItem({
  item,
  collectionName,
  reorderable,
  onEdit,
  onDelete,
}: {
  item: LiveDoc;
  collectionName: string;
  reorderable: boolean;
  onEdit: () => void;
  onDelete: () => void;
}) {
  const data = item.data;
  const imageUrl = typeof data.image_url === 'string' ? data.image_url : typeof data.gorsel === 'string' ? data.gorsel : '';

  return (
    <View style={styles.item}>
      {collectionName === 'surveys' ? (
        <View style={styles.surveyIcon}>
          <MaterialIcons name="assignment" size={28} color={colors.primary} />
        </View>
      ) : (
        <CachedImage imageUrl={imageUrl} width={50} height={50} borderRadius={10} />
      )}
      <View style={{ flex: 1, marginHorizontal: 16 }}>
        <Text style={[typography.bodyMedium, { fontFamily: fonts.bold }]} numberOfLines={1}>
          {displayName(data)}
        </Text>
        <ListSubtitle collectionName={collectionName} data={data} />
      </View>
      <PopupMenu
        icon="more-vert"
        iconSize={24}
        iconColor="#9E9E9E"
        items={[
          { value: 'edit', label: 'Düzenle', icon: null },
          { value: 'delete', label: 'Sil', icon: null },
        ]}
        onSelect={(value) => (value === 'edit' ? onEdit() : onDelete())}
      />
      {reorderable && <DragHandle />}
    </View>
  );
}

function DragHandle() {
  const drag = useReorderableDrag();
  return (
    <Pressable onPressIn={drag} hitSlop={8} style={{ paddingLeft: 4 }}>
      <MaterialIcons name="drag-indicator" size={24} color="#9E9E9E" />
    </Pressable>
  );
}

const pad = (n: number) => String(n).padStart(2, '0');
const isPast = (date: Date) => date.getTime() < Date.now();
const dots = (date: Date) => `${pad(date.getDate())}.${pad(date.getMonth() + 1)}.${date.getFullYear()}`;

function ListSubtitle({ collectionName, data }: { collectionName: string; data: Record<string, unknown> }) {
  switch (collectionName) {
    case 'firmalar': {
      if (data.expiry_date == null) {
        return <Text style={[styles.subtitle, { color: '#43A047', fontFamily: fonts.semiBold }]}>Bitiş: Sınırsız</Text>;
      }
      if (!isTimestamp(data.expiry_date)) return null;
      const expiry = data.expiry_date.toDate();
      const isExpired = isPast(expiry);
      return (
        <Text
          style={[
            styles.subtitle,
            { color: isExpired ? '#F44336' : '#757575', fontFamily: isExpired ? fonts.bold : fonts.regular },
          ]}>
          {`Bitiş: ${dots(expiry)}`}
        </Text>
      );
    }
    case 'esnaf_users': {
      const companyId = typeof data.companyId === 'string' ? data.companyId : '';
      const companyName = typeof data.companyName === 'string' ? data.companyName : '';
      return (
        <Text style={styles.subtitle}>{`Firma: ${companyName || companyId || 'Bağlı değil'}`}</Text>
      );
    }
    case 'coupons': {
      const isActive = data.isActive === true;
      const companyName = typeof data.companyName === 'string' ? data.companyName : '';
      const totalLimit = typeof data.total_limit === 'number' ? data.total_limit : null;
      const usedCount = typeof data.used_count === 'number' ? data.used_count : 0;
      let sub = `Firma: ${companyName || 'Bilinmiyor'} • ${isActive ? '✅ Aktif' : '❌ Pasif'}`;
      if (isTimestamp(data.expiry_date)) sub += `\nBitiş: ${dots(data.expiry_date.toDate())}`;
      if (totalLimit != null) sub += ` • Limit: ${usedCount}/${totalLimit}`;
      return <Text style={[styles.subtitle, { color: isActive ? '#388E3C' : '#F44336' }]}>{sub}</Text>;
    }
    case 'otobus_saatleri': {
      const str = (key: string) => (typeof data[key] === 'string' ? (data[key] as string) : '');
      const hergun = str('saatler_hergun');
      return (
        <View>
          {hergun.length > 0 && (
            <View style={styles.everyDay}>
              <TimeGroup label="HER GÜN" times={hergun} color="#1565C0" />
            </View>
          )}
          <TimeGroup label="HAFTA İÇİ" times={str('saatler_haftaici')} color="#616161" />
          <TimeGroup label="CUMARTESİ" times={str('saatler_cumartesi')} color="#EF6C00" />
          <TimeGroup label="PAZAR" times={str('saatler_pazar')} color="#C62828" />
        </View>
      );
    }
    case 'surveys': {
      const isActive = data.isActive === true;
      const url = typeof data.url === 'string' ? data.url : '';
      return (
        <Text style={[styles.subtitle, { color: isActive ? '#388E3C' : '#F44336' }]}>
          {`Durum: ${isActive ? '✅ Aktif' : '❌ Pasif'}\nBağlantı: ${url}`}
        </Text>
      );
    }
    default:
      return null;
  }
}

function TimeGroup({ label, times, color }: { label: string; times: string; color: string }) {
  if (!times) return null;
  const list = times
    .split(',')
    .filter((t) => t)
    .sort();
  return (
    <View>
      <Text style={[styles.groupLabel, { color }]}>{label}</Text>
      <View style={styles.timeChips}>
        {list.map((time, index) => (
          <View key={`${time}-${index}`} style={[styles.timeChip, { backgroundColor: `${color}1A`, borderColor: `${color}4D` }]}>
            <Text style={[styles.timeChipText, { color }]}>{time}</Text>
          </View>
        ))}
      </View>
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
  list: {
    padding: 16,
    paddingBottom: 96,
  },
  item: {
    marginBottom: 12,
    paddingHorizontal: 12,
    paddingVertical: 12,
    flexDirection: 'row',
    alignItems: 'center',
    borderRadius: 16,
    backgroundColor: colors.white,
    shadowColor: '#000000',
    shadowOpacity: 0.04,
    shadowRadius: 8,
    shadowOffset: { width: 0, height: 2 },
    elevation: 1,
  },
  surveyIcon: {
    width: 50,
    height: 50,
    alignItems: 'center',
    justifyContent: 'center',
    borderRadius: 10,
    backgroundColor: 'rgba(76, 175, 80, 0.1)',
  },
  subtitle: {
    fontFamily: fonts.regular,
    fontSize: 12,
    color: colors.textSecondary,
  },
  everyDay: {
    marginTop: 8,
    padding: 8,
    borderRadius: 8,
    borderWidth: 1,
    borderColor: 'rgba(33, 150, 243, 0.2)',
    backgroundColor: 'rgba(33, 150, 243, 0.05)',
  },
  groupLabel: {
    marginTop: 8,
    marginBottom: 4,
    fontFamily: fonts.bold,
    fontSize: 11,
  },
  timeChips: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 4,
  },
  timeChip: {
    paddingHorizontal: 6,
    paddingVertical: 2,
    borderRadius: 4,
    borderWidth: 1,
  },
  timeChipText: {
    fontFamily: fonts.semiBold,
    fontSize: 10,
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
    shadowOpacity: 0.25,
    shadowRadius: 6,
    shadowOffset: { width: 0, height: 3 },
    elevation: 6,
  },
  fabLabel: {
    marginLeft: 8,
    fontFamily: fonts.medium,
    fontSize: 14,
    color: colors.white,
  },
});
