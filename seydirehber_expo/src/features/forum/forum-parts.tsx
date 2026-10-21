import { MaterialIcons } from '@expo/vector-icons';
import { Image } from 'expo-image';
import type { ComponentProps } from 'react';
import { useState } from 'react';
import { StyleSheet, Text, View } from 'react-native';

import { showConfirmDialog } from '@/components/confirm-dialog';
import { PopupMenu, type PopupMenuItem } from '@/components/popup-menu';
import { showSnackbar } from '@/components/snackbar';
import { useUser } from '@/features/auth/auth-store';
import { blockUser } from '@/features/block/block-service';
import { EditPostSheet, EditReplySheet } from '@/features/forum/forum-edit-sheets';
import { ForumReportSheet } from '@/features/forum/forum-report-sheet';
import {
  deleteOwnPost,
  deleteOwnReply,
  deletePost,
  deleteReply,
  reportPost,
  reportReply,
} from '@/features/forum/forum-service';
import { type ForumPost, type ForumReply, publicDisplayName } from '@/features/forum/forum-types';
import { colors, fonts, typography } from '@/theme';
import { goBack } from '@/utils/navigation';

// Forum kartları ve detay ekranının ortak parçaları (avatar, kategori çipi, menü işlemleri).
type IconName = ComponentProps<typeof MaterialIcons>['name'];

export function ForumAvatar({ item, radius }: { item: { isAnonymous: boolean; photoUrl: string | null }; radius: number }) {
  const showPhoto = !item.isAnonymous && item.photoUrl != null;
  return (
    <View
      style={[
        styles.avatar,
        {
          width: radius * 2,
          height: radius * 2,
          borderRadius: radius,
          backgroundColor: item.isAnonymous ? '#EEEEEE' : colors.primarySurface,
        },
      ]}>
      {showPhoto ? (
        <Image source={{ uri: item.photoUrl! }} style={StyleSheet.absoluteFill} cachePolicy="memory-disk" />
      ) : (
        <MaterialIcons
          name={item.isAnonymous ? 'person-off' : 'person'}
          size={radius + 2}
          color={item.isAnonymous ? '#9E9E9E' : colors.primary}
        />
      )}
    </View>
  );
}

const CATEGORY_STYLES: Record<string, [string, string, string]> = {
  soru: ['#1565C0', '❓ Soru', '21, 101, 192'],
  tavsiye: ['#2E7D32', '💡 Tavsiye', '46, 125, 50'],
  etkinlik: ['#E65100', '📅 Etkinlik', '230, 81, 0'],
};

/** Liste kartındaki renkli kategori çipi. */
export function CategoryChip({ category }: { category: string }) {
  const [color, label, rgb] = CATEGORY_STYLES[category] ?? ['#546E7A', '💬 Genel', '84, 110, 122'];
  return (
    <View style={[styles.chip, { backgroundColor: `rgba(${rgb}, 0.1)`, borderColor: `rgba(${rgb}, 0.2)` }]}>
      <Text style={[typography.caption, { color, fontFamily: fonts.semiBold }]}>{label}</Text>
    </View>
  );
}

/** Kartlardaki menü öğesi: renkli kutu içinde ikon (Flutter forum_post_card / forum_reply_card). */
function boxedItem(value: string, label: string, icon: IconName, color: string, iconSize: number): PopupMenuItem {
  return {
    value,
    label,
    icon: (
      <View style={[styles.itemIconBox, { backgroundColor: color === colors.primary ? 'rgba(76, 175, 80, 0.1)' : 'rgba(229, 57, 53, 0.1)' }]}>
        <MaterialIcons name={icon} size={iconSize} color={color} />
      </View>
    ),
    labelStyle: [typography.bodyMedium, { color, fontFamily: fonts.semiBold }],
  };
}

/** Detay ekranındaki sade menü öğesi (Flutter forum_detail_screen). */
function plainItem(value: string, label: string, icon: IconName, color: string): PopupMenuItem {
  return {
    value,
    label,
    icon: <MaterialIcons name={icon} size={18} color={color} />,
    labelStyle: [typography.bodySmall, { color }],
  };
}

const BLOCK_CONFIRM = {
  title: 'Kullanıcıyı Engelle',
  content:
    'Bu kullanıcıyı engellemek istediğinize emin misiniz? Engellediğinizde bu kişinin paylaşımlarını bir daha göremeyeceksiniz.',
  confirmLabel: 'Engelle',
  cancelLabel: 'İptal',
  icon: 'block' as const,
  iconColor: colors.error,
  isDestructive: true,
};

const errorText = (error: unknown) => (error instanceof Error ? error.message : String(error));

/** Gönderi menüsü: Bildir / Sil / Düzenle / Kullanıcıyı Engelle (kim olduğuna göre). */
export function PostActionsMenu({
  post,
  isAdmin,
  variant,
  onLeave,
}: {
  post: ForumPost;
  isAdmin: boolean;
  variant: 'card' | 'detail';
  /** Detay ekranında silme/engellemeden sonra geri dönmek için. */
  onLeave?: () => void;
}) {
  const userId = useUser()?.uid ?? null;
  const [sheet, setSheet] = useState<'report' | 'edit' | null>(null);
  if (!userId) return null;

  const isOwn = userId === post.userId;
  const item = variant === 'card' ? (v: string, l: string, i: IconName, c: string) => boxedItem(v, l, i, c, 18) : plainItem;
  const items: PopupMenuItem[] = [];
  if (!isOwn) items.push(item('report', 'Bildir', variant === 'card' ? 'flag' : 'outlined-flag', colors.error));
  if (isOwn || isAdmin) items.push(item('delete', 'Sil', variant === 'card' ? 'delete' : 'delete-outline', colors.error));
  if (isOwn) {
    items.push(
      variant === 'card' ? item('edit', 'Düzenle', 'edit', colors.primary) : plainItem('edit', 'Düzenle', 'edit', colors.textSecondary),
    );
  }
  if (!isOwn) items.push(item('block', 'Kullanıcıyı Engelle', 'block', colors.error));

  const onSelect = async (value: string) => {
    if (value === 'report') setSheet('report');
    else if (value === 'edit') setSheet('edit');
    else if (value === 'block') {
      if (await showConfirmDialog(BLOCK_CONFIRM)) {
        blockUser(post.userId, { name: publicDisplayName(post), imageUrl: post.photoUrl });
        showSnackbar({ message: 'Kullanıcı engellendi.', floating: false });
        onLeave?.();
      }
    } else if (value === 'delete') {
      const confirmed = await showConfirmDialog({
        title: 'Gönderiyi Sil',
        content: 'Bu gönderiyi silmek istediğinize emin misiniz? Bu işlem geri alınamaz.',
        confirmLabel: 'Sil',
        cancelLabel: 'Vazgeç',
        icon: 'delete-outline',
        iconColor: colors.error,
        isDestructive: true,
      });
      if (!confirmed) return;
      try {
        await (isAdmin ? deletePost(post.id) : deleteOwnPost(post.id));
        onLeave?.();
        showSnackbar({ message: 'Gönderi silindi.', floating: false });
      } catch (error) {
        showSnackbar({ message: `Hata: ${errorText(error)}`, floating: false });
      }
    }
  };

  return (
    <>
      <PopupMenu
        items={items}
        onSelect={onSelect}
        icon={variant === 'card' ? 'more-horiz' : 'more-vert'}
        iconSize={variant === 'card' ? 22 : 20}
        iconColor={colors.textLight}
        position={variant === 'card' ? 'under' : 'over'}
      />
      <ForumReportSheet
        visible={sheet === 'report'}
        onClose={() => setSheet(null)}
        contentType="gönderi"
        onReport={() => reportPost(post.id, userId)}
      />
      <EditPostSheet post={post} visible={sheet === 'edit'} onClose={() => setSheet(null)} />
    </>
  );
}

/** Yanıt menüsü: Bildir / Sil / Düzenle / Kullanıcıyı Engelle. */
export function ReplyActionsMenu({ reply, isAdmin, onOpen }: { reply: ForumReply; isAdmin: boolean; onOpen?: () => void }) {
  const userId = useUser()?.uid ?? null;
  const [sheet, setSheet] = useState<'report' | 'edit' | null>(null);
  if (!userId) return null;

  const isOwn = userId === reply.userId;
  const items: PopupMenuItem[] = [];
  if (!isOwn) items.push(boxedItem('report', 'Bildir', 'flag', colors.error, 16));
  if (isOwn || isAdmin) items.push(boxedItem('delete', 'Sil', 'delete', colors.error, 16));
  if (isOwn) items.push(boxedItem('edit', 'Düzenle', 'edit', colors.primary, 16));
  if (!isOwn) items.push(boxedItem('block', 'Kullanıcıyı Engelle', 'block', colors.error, 16));

  const onSelect = async (value: string) => {
    if (value === 'report') setSheet('report');
    else if (value === 'edit') setSheet('edit');
    else if (value === 'block') {
      if (await showConfirmDialog(BLOCK_CONFIRM)) {
        blockUser(reply.userId, { name: publicDisplayName(reply), imageUrl: reply.photoUrl });
        showSnackbar({ message: 'Kullanıcı engellendi.', floating: false });
      }
    } else if (value === 'delete') {
      const confirmed = await showConfirmDialog({
        title: 'Yanıtı Sil',
        content: 'Bu yanıtı silmek istediğinize emin misiniz? Bu işlem geri alınamaz.',
        confirmLabel: 'Sil',
        cancelLabel: 'Vazgeç',
        icon: 'delete-outline',
        iconColor: colors.error,
        isDestructive: true,
      });
      if (!confirmed) return;
      try {
        await (isAdmin ? deleteReply(reply.id, reply.postId) : deleteOwnReply(reply.id, reply.postId));
        showSnackbar({ message: 'Yanıt silindi.', floating: false });
      } catch (error) {
        showSnackbar({ message: `Hata: ${errorText(error)}`, floating: false });
      }
    }
  };

  return (
    <>
      <PopupMenu
        items={items}
        onSelect={onSelect}
        onOpen={onOpen}
        icon="more-horiz"
        iconSize={20}
        iconColor={colors.textLight}
        position="under"
      />
      <ForumReportSheet
        visible={sheet === 'report'}
        onClose={() => setSheet(null)}
        contentType="yanıt"
        onReport={() => reportReply(reply.id, userId)}
      />
      <EditReplySheet reply={reply} visible={sheet === 'edit'} onClose={() => setSheet(null)} />
    </>
  );
}

/** Detay ekranından forum listesine geri döner. */
export const leaveDetail = () => {
  goBack();
};

const styles = StyleSheet.create({
  avatar: {
    alignItems: 'center',
    justifyContent: 'center',
    overflow: 'hidden',
  },
  chip: {
    paddingHorizontal: 8,
    paddingVertical: 3,
    borderRadius: 8,
    borderWidth: 1,
  },
  itemIconBox: {
    padding: 8,
    marginRight: 4,
    borderRadius: 10,
  },
});
