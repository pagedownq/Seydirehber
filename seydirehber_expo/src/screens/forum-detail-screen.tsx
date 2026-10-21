import { MaterialIcons } from '@expo/vector-icons';
import { type Href, router } from 'expo-router';
import { useEffect, useRef, useState } from 'react';
import {
  ActivityIndicator,
  Keyboard,
  KeyboardAvoidingView,
  Platform,
  Pressable,
  ScrollView,
  StyleSheet,
  Switch,
  Text,
  TextInput,
  View,
} from 'react-native';
import Animated, { FadeInDown } from 'react-native-reanimated';
import { useSafeAreaInsets } from 'react-native-safe-area-context';

import { AppBar } from '@/components/app-bar';
import { LinkableText } from '@/components/linkable-text';
import { showSnackbar } from '@/components/snackbar';
import { useIsGuest, useUser } from '@/features/auth/auth-store';
import { useIsAdmin } from '@/features/auth/admin-permissions';
import { ForumAvatar, leaveDetail, PostActionsMenu } from '@/features/forum/forum-parts';
import { ForumReplyCard } from '@/features/forum/forum-reply-card';
import { createReply, useForumPost, useForumReplies, votePost } from '@/features/forum/forum-service';
import { authorLabel, type ForumPost, timeAgo } from '@/features/forum/forum-types';
import { haptics } from '@/services/haptics';
import { colors, fonts, typography } from '@/theme';

// Flutter lib/features/forum/screens/forum_detail_screen.dart karşılığı.
const STICKY_DELAY_MS = 10_000;

export function ForumDetailScreen({ postId }: { postId: string }) {
  const { status, post } = useForumPost(postId);
  const isAdmin = useIsAdmin();

  let body;
  if (status === 'loading') {
    body = (
      <View style={styles.center}>
        <ActivityIndicator size="large" color={colors.primary} />
      </View>
    );
  } else if (status === 'error') {
    body = (
      <View style={styles.center}>
        <Text>Gönderi yüklenemedi</Text>
      </View>
    );
  } else if (!post) {
    body = (
      <View style={styles.center}>
        <Text style={typography.bodyMedium}>Gönderi bulunamadı.</Text>
      </View>
    );
  } else if (post.isHidden && !isAdmin) {
    body = <HiddenContent />;
  } else {
    body = <PostDetail post={post} isAdmin={isAdmin} />;
  }

  return (
    <View style={styles.container}>
      <AppBar
        title="Gönderi"
        actions={
          isAdmin && post ? (
            <View style={[styles.reportChip, { backgroundColor: post.reportCount > 0 ? colors.error : '#9E9E9E' }]}>
              <Text style={styles.reportChipText}>{post.reportCount} rapor</Text>
            </View>
          ) : null
        }
      />
      <View style={{ flex: 1 }}>{body}</View>
    </View>
  );
}

function PostDetail({ post, isAdmin }: { post: ForumPost; isAdmin: boolean }) {
  const insets = useSafeAreaInsets();
  const user = useUser();
  const isGuest = useIsGuest();
  const replies = useForumReplies(post.id);
  const userId = user?.uid ?? null;

  const [replyText, setReplyText] = useState('');
  const [anonymousReply, setAnonymousReply] = useState(false);
  const [submitting, setSubmitting] = useState(false);
  const [hasVoted, setHasVoted] = useState(false);
  const [showSticky, setShowSticky] = useState(false);
  const hasVotedRef = useRef(false);

  const alreadyVoted = userId != null && (post.helpfulVoterIds.includes(userId) || post.unhelpfulVoterIds.includes(userId));

  // 10 sn sonra oy verilmediyse "yararlı oldu mu?" çubuğu çıkar.
  useEffect(() => {
    const timer = setTimeout(() => {
      if (!hasVotedRef.current) setShowSticky(true);
    }, STICKY_DELAY_MS);
    return () => clearTimeout(timer);
  }, []);

  const vote = (isHelpful: boolean) => {
    hasVotedRef.current = true;
    setHasVoted(true);
    setShowSticky(false);
    if (user) votePost(post.id, user.uid, isHelpful).catch(() => {});
    showSnackbar({ message: 'Geri bildiriminiz için teşekkürler!', floating: false });
  };

  const submitReply = async () => {
    const content = replyText.trim();
    if (!content) return;
    if (!user || isGuest) {
      showSnackbar({ message: 'Yanıt yazabilmek için giriş yapmanız gerekiyor.', floating: false });
      return;
    }
    setSubmitting(true);
    try {
      await createReply({
        postId: post.id,
        userId: user.uid,
        displayName: user.displayName ?? 'Kullanıcı',
        photoUrl: user.photoURL ?? null,
        isAnonymous: anonymousReply,
        content,
      });
      setReplyText('');
      setAnonymousReply(false);
      Keyboard.dismiss();
    } catch (error) {
      showSnackbar({
        message: `Yanıt gönderilemedi: ${error instanceof Error ? error.message : String(error)}`,
        floating: false,
      });
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <KeyboardAvoidingView style={{ flex: 1 }} behavior={Platform.OS === 'ios' ? 'padding' : undefined}>
      <ScrollView
        contentContainerStyle={{ padding: 16 }}
        keyboardShouldPersistTaps="handled"
        scrollEventThrottle={64}
        onScroll={(event) => {
          const { contentOffset, contentSize, layoutMeasurement } = event.nativeEvent;
          const remaining = contentSize.height - layoutMeasurement.height - contentOffset.y;
          // Alttaki oylama kutusuna yaklaşınca yapışkan çubuk gizlenir.
          if (remaining < 300 && showSticky) setShowSticky(false);
        }}>
        <View style={styles.postCard}>
          <View style={styles.authorRow}>
            <ForumAvatar item={post} radius={20} />
            <View style={{ flex: 1, marginLeft: 10 }}>
              <Text style={styles.author}>{authorLabel(post, isAdmin)}</Text>
              <Text style={typography.caption}>
                {timeAgo(post.createdAt)}
                {post.isEdited ? ' (Düzenlendi)' : ''}
              </Text>
            </View>
            <PostActionsMenu post={post} isAdmin={isAdmin} variant="detail" onLeave={leaveDetail} />
          </View>
          <Text style={[typography.heading3, { marginTop: 14 }]}>{post.title}</Text>
          <LinkableText text={post.content} style={styles.content} />
          <View style={styles.metaRow}>
            <View style={styles.categoryBadge}>
              <Text style={styles.categoryText}>{post.category}</Text>
            </View>
            <MaterialIcons name="chat-bubble-outline" size={13} color={colors.textLight} style={{ marginLeft: 10 }} />
            <Text style={[typography.caption, { marginLeft: 4 }]}>{post.replyCount} yanıt</Text>
          </View>
        </View>

        <FeedbackBox voted={hasVoted || alreadyVoted} onVote={vote} />
        <View style={{ height: 20 }} />

        {post.replyCount > 0 && <Text style={[typography.heading3, styles.repliesTitle]}>Yanıtlar</Text>}

        {replies.status === 'loading' && (
          <View style={{ padding: 20, alignItems: 'center' }}>
            <ActivityIndicator color={colors.primary} />
          </View>
        )}
        {replies.status === 'error' && <Text>Yanıtlar yüklenemedi: {String(replies.error)}</Text>}
        {replies.status === 'success' &&
          (replies.items.length === 0 ? (
            <Text style={styles.noReplies}>Henüz yanıt yok.</Text>
          ) : isGuest ? (
            <View style={styles.guestWrap}>
              {replies.items.map((reply) => (
                <ForumReplyCard key={reply.id} reply={reply} isAdmin={isAdmin} blurred />
              ))}
              <View style={styles.guestOverlay}>
                <View style={styles.guestBox}>
                  <MaterialIcons name="lock-outline" size={48} color={colors.primary} />
                  <Text style={styles.guestTitle}>Yanıtları görebilmek için giriş yapmalısınız</Text>
                  <Pressable
                    style={styles.guestButton}
                    onPress={() => {
                      haptics.selection();
                      router.navigate('/settings' as Href);
                    }}>
                    <Text style={[typography.button, { fontFamily: fonts.bold, fontSize: 15 }]}>Giriş Yap</Text>
                  </Pressable>
                </View>
              </View>
            </View>
          ) : (
            replies.items.map((reply) => <ForumReplyCard key={reply.id} reply={reply} isAdmin={isAdmin} />)
          ))}
        <View style={{ height: 80 }} />
      </ScrollView>

      <View style={[styles.composer, { paddingBottom: insets.bottom > 0 ? insets.bottom + 8 : 12 }]}>
        {isGuest ? (
          <View style={styles.guestBanner}>
            <MaterialIcons name="lock-outline" size={20} color={colors.primary} />
            <Text style={[typography.bodySmall, { flex: 1, color: colors.primary }]}>
              Yanıt yazabilmek için giriş yapmanız gerekiyor.
            </Text>
          </View>
        ) : (
          <>
            <View style={styles.anonymousRow}>
              <Switch
                value={anonymousReply}
                onValueChange={setAnonymousReply}
                trackColor={{ true: colors.primary, false: '#E0E0E0' }}
                thumbColor={colors.white}
                style={{ transform: [{ scale: 0.8 }] }}
              />
              <Text style={[typography.caption, { color: anonymousReply ? colors.primary : colors.textLight }]}>
                Anonim yanıtla
              </Text>
            </View>
            <View style={styles.inputRow}>
              <TextInput
                value={replyText}
                onChangeText={setReplyText}
                placeholder="Yanıtınızı yazın..."
                placeholderTextColor={colors.textSecondary}
                multiline
                maxLength={1000}
                style={styles.replyInput}
              />
              {submitting ? (
                <ActivityIndicator color={colors.primary} style={{ width: 48 }} />
              ) : (
                <Pressable
                  style={styles.sendButton}
                  onPress={() => {
                    haptics.selection();
                    submitReply();
                  }}>
                  <MaterialIcons name="send" size={24} color={colors.white} />
                </Pressable>
              )}
            </View>
          </>
        )}
      </View>

      {showSticky && !hasVoted && !alreadyVoted && (
        <Animated.View
          entering={FadeInDown.duration(300)}
          style={[styles.sticky, { bottom: insets.bottom > 0 ? insets.bottom + 90 : 100 }]}>
          <Text style={[typography.bodySmall, { flex: 1, fontFamily: fonts.semiBold }]}>Bu gönderi yararlı oldu mu?</Text>
          <Pressable hitSlop={8} onPress={() => vote(true)}>
            <MaterialIcons name="thumb-up-off-alt" size={20} color={colors.primary} />
          </Pressable>
          <Pressable hitSlop={8} onPress={() => vote(false)} style={{ marginLeft: 16 }}>
            <MaterialIcons name="thumb-down-off-alt" size={20} color={colors.textLight} />
          </Pressable>
          <Pressable hitSlop={8} onPress={() => setShowSticky(false)} style={{ marginLeft: 8 }}>
            <MaterialIcons name="close" size={16} color={colors.textLight} />
          </Pressable>
        </Animated.View>
      )}
    </KeyboardAvoidingView>
  );
}

function FeedbackBox({ voted, onVote }: { voted: boolean; onVote: (isHelpful: boolean) => void }) {
  if (voted) {
    return (
      <View style={styles.feedbackThanks}>
        <Text style={[typography.bodyMedium, { color: colors.primary }]}>Geri bildiriminiz için teşekkürler! 🎉</Text>
      </View>
    );
  }
  return (
    <View style={styles.feedback}>
      <Text style={[typography.bodyMedium, { fontFamily: fonts.semiBold }]}>Bu gönderi sizin için yararlı oldu mu?</Text>
      <View style={styles.feedbackButtons}>
        <Pressable style={[styles.outlined, { borderColor: colors.primary }]} onPress={() => onVote(true)}>
          <MaterialIcons name="thumb-up-off-alt" size={18} color={colors.primary} />
          <Text style={[styles.outlinedText, { color: colors.primary }]}>Evet</Text>
        </Pressable>
        <Pressable style={[styles.outlined, { borderColor: '#79747E' }]} onPress={() => onVote(false)}>
          <MaterialIcons name="thumb-down-off-alt" size={18} color={colors.textSecondary} />
          <Text style={[styles.outlinedText, { color: colors.textSecondary }]}>Hayır</Text>
        </Pressable>
      </View>
    </View>
  );
}

function HiddenContent() {
  return (
    <View style={[styles.center, { padding: 32 }]}>
      <View style={styles.hiddenIcon}>
        <MaterialIcons name="warning-amber" size={40} color="#FF8F00" />
      </View>
      <Text style={[typography.heading3, { marginTop: 20, textAlign: 'center' }]}>İnceleme Altında</Text>
      <Text style={[typography.bodyMedium, { marginTop: 10, color: colors.textSecondary, textAlign: 'center' }]}>
        Bu içerik topluluk kuralları ihlali şikayetleri nedeniyle geçici olarak incelemeye alınmıştır.
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
  reportChip: {
    marginRight: 12,
    paddingHorizontal: 8,
    paddingVertical: 4,
    borderRadius: 8,
  },
  reportChipText: {
    fontFamily: fonts.regular,
    fontSize: 11,
    color: colors.white,
  },
  postCard: {
    padding: 18,
    borderRadius: 20,
    backgroundColor: colors.white,
    shadowColor: '#000000',
    shadowOpacity: 0.05,
    shadowRadius: 12,
    shadowOffset: { width: 0, height: 4 },
    elevation: 2,
  },
  authorRow: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  author: {
    ...typography.bodySmall,
    fontFamily: fonts.semiBold,
    color: colors.textPrimary,
  },
  content: {
    ...typography.bodyMedium,
    marginTop: 10,
    lineHeight: 22.4,
    color: colors.textSecondary,
  },
  metaRow: {
    marginTop: 14,
    flexDirection: 'row',
    alignItems: 'center',
  },
  categoryBadge: {
    paddingHorizontal: 10,
    paddingVertical: 4,
    borderRadius: 8,
    backgroundColor: colors.primarySurface,
  },
  categoryText: {
    ...typography.caption,
    fontFamily: fonts.semiBold,
    color: colors.primary,
  },
  feedbackThanks: {
    alignItems: 'center',
    paddingVertical: 20,
    paddingHorizontal: 16,
  },
  feedback: {
    marginTop: 10,
    alignItems: 'center',
    paddingVertical: 20,
    paddingHorizontal: 16,
    borderRadius: 12,
    backgroundColor: 'rgba(232, 245, 233, 0.5)',
  },
  feedbackButtons: {
    marginTop: 12,
    flexDirection: 'row',
    gap: 16,
  },
  outlined: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    paddingHorizontal: 16,
    paddingVertical: 10,
    borderRadius: 20,
    borderWidth: 1,
  },
  outlinedText: {
    fontFamily: fonts.medium,
    fontSize: 14,
  },
  repliesTitle: {
    marginBottom: 10,
    fontSize: 16,
  },
  noReplies: {
    padding: 20,
    textAlign: 'center',
    ...typography.bodyMedium,
  },
  guestWrap: {
    justifyContent: 'center',
  },
  guestOverlay: {
    position: 'absolute',
    left: 0,
    right: 0,
    top: 0,
    bottom: 0,
    alignItems: 'center',
    justifyContent: 'center',
    paddingHorizontal: 20,
  },
  guestBox: {
    alignSelf: 'stretch',
    alignItems: 'center',
    padding: 24,
    borderRadius: 20,
    backgroundColor: 'rgba(255, 255, 255, 0.95)',
    shadowColor: '#000000',
    shadowOpacity: 0.1,
    shadowRadius: 15,
    shadowOffset: { width: 0, height: 5 },
    elevation: 6,
  },
  guestTitle: {
    ...typography.bodyMedium,
    marginTop: 16,
    fontFamily: fonts.bold,
    fontSize: 15,
    textAlign: 'center',
  },
  guestButton: {
    alignSelf: 'stretch',
    marginTop: 20,
    paddingVertical: 14,
    alignItems: 'center',
    borderRadius: 12,
    backgroundColor: colors.primary,
  },
  composer: {
    paddingTop: 12,
    paddingHorizontal: 16,
    backgroundColor: colors.white,
    shadowColor: '#000000',
    shadowOpacity: 0.06,
    shadowRadius: 10,
    shadowOffset: { width: 0, height: -2 },
    elevation: 8,
  },
  guestBanner: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 10,
    paddingHorizontal: 16,
    paddingVertical: 12,
    borderRadius: 14,
    backgroundColor: colors.primarySurface,
  },
  anonymousRow: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  inputRow: {
    marginTop: 6,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
  },
  replyInput: {
    ...typography.bodyMedium,
    flex: 1,
    maxHeight: 96,
    padding: 12,
    borderRadius: 14,
    borderWidth: 1,
    borderColor: colors.border,
    backgroundColor: colors.background,
  },
  sendButton: {
    width: 48,
    height: 48,
    alignItems: 'center',
    justifyContent: 'center',
    borderRadius: 14,
    backgroundColor: colors.primary,
  },
  sticky: {
    position: 'absolute',
    left: 16,
    right: 16,
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 16,
    paddingVertical: 12,
    borderRadius: 16,
    backgroundColor: 'rgba(255, 255, 255, 0.95)',
    shadowColor: '#000000',
    shadowOpacity: 0.1,
    shadowRadius: 10,
    shadowOffset: { width: 0, height: -2 },
    elevation: 6,
  },
  hiddenIcon: {
    padding: 20,
    borderRadius: 999,
    backgroundColor: '#FFF3E0',
  },
});
