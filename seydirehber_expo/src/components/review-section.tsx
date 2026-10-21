import { MaterialCommunityIcons, MaterialIcons } from '@expo/vector-icons';
import { useState } from 'react';
import { Pressable, StyleSheet, Text, View } from 'react-native';

import { BottomSheet } from '@/components/bottom-sheet';
import { EmptyState } from '@/components/empty-state';
import { ReviewShimmer } from '@/components/shimmer';
import { useIsGuest } from '@/features/auth/auth-store';
import { PostReviewSheet } from '@/features/reviews/post-review-sheet';
import { ReviewCard } from '@/features/reviews/review-card';
import { type Review, useReviews } from '@/features/reviews/review-service';
import { haptics } from '@/services/haptics';
import { colors, fonts } from '@/theme';

// Flutter lib/core/widgets/review_section.dart karşılığı.
type ReviewSectionProps = { targetId: string; targetType: 'company' | 'place' };

const VISIBLE_COUNT = 5;

export function ReviewSection({ targetId, targetType }: ReviewSectionProps) {
  const state = useReviews(targetId);
  const isGuest = useIsGuest();
  const [sheet, setSheet] = useState<'post' | 'guest' | null>(null);

  const showAddReview = () => setSheet(isGuest ? 'guest' : 'post');

  return (
    <View>
      <View style={styles.header}>
        <Text style={styles.title} numberOfLines={1}>
          Değerlendirme ve Yorumlar
        </Text>
        <Pressable
          onPress={() => {
            haptics.selection();
            showAddReview();
          }}
          style={({ pressed }) => [styles.addButton, pressed && { opacity: 0.85 }]}>
          <MaterialIcons name="edit-note" size={20} color={colors.white} />
          <Text style={styles.addText}>Yorum Yap</Text>
        </Pressable>
      </View>
      <View style={{ height: 16 }} />

      {state.status === 'success' && <RatingSummary reviews={state.reviews} />}
      <View style={{ height: 12 }} />

      {state.status === 'loading' && <ReviewShimmer />}
      {state.status === 'error' &&
        (String(state.error).includes('requires an index') ? (
          <Text style={styles.indexMessage}>
            Yorumlar ilk kez hazırlandığı için birkaç dakika sürebilir. Lütfen bekleyin...
          </Text>
        ) : (
          <Text>Hata: {String(state.error)}</Text>
        ))}
      {state.status === 'success' &&
        (state.reviews.length === 0 ? (
          <View style={styles.empty}>
            <EmptyState
              icon="rate-review"
              title="Henüz Yorum Yapılmamış"
              subtitle="Bu yer hakkında hala kimse bir şey yazmamış. Burayı ilk sen canlandırmak ister misin?"
              actionLabel="İlk Yorumu Sen Yap"
              onActionPress={showAddReview}
            />
          </View>
        ) : (
          state.reviews.slice(0, VISIBLE_COUNT).map((review) => <ReviewCard key={review.id} review={review} />)
        ))}

      {state.status === 'success' && state.reviews.length > VISIBLE_COUNT && (
        // Flutter'da bu buton bir şey yapmıyor (tüm yorumlar ekranı yok); davranış korunuyor.
        <Pressable style={styles.seeAll} onPress={() => haptics.selection()}>
          <Text style={styles.seeAllText}>Tüm Yorumları Gör</Text>
        </Pressable>
      )}

      <PostReviewSheet
        visible={sheet === 'post'}
        onClose={() => setSheet(null)}
        targetId={targetId}
        targetType={targetType}
      />
      <GuestSheet visible={sheet === 'guest'} onClose={() => setSheet(null)} />
    </View>
  );
}

function RatingSummary({ reviews }: { reviews: Review[] }) {
  const count = reviews.length;
  const average = count === 0 ? 0 : reviews.reduce((sum, r) => sum + r.rating, 0) / count;
  const distribution: Record<number, number> = { 5: 0, 4: 0, 3: 0, 2: 0, 1: 0 };
  for (const review of reviews) {
    const star = Math.trunc(review.rating);
    if (star in distribution) distribution[star] += 1;
  }

  return (
    <View style={styles.summary}>
      <View style={{ alignItems: 'center' }}>
        <Text style={styles.average}>{average.toFixed(1)}</Text>
        <View style={{ flexDirection: 'row' }}>
          {Array.from({ length: 5 }, (_, index) => (
            <MaterialIcons
              key={index}
              name="star"
              size={16}
              color={index < Math.round(average) ? '#FFC107' : '#E0E0E0'}
            />
          ))}
        </View>
        <Text style={styles.count}>{count} değerlendirme</Text>
      </View>
      <View style={styles.bars}>
        {[5, 4, 3, 2, 1].map((stars) => (
          <View key={stars} style={styles.barRow}>
            <Text style={styles.barLabel}>{stars}</Text>
            <View style={styles.barTrack}>
              <View style={[styles.barFill, { width: `${count === 0 ? 0 : (distribution[stars] / count) * 100}%` }]} />
            </View>
          </View>
        ))}
      </View>
    </View>
  );
}

// Flutter: misafir kullanıcı yorum yapmak isteyince çıkan "Giriş Yapmalısınız" sayfası.
function GuestSheet({ visible, onClose }: { visible: boolean; onClose: () => void }) {
  return (
    <BottomSheet visible={visible} onClose={onClose}>
      <View style={styles.guestSheet}>
        <View style={styles.guestIcon}>
          <MaterialCommunityIcons name="account-lock" size={40} color={colors.primary} />
        </View>
        <Text style={styles.guestTitle}>Giriş Yapmalısınız</Text>
        <Text style={styles.guestText}>Yorum yazabilmek ve şehri değerlendirebilmek için lütfen giriş yapın.</Text>
        <Pressable
          style={styles.guestButton}
          onPress={() => {
            haptics.selection();
            onClose();
          }}>
          <Text style={styles.guestButtonText}>Tamam</Text>
        </Pressable>
      </View>
    </BottomSheet>
  );
}

const styles = StyleSheet.create({
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
  },
  title: {
    flex: 1,
    fontFamily: fonts.bold,
    fontSize: 18,
    color: colors.black87,
  },
  addButton: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    paddingHorizontal: 20,
    paddingVertical: 12,
    borderRadius: 30,
    backgroundColor: colors.primary,
    shadowColor: colors.primary,
    shadowOpacity: 0.4,
    shadowRadius: 4,
    shadowOffset: { width: 0, height: 2 },
    elevation: 4,
  },
  addText: {
    fontFamily: fonts.semiBold,
    fontSize: 14,
    color: colors.white,
  },
  summary: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: 20,
    borderRadius: 20,
    backgroundColor: 'rgba(232, 245, 233, 0.5)',
  },
  average: {
    fontFamily: fonts.black,
    fontSize: 40,
    color: colors.primaryDark,
  },
  count: {
    marginTop: 4,
    fontFamily: fonts.regular,
    fontSize: 10,
    color: colors.textLight,
  },
  bars: {
    flex: 1,
    marginLeft: 32,
  },
  barRow: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: 2,
  },
  barLabel: {
    width: 8,
    fontFamily: fonts.bold,
    fontSize: 10,
    color: colors.textPrimary,
  },
  barTrack: {
    flex: 1,
    height: 4,
    marginLeft: 8,
    borderRadius: 10,
    overflow: 'hidden',
    backgroundColor: '#EEEEEE',
  },
  barFill: {
    height: 4,
    backgroundColor: '#FFC107',
  },
  indexMessage: {
    padding: 16,
    fontFamily: fonts.regular,
    fontSize: 13,
    color: '#9E9E9E',
    textAlign: 'center',
  },
  empty: {
    paddingVertical: 24,
  },
  seeAll: {
    alignSelf: 'center',
    paddingHorizontal: 12,
    paddingVertical: 10,
  },
  seeAllText: {
    fontFamily: fonts.medium,
    fontSize: 14,
    color: colors.primary,
  },
  guestSheet: {
    alignItems: 'center',
    paddingHorizontal: 24,
    paddingVertical: 32,
    borderTopLeftRadius: 32,
    borderTopRightRadius: 32,
    backgroundColor: colors.white,
  },
  guestIcon: {
    width: 80,
    height: 80,
    alignItems: 'center',
    justifyContent: 'center',
    borderRadius: 40,
    backgroundColor: 'rgba(76, 175, 80, 0.1)',
  },
  guestTitle: {
    marginTop: 24,
    fontFamily: fonts.black,
    fontSize: 22,
    letterSpacing: -0.5,
    color: '#000000',
  },
  guestText: {
    marginTop: 12,
    fontFamily: fonts.regular,
    fontSize: 15,
    lineHeight: 22.5,
    color: colors.grey600,
    textAlign: 'center',
  },
  guestButton: {
    alignSelf: 'stretch',
    height: 56,
    marginTop: 32,
    alignItems: 'center',
    justifyContent: 'center',
    borderRadius: 16,
    backgroundColor: colors.primary,
  },
  guestButtonText: {
    fontFamily: fonts.bold,
    fontSize: 16,
    color: colors.white,
  },
});
