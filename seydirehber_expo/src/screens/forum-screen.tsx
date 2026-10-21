import { MaterialIcons } from '@expo/vector-icons';
import { type Href, router } from 'expo-router';
import { useState } from 'react';
import {
  ActivityIndicator,
  FlatList,
  Keyboard,
  Modal,
  Pressable,
  RefreshControl,
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  View,
} from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';

import { AppBar } from '@/components/app-bar';
import { useIsGuest } from '@/features/auth/auth-store';
import { useIsAdmin } from '@/features/auth/admin-permissions';
import { ForumPostCard } from '@/features/forum/forum-post-card';
import { useForumFilterStore, useForumPosts, useMyForumPosts } from '@/features/forum/forum-service';
import { FORUM_CATEGORIES } from '@/features/forum/forum-types';
import { haptics } from '@/services/haptics';
import { colors, fonts, typography } from '@/theme';

// Flutter lib/features/forum/screens/forum_screen.dart karşılığı.
export function ForumScreen() {
  const insets = useSafeAreaInsets();
  const posts = useForumPosts();
  const myPosts = useMyForumPosts();
  const isGuest = useIsGuest();
  const isAdmin = useIsAdmin();
  const category = useForumFilterStore((s) => s.category);
  const search = useForumFilterStore((s) => s.search);
  const [loginDialogVisible, setLoginDialogVisible] = useState(false);
  // Flutter: arama kutusu her girişte boş açılır ama filtre değeri (global) korunur.
  const [searchText, setSearchText] = useState('');
  const [refreshing, setRefreshing] = useState(false);

  let body;
  if (posts.status === 'loading') {
    body = (
      <View style={styles.center}>
        <ActivityIndicator size="large" color={colors.primary} />
      </View>
    );
  } else if (posts.status === 'error') {
    body = (
      <View style={styles.center}>
        <MaterialIcons name="error-outline" size={40} color={colors.error} />
        <Text style={[typography.bodyMedium, { marginTop: 12 }]}>Bir hata oluştu</Text>
        <Pressable
          style={styles.textButton}
          onPress={() => useForumFilterStore.setState((s) => ({ retryCount: s.retryCount + 1 }))}>
          <Text style={styles.textButtonLabel}>Yeniden Dene</Text>
        </Pressable>
      </View>
    );
  } else if (posts.items.length === 0) {
    body = (
      <View style={styles.center}>
        <View style={styles.emptyIcon}>
          <MaterialIcons name="forum" size={48} color="rgba(76, 175, 80, 0.5)" />
        </View>
        <Text style={[typography.heading3, { marginTop: 24 }]}>Henüz gönderi yok</Text>
        <Text style={[typography.bodyMedium, { marginTop: 8, color: colors.textLight }]}>
          Sessizliği ilk bozan sen ol!
        </Text>
      </View>
    );
  } else {
    body = (
      <FlatList
        data={posts.items}
        keyExtractor={(post) => post.id}
        contentContainerStyle={{ padding: 16, paddingBottom: 96 }}
        keyboardShouldPersistTaps="handled"
        renderItem={({ item }) => <ForumPostCard post={item} isAdmin={isAdmin} />}
        refreshControl={
          // Liste canlı dinlendiği için yenileme sadece görsel geri bildirim.
          <RefreshControl
            refreshing={refreshing}
            onRefresh={() => {
              setRefreshing(true);
              setTimeout(() => setRefreshing(false), 400);
            }}
            colors={[colors.primary]}
            tintColor={colors.primary}
          />
        }
      />
    );
  }

  return (
    <View style={styles.container}>
      <AppBar
        title="Forum"
        titleContent={
          <>
            <View style={styles.titleIcon}>
              <MaterialIcons name="forum" size={18} color={colors.primary} />
            </View>
            <Text style={[typography.appBarTitle, { marginLeft: 10 }]}>Forum</Text>
          </>
        }
        actions={
          !isGuest && myPosts.status === 'success' && myPosts.items.length > 0 ? (
            <Pressable
              style={styles.myPostsButton}
              onPress={() => {
                haptics.selection();
                router.push('/forum/my-posts' as Href);
              }}>
              <MaterialIcons name="person" size={16} color={colors.primary} />
              <Text style={styles.myPostsText}>Gönderilerim</Text>
            </Pressable>
          ) : null
        }
      />
      <View style={styles.searchWrap}>
        <View style={styles.search}>
          <MaterialIcons name="search" size={24} color={colors.textLight} />
          <TextInput
            value={searchText}
            onChangeText={(value) => {
              setSearchText(value);
              useForumFilterStore.setState({ search: value });
            }}
            placeholder="Forumda ara..."
            placeholderTextColor={colors.textLight}
            style={styles.searchInput}
          />
          {search ? (
            <Pressable
              hitSlop={8}
              onPress={() => {
                haptics.selection();
                setSearchText('');
                useForumFilterStore.setState({ search: '' });
                Keyboard.dismiss();
              }}>
              <MaterialIcons name="clear" size={20} color={colors.textLight} />
            </Pressable>
          ) : null}
        </View>
      </View>

      <ScrollView
        horizontal
        showsHorizontalScrollIndicator={false}
        style={{ height: 52, flexGrow: 0 }}
        contentContainerStyle={styles.chips}>
        {FORUM_CATEGORIES.map((cat) => {
          const selected = category === cat.value;
          return (
            <Pressable
              key={cat.value}
              onPress={() => {
                haptics.selection();
                useForumFilterStore.setState({ category: cat.value });
              }}
              style={[
                styles.chip,
                {
                  backgroundColor: selected ? colors.primarySurface : colors.white,
                  borderColor: selected ? colors.primary : colors.border,
                },
              ]}>
              {selected && <MaterialIcons name="check" size={16} color={colors.primary} />}
              <Text
                style={[
                  typography.bodySmall,
                  { color: selected ? colors.primary : colors.textSecondary, fontFamily: selected ? fonts.bold : fonts.regular },
                ]}>
                {`${cat.emoji} ${cat.label}`}
              </Text>
            </Pressable>
          );
        })}
      </ScrollView>

      <View style={{ flex: 1 }}>{body}</View>

      <Pressable
        onPress={() => {
          haptics.selection();
          if (isGuest) setLoginDialogVisible(true);
          else router.push('/forum/create' as Href);
        }}
        style={[styles.fab, { bottom: 16 + insets.bottom }]}>
        <MaterialIcons name="add-comment" size={22} color={colors.white} />
        <Text style={[typography.button, { fontFamily: fonts.bold }]}>Yeni Gönderi</Text>
      </Pressable>

      <Modal
        visible={loginDialogVisible}
        transparent
        animationType="fade"
        onRequestClose={() => setLoginDialogVisible(false)}>
        <Pressable style={styles.barrier} onPress={() => setLoginDialogVisible(false)}>
          <Pressable style={styles.dialog}>
            <Text style={typography.heading3}>Giriş Gerekli</Text>
            <Text style={[typography.bodyMedium, { marginTop: 16 }]}>Gönderi paylaşmak için giriş yapmanız gerekiyor.</Text>
            <Pressable style={styles.dialogAction} onPress={() => setLoginDialogVisible(false)}>
              <Text style={styles.textButtonLabel}>Kapat</Text>
            </Pressable>
          </Pressable>
        </Pressable>
      </Modal>
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
  titleIcon: {
    padding: 7,
    borderRadius: 10,
    backgroundColor: colors.primarySurface,
  },
  myPostsButton: {
    marginRight: 8,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    paddingHorizontal: 12,
    paddingVertical: 8,
    borderRadius: 12,
    backgroundColor: colors.primarySurface,
  },
  myPostsText: {
    fontFamily: fonts.bold,
    fontSize: 13,
    color: colors.primary,
  },
  searchWrap: {
    paddingHorizontal: 16,
    paddingVertical: 8,
  },
  search: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
    paddingHorizontal: 12,
    borderRadius: 16,
    backgroundColor: colors.white,
    shadowColor: '#000000',
    shadowOpacity: 0.03,
    shadowRadius: 10,
    shadowOffset: { width: 0, height: 4 },
    elevation: 1,
  },
  searchInput: {
    ...typography.bodyMedium,
    flex: 1,
    paddingVertical: 14,
  },
  chips: {
    paddingHorizontal: 16,
    paddingVertical: 8,
    gap: 8,
    alignItems: 'center',
  },
  chip: {
    height: 32,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    paddingHorizontal: 12,
    borderRadius: 8,
    borderWidth: 1,
  },
  emptyIcon: {
    padding: 24,
    borderRadius: 999,
    backgroundColor: colors.primarySurface,
  },
  textButton: {
    marginTop: 8,
    paddingHorizontal: 12,
    paddingVertical: 10,
  },
  textButtonLabel: {
    fontFamily: fonts.medium,
    fontSize: 14,
    color: colors.primary,
  },
  fab: {
    position: 'absolute',
    right: 16,
    height: 56,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    paddingHorizontal: 20,
    borderRadius: 30,
    backgroundColor: colors.primary,
    shadowColor: colors.primary,
    shadowOpacity: 0.3,
    shadowRadius: 16,
    shadowOffset: { width: 0, height: 8 },
    elevation: 6,
  },
  barrier: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    paddingHorizontal: 40,
    backgroundColor: colors.barrier,
  },
  dialog: {
    width: '100%',
    padding: 24,
    borderRadius: 20,
    backgroundColor: colors.white,
  },
  dialogAction: {
    alignSelf: 'flex-end',
    marginTop: 24,
    paddingHorizontal: 12,
    paddingVertical: 10,
  },
});
