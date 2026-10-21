import { MaterialIcons } from '@expo/vector-icons';
import { Keyboard, Pressable, StyleSheet, Text, View } from 'react-native';

import { LinkableText } from '@/components/linkable-text';
import { showSnackbar } from '@/components/snackbar';
import { useUser } from '@/features/auth/auth-store';
import { ForumAvatar, ReplyActionsMenu } from '@/features/forum/forum-parts';
import { toggleLikeReply } from '@/features/forum/forum-service';
import { authorLabel, type ForumReply, timeAgo } from '@/features/forum/forum-types';
import { colors, fonts, typography } from '@/theme';

// Flutter lib/features/forum/widgets/forum_reply_card.dart karşılığı.
// `blurred`: misafire yanıtlar bulanık gösterilir (Flutter ImageFiltered). Native bulanıklık modülü
// eklememek için metinler saydam yapılıp gölgeleriyle bulanık görünüm verilir.
export function ForumReplyCard({
  reply,
  isAdmin = false,
  blurred = false,
}: {
  reply: ForumReply;
  isAdmin?: boolean;
  blurred?: boolean;
}) {
  const userId = useUser()?.uid ?? null;
  const isLiked = userId != null && reply.likedUserIds.includes(userId);
  const likeColor = isLiked ? colors.primary : colors.textLight;
  const blur = blurred ? styles.blurredText : null;

  return (
    <View style={[styles.card, blurred && { opacity: 0.6 }]} pointerEvents={blurred ? 'none' : 'auto'}>
      <View style={styles.header}>
        <ForumAvatar item={reply} radius={15} />
        <View style={styles.headerTexts}>
          <Text style={[styles.author, blur]}>{authorLabel(reply, isAdmin)}</Text>
          <Text style={[typography.caption, blur]}>
            {timeAgo(reply.createdAt)}
            {reply.isEdited ? ' (Düzenlendi)' : ''}
          </Text>
        </View>
        {!blurred && <ReplyActionsMenu reply={reply} isAdmin={isAdmin} onOpen={Keyboard.dismiss} />}
      </View>
      {blurred ? (
        <Text style={[styles.content, blur]}>{reply.content}</Text>
      ) : (
        <LinkableText text={reply.content} style={styles.content} />
      )}
      <View style={styles.footer}>
        <Pressable
          onPress={() => {
            if (!userId) {
              showSnackbar({ message: 'Yanıtı beğenmek için giriş yapmalısınız.', floating: false });
              return;
            }
            toggleLikeReply(reply.id, userId, isLiked).catch(() => {});
          }}
          style={[styles.like, isLiked && { backgroundColor: 'rgba(76, 175, 80, 0.08)' }]}>
          <MaterialIcons name={isLiked ? 'favorite' : 'favorite-border'} size={16} color={likeColor} />
          <Text style={[typography.caption, { color: likeColor, fontFamily: fonts.bold }, blur]}>
            {reply.likedUserIds.length}
          </Text>
        </Pressable>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  card: {
    marginBottom: 10,
    padding: 14,
    borderRadius: 16,
    borderWidth: 1,
    borderColor: colors.border,
    backgroundColor: colors.white,
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  headerTexts: {
    flex: 1,
    marginLeft: 8,
  },
  author: {
    ...typography.bodySmall,
    fontFamily: fonts.semiBold,
    fontSize: 12,
    color: colors.textPrimary,
  },
  content: {
    ...typography.bodySmall,
    marginTop: 8,
    lineHeight: 18,
    color: colors.textSecondary,
  },
  footer: {
    marginTop: 8,
    flexDirection: 'row',
    justifyContent: 'flex-end',
  },
  like: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    paddingHorizontal: 10,
    paddingVertical: 5,
    borderRadius: 12,
  },
  blurredText: {
    color: 'transparent',
    textShadowColor: 'rgba(0, 0, 0, 0.45)',
    textShadowOffset: { width: 0, height: 0 },
    textShadowRadius: 8,
  },
});
