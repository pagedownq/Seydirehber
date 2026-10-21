import { MaterialIcons } from '@expo/vector-icons';
import { ActivityIndicator, FlatList, StyleSheet, Text, View } from 'react-native';

import { AppBar } from '@/components/app-bar';
import { ForumPostCard } from '@/features/forum/forum-post-card';
import { useMyForumPosts } from '@/features/forum/forum-service';
import { colors, typography } from '@/theme';

// Flutter lib/features/forum/screens/my_forum_posts_screen.dart karşılığı.
export function MyForumPostsScreen() {
  const posts = useMyForumPosts();

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
        <Text>Hata: {String(posts.error)}</Text>
      </View>
    );
  } else if (posts.items.length === 0) {
    body = (
      <View style={styles.center}>
        <View style={styles.emptyIcon}>
          <MaterialIcons name="post-add" size={48} color="rgba(76, 175, 80, 0.5)" />
        </View>
        <Text style={[typography.heading3, { marginTop: 24 }]}>Henüz gönderiniz yok</Text>
      </View>
    );
  } else {
    body = (
      <FlatList
        data={posts.items}
        keyExtractor={(post) => post.id}
        contentContainerStyle={{ padding: 16 }}
        renderItem={({ item }) => <ForumPostCard post={item} />}
      />
    );
  }

  return (
    <View style={styles.container}>
      <AppBar title="Gönderilerim" />
      <View style={{ flex: 1 }}>{body}</View>
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
  emptyIcon: {
    padding: 24,
    borderRadius: 999,
    backgroundColor: colors.primarySurface,
  },
});
