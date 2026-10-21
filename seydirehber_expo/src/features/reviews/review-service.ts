import {
  addDoc,
  collection,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  limit,
  onSnapshot,
  orderBy,
  query,
  serverTimestamp,
  updateDoc,
  where,
} from '@react-native-firebase/firestore';
import { useEffect, useState } from 'react';

import { auth, db } from '@/services/firebase';
import { isTimestamp } from '@/utils/firestore-values';
import { hasProfanity } from '@/utils/profanity-filter';

// Flutter lib/core/services/review_service.dart + lib/core/models/review.dart karşılığı.
export type ReviewTargetType = 'place' | 'company';

export type Review = {
  id: string;
  targetId: string;
  targetType: string;
  userId: string;
  userName: string;
  userImageUrl: string | null;
  rating: number;
  comment: string;
  createdAt: Date;
  isEdited: boolean;
  updatedAt: Date | null;
  reply: { text: string; createdAt: Date } | null;
};

/** Servisin fırlattığı özel hata kodları (Flutter'daki string throw'lar). */
export const PROFANITY_DETECTED = 'PROFANITY_DETECTED';
export const ALREADY_REPORTED = 'ALREADY_REPORTED';

function toReview(id: string, data: Record<string, unknown>): Review {
  const reply = data.reply as Record<string, unknown> | null | undefined;
  return {
    id,
    targetId: (data.targetId as string) ?? '',
    targetType: (data.targetType as string) ?? '',
    userId: (data.userId as string) ?? '',
    userName: (data.userName as string) ?? 'İsimsiz Kullanıcı',
    userImageUrl: (data.userImageUrl as string | null) ?? null,
    rating: typeof data.rating === 'number' ? data.rating : 0,
    comment: (data.comment as string) ?? '',
    // Sunucu zaman damgası henüz yazılmadıysa (yeni yorum) şimdiki zaman.
    createdAt: isTimestamp(data.createdAt) ? data.createdAt.toDate() : new Date(),
    isEdited: (data.isEdited as boolean) ?? false,
    updatedAt: isTimestamp(data.updatedAt) ? data.updatedAt.toDate() : null,
    reply: reply
      ? {
          text: (reply.text as string) ?? '',
          createdAt: isTimestamp(reply.createdAt) ? reply.createdAt.toDate() : new Date(),
        }
      : null,
  };
}

export type ReviewsState =
  | { status: 'loading'; reviews: Review[] }
  | { status: 'success'; reviews: Review[] }
  | { status: 'error'; reviews: Review[]; error: Error };

/** Flutter reviewsProvider(targetId): hedefin yorumları, en yeni önce. */
export function useReviews(targetId: string): ReviewsState {
  const [current, setCurrent] = useState<{ targetId: string; state: ReviewsState }>({
    targetId,
    state: { status: 'loading', reviews: [] },
  });

  useEffect(
    () =>
      onSnapshot(
        query(collection(db, 'reviews'), where('targetId', '==', targetId), orderBy('createdAt', 'desc')),
        (snapshot) =>
          setCurrent({
            targetId,
            state: {
              status: 'success',
              reviews: snapshot.docs.map((d) => toReview(d.id, d.data() as Record<string, unknown>)),
            },
          }),
        (error) => setCurrent({ targetId, state: { status: 'error', reviews: [], error } }),
      ),
    [targetId],
  );

  return current.targetId === targetId ? current.state : { status: 'loading', reviews: [] };
}

/** Hedef dokümandaki ortalama puan ve yorum sayısını yeniden hesaplar (denormalizasyon). */
async function syncTargetStats(targetId: string, targetType: string) {
  const collectionPath = targetType === 'company' ? 'firmalar' : 'gezilecek_yerler';
  const targetDoc = doc(db, collectionPath, targetId);
  try {
    const reviews = await getDocs(query(collection(db, 'reviews'), where('targetId', '==', targetId)));
    if (!reviews.empty) {
      const total = reviews.docs.reduce((sum, d) => {
        const rating = d.data().rating;
        return sum + (typeof rating === 'number' ? rating : 0);
      }, 0);
      await updateDoc(targetDoc, { ortalama_puan: total / reviews.size, yorum_sayisi: reviews.size });
    } else {
      await updateDoc(targetDoc, { ortalama_puan: 0.0, yorum_sayisi: 0 });
    }
  } catch (error) {
    console.warn('Sync target stats error:', error);
  }
}

export async function addReview(input: {
  targetId: string;
  targetType: string;
  rating: number;
  comment: string;
}) {
  const user = auth.currentUser;
  if (!user) throw new Error('Yorum yapmak için giriş yapmalısınız.');
  if (hasProfanity(input.comment)) throw PROFANITY_DETECTED;

  await addDoc(collection(db, 'reviews'), {
    targetId: input.targetId,
    targetType: input.targetType,
    userId: user.uid,
    userName: user.displayName ?? 'Misafir',
    userImageUrl: user.photoURL ?? null,
    rating: input.rating,
    comment: input.comment,
    createdAt: serverTimestamp(),
    isEdited: false,
    updatedAt: null,
    reply: null,
  });
  await syncTargetStats(input.targetId, input.targetType);
}

export async function updateReview(input: { reviewId: string; rating: number; comment: string }) {
  if (!auth.currentUser) throw new Error('Yorum düzenlemek için giriş yapmalısınız.');
  if (hasProfanity(input.comment)) throw PROFANITY_DETECTED;

  const reviewRef = doc(db, 'reviews', input.reviewId);
  await updateDoc(reviewRef, {
    rating: input.rating,
    comment: input.comment,
    isEdited: true,
    updatedAt: serverTimestamp(),
  });

  const reviewDoc = await getDoc(reviewRef);
  const data = reviewDoc.data();
  if (data) await syncTargetStats(data.targetId, data.targetType);
}

export async function deleteReview(reviewId: string) {
  if (!auth.currentUser) throw new Error('Yorum silmek için giriş yapmalısınız.');
  const reviewRef = doc(db, 'reviews', reviewId);
  const reviewDoc = await getDoc(reviewRef);
  const data = reviewDoc.data();
  if (!data) return;

  await deleteDoc(reviewRef);
  await syncTargetStats(data.targetId, data.targetType);
}

export async function reportReview(review: Review) {
  if (!review.id) throw 'ERROR_INVALID_REVIEW_ID';
  const reporterId = auth.currentUser?.uid ?? 'guest';

  // Misafir değilse mükerrer şikayet kontrolü; kontrol başarısız olursa (ör. yetki) devam edilir.
  if (reporterId !== 'guest') {
    let alreadyReported = false;
    try {
      const existing = await getDocs(
        query(
          collection(db, 'sikayetler'),
          where('reviewId', '==', review.id),
          where('reporterId', '==', reporterId),
          limit(1),
        ),
      );
      alreadyReported = !existing.empty;
    } catch (error) {
      console.warn('Şikayet kontrolünde hata (devam ediliyor):', error);
    }
    if (alreadyReported) throw ALREADY_REPORTED;
  }

  await addDoc(collection(db, 'sikayetler'), {
    reviewId: review.id,
    reporterId,
    targetId: review.targetId,
    targetType: review.targetType,
    content: review.comment,
    userName: review.userName,
    timestamp: serverTimestamp(),
    status: 'pending',
  });
}
