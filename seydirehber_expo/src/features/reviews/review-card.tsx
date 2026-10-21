import { MaterialCommunityIcons, MaterialIcons } from '@expo/vector-icons';
import { Image } from 'expo-image';
import type { ComponentProps } from 'react';
import { useState } from 'react';
import { Pressable, StyleSheet, Text, View } from 'react-native';

import { BottomSheet } from '@/components/bottom-sheet';
import { PopupMenu, type PopupMenuItem } from '@/components/popup-menu';
import { showSnackbar } from '@/components/snackbar';
import { useUser } from '@/features/auth/auth-store';
import { blockUser, useIsBlocked } from '@/features/block/block-service';
import { PostReviewSheet } from '@/features/reviews/post-review-sheet';
import { ALREADY_REPORTED, deleteReview, type Review, reportReview } from '@/features/reviews/review-service';
import { colors, fonts } from '@/theme';
import { formatDots, formatLongTr } from '@/utils/date';

// Flutter lib/core/widgets/review_card.dart karşılığı.
const SLATE_900 = '#1E293B';
const SLATE_500 = '#64748B';

export function ReviewCard({ review }: { review: Review }) {
  const user = useUser();
  const isBlocked = useIsBlocked(review.userId);
  const [sheet, setSheet] = useState<'edit' | 'delete' | 'report' | null>(null);

  if (isBlocked) return null;

  const isOwn = user?.uid === review.userId;
  const menuItems: PopupMenuItem[] = isOwn
    ? [
        { value: 'edit', label: 'Yorumu Düzenle', icon: <MaterialCommunityIcons name="pencil-outline" size={18} color={colors.primary} /> },
        { value: 'delete', label: 'Yorumu Sil', icon: <MaterialIcons name="delete-outline" size={18} color="#FF5252" /> },
      ]
    : [
        { value: 'report', label: 'Rapor Et', icon: <MaterialCommunityIcons name="flag-outline" size={18} color="#FF9800" /> },
        { value: 'block', label: 'Kullanıcıyı Engelle', icon: <MaterialIcons name="block" size={18} color="#607D8B" /> },
      ];

  const onSelect = (value: string) => {
    if (value === 'block') {
      blockUser(review.userId, { name: review.userName, imageUrl: review.userImageUrl });
      showSnackbar({ message: 'Kullanıcı engellendi ve içerikleri gizlendi.', backgroundColor: '#607D8B' });
      return;
    }
    setSheet(value as 'edit' | 'delete' | 'report');
  };

  return (
    <View style={styles.card}>
      <View style={styles.header}>
        <View style={styles.avatarRing}>
          <View style={styles.avatar}>
            {review.userImageUrl ? (
              <Image source={{ uri: review.userImageUrl }} style={StyleSheet.absoluteFill} cachePolicy="memory-disk" />
            ) : (
              <MaterialIcons name="person" size={20} color={colors.primary} />
            )}
          </View>
        </View>
        <View style={styles.headerTexts}>
          <Text style={styles.userName}>{review.userName}</Text>
          <Text style={styles.date}>{formatLongTr(review.createdAt)}</Text>
        </View>
        <Stars rating={review.rating} size={14} />
        <PopupMenu items={menuItems} onSelect={onSelect} />
      </View>

      {review.comment.trim() ? (
        <Text style={styles.comment}>
          {review.comment}
          {review.isEdited && <Text style={styles.edited}> (düzenlendi)</Text>}
        </Text>
      ) : null}

      {review.reply && (
        <View style={styles.reply}>
          <View style={styles.replyHeader}>
            <View style={styles.replyIcon}>
              <MaterialIcons name="store" size={14} color={colors.primary} />
            </View>
            <Text style={styles.replyTitle}>İşletme Yanıtı</Text>
            <View style={{ flex: 1 }} />
            <Text style={styles.replyDate}>{formatDots(review.reply.createdAt)}</Text>
          </View>
          <Text style={styles.replyText}>{review.reply.text}</Text>
        </View>
      )}

      <PostReviewSheet
        visible={sheet === 'edit'}
        onClose={() => setSheet(null)}
        targetId={review.targetId}
        targetType={review.targetType}
        existingReview={review}
      />
      <ConfirmSheet
        visible={sheet === 'delete'}
        onClose={() => setSheet(null)}
        icon="delete-sweep"
        accent="#F44336"
        title="Yorumu Siliyorsunuz"
        message="Bu işlemin geri dönüşü yoktur. Yorumunuzu silmek istediğinize emin misiniz?"
        confirmLabel="Evet, Sil"
        onConfirm={async () => {
          setSheet(null);
          await deleteReview(review.id).catch(() => {});
        }}
      />
      <ConfirmSheet
        visible={sheet === 'report'}
        onClose={() => setSheet(null)}
        icon="report-problem"
        accent="#FF9800"
        title="Yorumu Raporla"
        message="Bu yorumun topluluk kurallarımızı ihlal ettiğini veya uygunsuz olduğunu mu düşünüyorsunuz? Ekibimiz inceleyecektir."
        confirmLabel="Raporla"
        onConfirm={async () => {
          try {
            await reportReview(review);
            showSnackbar({ message: 'Bildiriminiz alındı, teşekkür ederiz.', backgroundColor: '#FF9800' });
          } catch (error) {
            const already = error === ALREADY_REPORTED;
            showSnackbar({
              message: already ? 'Bu yorumu zaten raporladınız.' : 'Hata oluştu, tekrar deneyin.',
              backgroundColor: already ? '#607D8B' : '#F44336',
            });
          } finally {
            setSheet(null);
          }
        }}
      />
    </View>
  );
}

export function Stars({ rating, size }: { rating: number; size: number }) {
  return (
    <View style={{ flexDirection: 'row' }}>
      {Array.from({ length: 5 }, (_, index) => (
        <MaterialIcons key={index} name="star" size={size} color={index < rating ? '#FBBF24' : '#E2E8F0'} />
      ))}
    </View>
  );
}

// Flutter review_card.dart içindeki silme / raporlama alt sayfaları.
function ConfirmSheet({
  visible,
  onClose,
  icon,
  accent,
  title,
  message,
  confirmLabel,
  onConfirm,
}: {
  visible: boolean;
  onClose: () => void;
  icon: ComponentProps<typeof MaterialIcons>['name'];
  accent: string;
  title: string;
  message: string;
  confirmLabel: string;
  onConfirm: () => void;
}) {
  return (
    <BottomSheet visible={visible} onClose={onClose}>
      <View style={styles.sheet}>
        <View style={[styles.sheetIcon, { backgroundColor: `${accent}1A` }]}>
          <MaterialIcons name={icon} size={30} color={accent} />
        </View>
        <Text style={styles.sheetTitle}>{title}</Text>
        <Text style={styles.sheetMessage}>{message}</Text>
        <View style={styles.sheetButtons}>
          <Pressable style={styles.sheetCancel} onPress={onClose}>
            <Text style={styles.sheetCancelText}>Vazgeç</Text>
          </Pressable>
          <Pressable style={[styles.sheetConfirm, { backgroundColor: accent }]} onPress={onConfirm}>
            <Text style={styles.sheetConfirmText}>{confirmLabel}</Text>
          </Pressable>
        </View>
      </View>
    </BottomSheet>
  );
}

const styles = StyleSheet.create({
  card: {
    marginVertical: 8,
    padding: 20,
    borderRadius: 24,
    backgroundColor: colors.white,
    shadowColor: '#000000',
    shadowOpacity: 0.04,
    shadowRadius: 20,
    shadowOffset: { width: 0, height: 8 },
    elevation: 2,
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  avatarRing: {
    borderRadius: 999,
    borderWidth: 2,
    borderColor: 'rgba(76, 175, 80, 0.1)',
  },
  avatar: {
    width: 40,
    height: 40,
    alignItems: 'center',
    justifyContent: 'center',
    borderRadius: 20,
    overflow: 'hidden',
    backgroundColor: colors.primarySurface,
  },
  headerTexts: {
    flex: 1,
    marginLeft: 14,
  },
  userName: {
    fontFamily: fonts.extraBold,
    fontSize: 15,
    letterSpacing: -0.2,
    color: SLATE_900,
  },
  date: {
    marginTop: 2,
    fontFamily: fonts.medium,
    fontSize: 11,
    color: SLATE_500,
  },
  comment: {
    marginTop: 16,
    fontFamily: fonts.regular,
    fontSize: 14,
    lineHeight: 22.4,
    color: '#334155',
  },
  edited: {
    fontFamily: fonts.regular,
    fontSize: 12,
    fontStyle: 'italic',
    color: '#9E9E9E',
  },
  reply: {
    marginTop: 20,
    padding: 16,
    borderRadius: 20,
    borderWidth: 1,
    borderColor: 'rgba(76, 175, 80, 0.08)',
    backgroundColor: 'rgba(76, 175, 80, 0.04)',
  },
  replyHeader: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  replyIcon: {
    padding: 6,
    borderRadius: 999,
    backgroundColor: 'rgba(76, 175, 80, 0.1)',
  },
  replyTitle: {
    marginLeft: 10,
    fontFamily: fonts.black,
    fontSize: 12,
    letterSpacing: 0.2,
    color: colors.primary,
  },
  replyDate: {
    fontFamily: fonts.semiBold,
    fontSize: 10,
    color: 'rgba(76, 175, 80, 0.5)',
  },
  replyText: {
    marginTop: 12,
    fontFamily: fonts.medium,
    fontSize: 13,
    lineHeight: 19.5,
    color: '#475569',
  },
  sheet: {
    alignItems: 'center',
    padding: 32,
    borderTopLeftRadius: 32,
    borderTopRightRadius: 32,
    backgroundColor: colors.white,
  },
  sheetIcon: {
    width: 60,
    height: 60,
    alignItems: 'center',
    justifyContent: 'center',
    borderRadius: 30,
  },
  sheetTitle: {
    marginTop: 20,
    fontFamily: fonts.black,
    fontSize: 20,
    color: SLATE_900,
  },
  sheetMessage: {
    marginTop: 10,
    fontFamily: fonts.regular,
    fontSize: 14,
    lineHeight: 21,
    color: SLATE_500,
    textAlign: 'center',
  },
  sheetButtons: {
    marginTop: 32,
    flexDirection: 'row',
    gap: 16,
    alignSelf: 'stretch',
  },
  sheetCancel: {
    flex: 1,
    alignItems: 'center',
    paddingVertical: 16,
    borderRadius: 16,
  },
  sheetCancelText: {
    fontFamily: fonts.bold,
    fontSize: 14,
    color: SLATE_500,
  },
  sheetConfirm: {
    flex: 1,
    alignItems: 'center',
    paddingVertical: 16,
    borderRadius: 16,
  },
  sheetConfirmText: {
    fontFamily: fonts.bold,
    fontSize: 14,
    color: colors.white,
  },
});
