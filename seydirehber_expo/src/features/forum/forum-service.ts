import {
  addDoc,
  arrayRemove,
  arrayUnion,
  collection,
  deleteDoc,
  doc,
  getDocs,
  increment,
  onSnapshot,
  orderBy,
  query,
  runTransaction,
  serverTimestamp,
  updateDoc,
  where,
  writeBatch,
} from '@react-native-firebase/firestore';
import { useEffect, useState } from 'react';
import { create } from 'zustand';

import { useAuthStore } from '@/features/auth/auth-store';
import { useBlockStore } from '@/features/block/block-service';
import {
  type ForumCategoryValue,
  type ForumPost,
  type ForumReply,
  toForumPost,
  toForumReply,
} from '@/features/forum/forum-types';
import { db } from '@/services/firebase';
import { findProfanity } from '@/utils/profanity-filter';

// Flutter lib/features/forum/providers/forum_providers.dart karşılığı.

/** Seçili kategori ve arama (Flutter'da global StateProvider; ekrandan çıkınca sıfırlanmıyor). */
export const useForumFilterStore = create<{ category: ForumCategoryValue; search: string; retryCount: number }>(
  () => ({
    category: 'tumu',
    search: '',
    // "Yeniden Dene" dinleyiciyi yeniden başlatır (Flutter ref.invalidate).
    retryCount: 0,
  }),
);

export type ListState<T> =
  | { status: 'loading'; items: T[] }
  | { status: 'success'; items: T[] }
  | { status: 'error'; items: T[]; error: Error };

/** Dinleyici hook'ları için ortak yapı: anahtar değişince eski sonuç gösterilmez. */
function useSnapshotList<T>(
  key: string | null,
  subscribe: (onNext: (items: T[]) => void, onError: (error: Error) => void) => () => void,
): ListState<T> {
  const [current, setCurrent] = useState<{ key: string | null; state: ListState<T> }>({
    key,
    state: { status: 'loading', items: [] },
  });

  useEffect(() => {
    if (key == null) return;
    return subscribe(
      (items) => setCurrent({ key, state: { status: 'success', items } }),
      (error) => setCurrent({ key, state: { status: 'error', items: [], error } }),
    );
    // subscribe her render'da yeni; dinleyici yalnızca anahtar değişince yenilenir.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [key]);

  if (key == null) return { status: 'success', items: [] };
  return current.key === key ? current.state : { status: 'loading', items: [] };
}

/** Görünür gönderiler; kategoriye göre süzülür, engellenenler ve arama istemcide uygulanır. */
export function useForumPosts(): ListState<ForumPost> {
  const category = useForumFilterStore((s) => s.category);
  const search = useForumFilterStore((s) => s.search).trim().toLowerCase();
  const retryCount = useForumFilterStore((s) => s.retryCount);
  const blockedIds = useBlockStore((s) => s.blockedUids);

  const state = useSnapshotList<ForumPost>(`posts:${category}:${retryCount}`, (onNext, onError) => {
    const constraints = [where('is_hidden', '==', false), orderBy('created_at', 'desc')];
    if (category !== 'tumu') constraints.push(where('category', '==', category));
    return onSnapshot(
      query(collection(db, 'forum_posts'), ...constraints),
      (snapshot) => onNext(snapshot.docs.map((d) => toForumPost(d.id, d.data()))),
      onError,
    );
  });

  let items = state.items;
  if (blockedIds.length > 0) items = items.filter((p) => !blockedIds.includes(p.userId));
  if (search) {
    items = items.filter((p) => p.title.toLowerCase().includes(search) || p.content.toLowerCase().includes(search));
  }
  return { ...state, items };
}

export function useForumPost(postId: string): ListState<ForumPost | null> & { post: ForumPost | null } {
  const state = useSnapshotList<ForumPost | null>(`post:${postId}`, (onNext, onError) =>
    onSnapshot(
      doc(db, 'forum_posts', postId),
      (snapshot) => {
        const data = snapshot.data();
        onNext([snapshot.exists() && data ? toForumPost(snapshot.id, data) : null]);
      },
      onError,
    ),
  );
  return { ...state, post: state.items[0] ?? null };
}

export function useMyForumPosts(): ListState<ForumPost> {
  const uid = useAuthStore((s) => s.user?.uid ?? null);
  return useSnapshotList<ForumPost>(uid ? `my:${uid}` : null, (onNext, onError) =>
    onSnapshot(
      query(collection(db, 'forum_posts'), where('user_id', '==', uid), orderBy('created_at', 'desc')),
      (snapshot) => onNext(snapshot.docs.map((d) => toForumPost(d.id, d.data()))),
      onError,
    ),
  );
}

export function useForumReplies(postId: string): ListState<ForumReply> {
  const blockedIds = useBlockStore((s) => s.blockedUids);
  const state = useSnapshotList<ForumReply>(`replies:${postId}`, (onNext, onError) =>
    onSnapshot(
      query(
        collection(db, 'forum_replies'),
        where('post_id', '==', postId),
        where('is_hidden', '==', false),
        orderBy('created_at', 'asc'),
      ),
      (snapshot) => onNext(snapshot.docs.map((d) => toForumReply(d.id, d.data()))),
      onError,
    ),
  );
  return blockedIds.length > 0
    ? { ...state, items: state.items.filter((r) => !blockedIds.includes(r.userId)) }
    : state;
}

/** Admin: gizlenmiş gönderiler (inceleme kuyruğu). */
export function useHiddenForumPosts(): ListState<ForumPost> {
  return useSnapshotList<ForumPost>('hiddenPosts', (onNext, onError) =>
    onSnapshot(
      query(collection(db, 'forum_posts'), where('is_hidden', '==', true), orderBy('report_count', 'desc')),
      (snapshot) => onNext(snapshot.docs.map((d) => toForumPost(d.id, d.data()))),
      onError,
    ),
  );
}

/** Admin: gizlenmiş yanıtlar. */
export function useHiddenForumReplies(): ListState<ForumReply> {
  return useSnapshotList<ForumReply>('hiddenReplies', (onNext, onError) =>
    onSnapshot(
      query(collection(db, 'forum_replies'), where('is_hidden', '==', true), orderBy('report_count', 'desc')),
      (snapshot) => onNext(snapshot.docs.map((d) => toForumReply(d.id, d.data()))),
      onError,
    ),
  );
}

// ─── Forum servisi ────────────────────────────────────────────────────────────

function assertClean(...texts: string[]) {
  const badWords = [...new Set(texts.flatMap((text) => findProfanity(text)))];
  if (badWords.length > 0) throw new Error(`Uygunsuz kelimeler tespit edildi: ${badWords.join(', ')}`);
}

const postRef = (postId: string) => doc(db, 'forum_posts', postId);
const replyRef = (replyId: string) => doc(db, 'forum_replies', replyId);

export async function createPost(input: {
  userId: string;
  displayName: string;
  photoUrl: string | null;
  isAnonymous: boolean;
  title: string;
  content: string;
  category: string;
}) {
  assertClean(input.title, input.content);
  const ref = await addDoc(collection(db, 'forum_posts'), {
    user_id: input.userId,
    display_name: input.displayName,
    photo_url: input.photoUrl,
    is_anonymous: input.isAnonymous,
    title: input.title.trim(),
    content: input.content.trim(),
    category: input.category,
    reply_count: 0,
    report_count: 0,
    is_hidden: false,
    reporter_ids: [],
    created_at: serverTimestamp(),
    updated_at: serverTimestamp(),
  });
  return ref.id;
}

export async function createReply(input: {
  postId: string;
  userId: string;
  displayName: string;
  photoUrl: string | null;
  isAnonymous: boolean;
  content: string;
}) {
  assertClean(input.content);
  const batch = writeBatch(db);
  batch.set(doc(collection(db, 'forum_replies')), {
    post_id: input.postId,
    user_id: input.userId,
    display_name: input.displayName,
    photo_url: input.photoUrl,
    is_anonymous: input.isAnonymous,
    content: input.content.trim(),
    report_count: 0,
    is_hidden: false,
    reporter_ids: [],
    created_at: serverTimestamp(),
  });
  batch.update(postRef(input.postId), { reply_count: increment(1), updated_at: serverTimestamp() });
  await batch.commit();
}

/** Raporu kabul ederse true, aynı kişi daha önce raporladıysa false. 3 raporda içerik gizlenir. */
async function report(ref: ReturnType<typeof postRef>, reporterId: string, touchUpdatedAt: boolean) {
  return runTransaction(db, async (tx) => {
    const snapshot = await tx.get(ref);
    const data = snapshot.data();
    if (!snapshot.exists() || !data) return false;

    const reporterIds = Array.isArray(data.reporter_ids) ? data.reporter_ids.map(String) : [];
    if (reporterIds.includes(reporterId)) return false;

    reporterIds.push(reporterId);
    const newCount = (typeof data.report_count === 'number' ? Math.trunc(data.report_count) : 0) + 1;
    tx.update(ref, {
      reporter_ids: reporterIds,
      report_count: newCount,
      ...(newCount >= 3 ? { is_hidden: true } : {}),
      ...(touchUpdatedAt ? { updated_at: serverTimestamp() } : {}),
    });
    return true;
  });
}

export const reportPost = (postId: string, reporterId: string) => report(postRef(postId), reporterId, true);
export const reportReply = (replyId: string, reporterId: string) => report(replyRef(replyId), reporterId, false);

export async function approvePost(postId: string) {
  await updateDoc(postRef(postId), { is_hidden: false, report_count: 0, reporter_ids: [], updated_at: serverTimestamp() });
}

export async function approveReply(replyId: string) {
  await updateDoc(replyRef(replyId), { is_hidden: false, report_count: 0, reporter_ids: [] });
}

/** Admin: gönderiyi yanıtlarıyla birlikte kalıcı siler. */
export async function deletePost(postId: string) {
  const batch = writeBatch(db);
  const replies = await getDocs(query(collection(db, 'forum_replies'), where('post_id', '==', postId)));
  replies.docs.forEach((d) => batch.delete(d.ref));
  batch.delete(postRef(postId));
  await batch.commit();
}

/** Admin: yanıtı kalıcı siler. */
export async function deleteReply(replyId: string, postId: string) {
  const batch = writeBatch(db);
  batch.delete(replyRef(replyId));
  batch.update(postRef(postId), { reply_count: increment(-1) });
  await batch.commit();
}

/** Kendi gönderisini siler (Flutter'daki gibi yanıtlar silinmez). */
export async function deleteOwnPost(postId: string) {
  await deleteDoc(postRef(postId));
}

export async function deleteOwnReply(replyId: string, postId: string) {
  const batch = writeBatch(db);
  batch.delete(replyRef(replyId));
  batch.update(postRef(postId), { reply_count: increment(-1) });
  await batch.commit();
}

export async function editOwnPost(input: { postId: string; title: string; content: string; category: string }) {
  assertClean(input.title, input.content);
  await updateDoc(postRef(input.postId), {
    title: input.title.trim(),
    content: input.content.trim(),
    category: input.category,
    is_edited: true,
    updated_at: serverTimestamp(),
  });
}

export async function editOwnReply(replyId: string, content: string) {
  assertClean(content);
  await updateDoc(replyRef(replyId), { content: content.trim(), is_edited: true });
}

export async function votePost(postId: string, userId: string, isHelpful: boolean) {
  await updateDoc(
    postRef(postId),
    isHelpful
      ? { helpful_voter_ids: arrayUnion(userId), unhelpful_voter_ids: arrayRemove(userId) }
      : { unhelpful_voter_ids: arrayUnion(userId), helpful_voter_ids: arrayRemove(userId) },
  );
}

export async function toggleLikeReply(replyId: string, userId: string, isLiked: boolean) {
  await updateDoc(replyRef(replyId), { liked_user_ids: isLiked ? arrayRemove(userId) : arrayUnion(userId) });
}
