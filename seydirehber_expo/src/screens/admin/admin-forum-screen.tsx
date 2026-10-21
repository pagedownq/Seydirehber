import { MaterialIcons } from '@expo/vector-icons';
import { useState } from 'react';
import { ActivityIndicator, FlatList, Pressable, StyleSheet, Text, View } from 'react-native';

import { AppBar } from '@/components/app-bar';
import { showSnackbar } from '@/components/snackbar';
import {
  approvePost,
  approveReply,
  deletePost,
  deleteReply,
  type ListState,
  useHiddenForumPosts,
  useHiddenForumReplies,
} from '@/features/forum/forum-service';
import type { ForumPost, ForumReply } from '@/features/forum/forum-types';
import { colors, fonts, typography } from '@/theme';
import { alertConfirm } from '@/utils/alert-confirm';

// Flutter lib/features/admin/screens/admin_forum_screen.dart karşılığı: gizlenmiş gönderi ve yanıtlar.
export function AdminForumScreen() {
  const [tab, setTab] = useState<0 | 1>(0);

  return (
    <View style={styles.container}>
      <AppBar title="Forum Moderasyonu" />
      <View style={styles.tabBar}>
        {(['Gönderiler', 'Yanıtlar'] as const).map((label, index) => {
          const selected = tab === index;
          return (
            <Pressable key={label} style={styles.tab} onPress={() => setTab(index as 0 | 1)}>
              <Text style={[styles.tabLabel, { color: selected ? colors.primary : colors.textLight }]}>{label}</Text>
              <View style={[styles.indicator, selected && { backgroundColor: colors.primary }]} />
            </Pressable>
          );
        })}
      </View>
      {tab === 0 ? <HiddenPostsTab /> : <HiddenRepliesTab />}
    </View>
  );
}

const confirm = (message: string) =>
  alertConfirm({ title: 'Emin misiniz?', content: message, confirmText: 'Evet, Sil', isDestructive: true });

function ModerationList<T extends { id: string }>({
  state,
  emptyLabel,
  render,
}: {
  state: ListState<T>;
  emptyLabel: string;
  render: (item: T) => React.ReactElement;
}) {
  if (state.status === 'loading') {
    return (
      <View style={styles.center}>
        <ActivityIndicator size="large" color={colors.primary} />
      </View>
    );
  }
  if (state.status === 'error') {
    return (
      <View style={styles.center}>
        <Text style={typography.bodyMedium}>{`Hata: ${String(state.error)}`}</Text>
      </View>
    );
  }
  if (state.items.length === 0) {
    return (
      <View style={styles.center}>
        <MaterialIcons name="verified" size={56} color="#E0E0E0" />
        <Text style={[typography.bodyMedium, { marginTop: 16, color: colors.textLight }]}>{emptyLabel}</Text>
      </View>
    );
  }
  return (
    <FlatList
      data={state.items}
      keyExtractor={(item) => item.id}
      contentContainerStyle={{ padding: 16 }}
      renderItem={({ item }) => render(item)}
    />
  );
}

function HiddenPostsTab() {
  const posts = useHiddenForumPosts();
  return (
    <ModerationList<ForumPost>
      state={posts}
      emptyLabel="İncelenecek gönderi yok 🎉"
      render={(post) => (
        <ModerationTile
          variant="post"
          reportCount={post.reportCount}
          displayName={post.displayName}
          title={post.title}
          content={post.content}
          onApprove={async () => {
            await approvePost(post.id);
            showSnackbar({ message: 'Gönderi onaylandı ve yayına alındı.' });
          }}
          onDelete={async () => {
            if (!(await confirm('Gönderiyi kalıcı olarak silmek istediğinizden emin misiniz? Tüm yanıtlar da silinecek.'))) return;
            await deletePost(post.id);
            showSnackbar({ message: 'Gönderi kalıcı olarak silindi.' });
          }}
        />
      )}
    />
  );
}

function HiddenRepliesTab() {
  const replies = useHiddenForumReplies();
  return (
    <ModerationList<ForumReply>
      state={replies}
      emptyLabel="İncelenecek yanıt yok 🎉"
      render={(reply) => (
        <ModerationTile
          variant="reply"
          reportCount={reply.reportCount}
          displayName={reply.displayName}
          content={reply.content}
          onApprove={async () => {
            await approveReply(reply.id);
            showSnackbar({ message: 'Yanıt onaylandı ve yayına alındı.' });
          }}
          onDelete={async () => {
            if (!(await confirm('Yanıtı kalıcı olarak silmek istediğinizden emin misiniz?'))) return;
            await deleteReply(reply.id, reply.postId);
            showSnackbar({ message: 'Yanıt kalıcı olarak silindi.' });
          }}
        />
      )}
    />
  );
}

function ModerationTile({
  variant,
  reportCount,
  displayName,
  title,
  content,
  onApprove,
  onDelete,
}: {
  variant: 'post' | 'reply';
  reportCount: number;
  displayName: string;
  title?: string;
  content: string;
  onApprove: () => void;
  onDelete: () => void;
}) {
  const accent = variant === 'post' ? colors.error : colors.warning;
  const tint = variant === 'post' ? 'rgba(229, 57, 53, ' : 'rgba(255, 167, 38, ';

  return (
    <View style={[styles.tile, { borderColor: `${tint}0.3)` }, variant === 'post' && styles.tileShadow]}>
      <View style={styles.row}>
        <View style={[styles.badge, { backgroundColor: `${tint}0.1)` }]}>
          <Text style={[typography.caption, { fontFamily: fonts.bold, color: accent }]}>{`${reportCount} Rapor`}</Text>
        </View>
        {/* Gerçek kullanıcı kimliği (admin görür) */}
        <Text style={[typography.caption, styles.user]} numberOfLines={1}>
          {`Kullanıcı: ${displayName}`}
        </Text>
      </View>
      {title != null && <Text style={[typography.bodyMedium, styles.title]}>{title}</Text>}
      <Text style={[typography.bodySmall, styles.content]} numberOfLines={variant === 'post' ? 4 : 5}>
        {content}
      </Text>
      <View style={[styles.row, { marginTop: 14 }]}>
        <Pressable onPress={onApprove} style={[styles.button, styles.approve]}>
          <MaterialIcons name="check-circle-outline" size={16} color={colors.success} />
          <Text style={[styles.buttonText, { color: colors.success }]}>Onayla</Text>
        </Pressable>
        <View style={{ width: 10 }} />
        <Pressable onPress={onDelete} style={[styles.button, { backgroundColor: colors.error }]}>
          <MaterialIcons name="delete-outline" size={16} color={colors.white} />
          <Text style={[styles.buttonText, { color: colors.white }]}>Kalıcı Sil</Text>
        </Pressable>
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
  tabBar: {
    flexDirection: 'row',
    backgroundColor: colors.white,
    borderBottomWidth: 1,
    borderBottomColor: '#E0E0E0',
  },
  tab: {
    flex: 1,
    height: 48,
    alignItems: 'center',
    justifyContent: 'flex-end',
  },
  tabLabel: {
    marginBottom: 12,
    fontFamily: fonts.medium,
    fontSize: 14,
  },
  indicator: {
    alignSelf: 'stretch',
    height: 3,
    marginHorizontal: 16,
    borderTopLeftRadius: 3,
    borderTopRightRadius: 3,
    backgroundColor: 'transparent',
  },
  row: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  tile: {
    marginBottom: 12,
    padding: 16,
    borderRadius: 16,
    borderWidth: 1,
    backgroundColor: colors.white,
  },
  tileShadow: {
    shadowColor: '#000000',
    shadowOpacity: 0.04,
    shadowRadius: 8,
    shadowOffset: { width: 0, height: 2 },
    elevation: 1,
  },
  badge: {
    paddingHorizontal: 10,
    paddingVertical: 4,
    borderRadius: 8,
  },
  user: {
    flex: 1,
    marginLeft: 8,
    color: colors.textSecondary,
  },
  title: {
    marginTop: 10,
    fontFamily: fonts.bold,
  },
  content: {
    marginTop: 6,
    lineHeight: 16.8,
    color: colors.textSecondary,
  },
  button: {
    flex: 1,
    height: 40,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 8,
    borderRadius: 10,
  },
  approve: {
    borderWidth: 1,
    borderColor: colors.success,
  },
  buttonText: {
    fontFamily: fonts.medium,
    fontSize: 14,
  },
});
