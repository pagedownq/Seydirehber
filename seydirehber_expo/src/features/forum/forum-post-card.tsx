import { MaterialIcons } from '@expo/vector-icons';
import { type Href, router } from 'expo-router';
import { Pressable, StyleSheet, Text, View } from 'react-native';

import { LinkableText } from '@/components/linkable-text';
import { CategoryChip, ForumAvatar, PostActionsMenu } from '@/features/forum/forum-parts';
import { authorLabel, type ForumPost, timeAgo } from '@/features/forum/forum-types';
import { haptics } from '@/services/haptics';
import { colors, fonts, typography } from '@/theme';

// Flutter lib/features/forum/widgets/forum_post_card.dart karşılığı.
export function ForumPostCard({ post, isAdmin = false }: { post: ForumPost; isAdmin?: boolean }) {
  const hasVotes = post.helpfulVoterIds.length > 0 || post.unhelpfulVoterIds.length > 0;

  return (
    <Pressable
      onPress={() => {
        haptics.selection();
        router.push(`/forum/${post.id}` as Href);
      }}
      style={styles.card}>
      <View style={styles.header}>
        <ForumAvatar item={post} radius={16} />
        <View style={styles.headerTexts}>
          <Text style={styles.author}>{authorLabel(post, isAdmin)}</Text>
          <Text style={typography.caption}>
            {timeAgo(post.createdAt)}
            {post.isEdited ? ' (Düzenlendi)' : ''}
          </Text>
        </View>
        <CategoryChip category={post.category} />
        <View style={{ width: 4 }} />
        <PostActionsMenu post={post} isAdmin={isAdmin} variant="card" />
      </View>

      <Text style={styles.title} numberOfLines={2}>
        {post.title}
      </Text>
      <LinkableText text={post.content} style={styles.content} numberOfLines={3} />

      <View style={styles.footer}>
        <MaterialIcons name="chat-bubble-outline" size={14} color={colors.textLight} />
        <Text style={typography.caption}>{post.replyCount} yanıt</Text>
        <View style={{ flex: 1 }} />
        {hasVotes && (
          <>
            <MaterialIcons name="thumb-up-off-alt" size={14} color={colors.primary} />
            <Text style={[typography.caption, styles.voteText, { color: colors.primary }]}>
              {post.helpfulVoterIds.length}
            </Text>
            <View style={{ width: 8 }} />
            <MaterialIcons name="thumb-down-off-alt" size={14} color={colors.error} />
            <Text style={[typography.caption, styles.voteText, { color: colors.error }]}>
              {post.unhelpfulVoterIds.length}
            </Text>
          </>
        )}
      </View>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  card: {
    marginBottom: 12,
    borderRadius: 18,
    backgroundColor: colors.white,
    shadowColor: '#000000',
    shadowOpacity: 0.05,
    shadowRadius: 10,
    shadowOffset: { width: 0, height: 3 },
    elevation: 2,
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingLeft: 16,
    paddingRight: 8,
    paddingTop: 14,
    paddingBottom: 4,
  },
  headerTexts: {
    flex: 1,
    marginLeft: 10,
  },
  author: {
    ...typography.bodySmall,
    fontFamily: fonts.semiBold,
    fontSize: 12,
    color: colors.textPrimary,
  },
  title: {
    ...typography.bodyMedium,
    paddingHorizontal: 16,
    paddingVertical: 4,
    fontFamily: fonts.bold,
  },
  content: {
    ...typography.bodySmall,
    paddingHorizontal: 16,
    paddingTop: 2,
    paddingBottom: 14,
    lineHeight: 18,
    color: colors.textSecondary,
  },
  footer: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    paddingHorizontal: 16,
    paddingVertical: 10,
    borderBottomLeftRadius: 18,
    borderBottomRightRadius: 18,
    backgroundColor: colors.background,
  },
  voteText: {
    fontFamily: fonts.semiBold,
  },
});
