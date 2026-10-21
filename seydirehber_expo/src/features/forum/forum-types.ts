import { isTimestamp } from '@/utils/firestore-values';

// Flutter lib/features/forum/models/forum_post.dart + forum_reply.dart karşılığı (snake_case alanlar).
export type ForumPost = {
  id: string;
  userId: string;
  displayName: string;
  photoUrl: string | null;
  isAnonymous: boolean;
  title: string;
  content: string;
  category: string;
  replyCount: number;
  reportCount: number;
  isHidden: boolean;
  reporterIds: string[];
  createdAt: Date;
  updatedAt: Date;
  isEdited: boolean;
  helpfulVoterIds: string[];
  unhelpfulVoterIds: string[];
};

export type ForumReply = {
  id: string;
  postId: string;
  userId: string;
  displayName: string;
  photoUrl: string | null;
  isAnonymous: boolean;
  content: string;
  reportCount: number;
  isHidden: boolean;
  reporterIds: string[];
  createdAt: Date;
  isEdited: boolean;
  likedUserIds: string[];
};

type Data = Record<string, unknown>;

const strOr = (value: unknown, fallback: string) => (typeof value === 'string' ? value : fallback);
const intOr = (value: unknown) => (typeof value === 'number' ? Math.trunc(value) : 0);
const boolOr = (value: unknown, fallback: boolean) => (typeof value === 'boolean' ? value : fallback);
const stringList = (value: unknown) => (Array.isArray(value) ? value.map(String) : []);
const dateOr = (value: unknown) => (isTimestamp(value) ? value.toDate() : new Date());

export function toForumPost(id: string, data: Data): ForumPost {
  return {
    id,
    userId: strOr(data.user_id, ''),
    displayName: strOr(data.display_name, 'Kullanıcı'),
    photoUrl: typeof data.photo_url === 'string' ? data.photo_url : null,
    isAnonymous: boolOr(data.is_anonymous, false),
    title: strOr(data.title, ''),
    content: strOr(data.content, ''),
    category: strOr(data.category, 'genel'),
    replyCount: intOr(data.reply_count),
    reportCount: intOr(data.report_count),
    isHidden: boolOr(data.is_hidden, false),
    reporterIds: stringList(data.reporter_ids),
    createdAt: dateOr(data.created_at),
    updatedAt: dateOr(data.updated_at),
    isEdited: boolOr(data.is_edited, false),
    helpfulVoterIds: stringList(data.helpful_voter_ids),
    unhelpfulVoterIds: stringList(data.unhelpful_voter_ids),
  };
}

export function toForumReply(id: string, data: Data): ForumReply {
  return {
    id,
    postId: strOr(data.post_id, ''),
    userId: strOr(data.user_id, ''),
    displayName: strOr(data.display_name, 'Kullanıcı'),
    photoUrl: typeof data.photo_url === 'string' ? data.photo_url : null,
    isAnonymous: boolOr(data.is_anonymous, false),
    content: strOr(data.content, ''),
    reportCount: intOr(data.report_count),
    isHidden: boolOr(data.is_hidden, false),
    reporterIds: stringList(data.reporter_ids),
    createdAt: dateOr(data.created_at),
    isEdited: boolOr(data.is_edited, false),
    likedUserIds: stringList(data.liked_user_ids),
  };
}

/** Anonimse "Anonim Kullanıcı", değilse gerçek isim. */
export const publicDisplayName = (item: { isAnonymous: boolean; displayName: string }) =>
  item.isAnonymous ? 'Anonim Kullanıcı' : item.displayName;

/** Admin anonim yazarın gerçek adını da görür. */
export const authorLabel = (item: { isAnonymous: boolean; displayName: string }, isAdmin: boolean) =>
  isAdmin && item.isAnonymous ? `${publicDisplayName(item)} (${item.displayName})` : publicDisplayName(item);

export const FORUM_CATEGORIES = [
  { value: 'tumu', label: 'Tümü', emoji: '📋' },
  { value: 'genel', label: 'Genel', emoji: '💬' },
  { value: 'soru', label: 'Soru', emoji: '❓' },
  { value: 'tavsiye', label: 'Tavsiye', emoji: '💡' },
  { value: 'etkinlik', label: 'Etkinlik', emoji: '📅' },
] as const;

export type ForumCategoryValue = (typeof FORUM_CATEGORIES)[number]['value'];

/** "3g önce", "5s önce", "12d önce", "Az önce". */
export function timeAgo(date: Date) {
  const diffMs = Date.now() - date.getTime();
  const days = Math.floor(diffMs / 86_400_000);
  if (days > 0) return `${days}g önce`;
  const hours = Math.floor(diffMs / 3_600_000);
  if (hours > 0) return `${hours}s önce`;
  const minutes = Math.floor(diffMs / 60_000);
  if (minutes > 0) return `${minutes}d önce`;
  return 'Az önce';
}
