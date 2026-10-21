import { create } from 'zustand';

import { getItem, removeItem, setItem, StorageKeys } from '@/services/storage';

// Flutter lib/core/services/block_service.dart karşılığı. Saklama biçimi aynı:
// blocked_user_details_json = JSON metinleri listesi, blocked_user_uids = uid listesi (hızlı kontrol).
export type BlockedUser = { uid: string; name: string; imageUrl?: string | null };

export const useBlockStore = create<{ blockedUids: string[] }>(() => ({ blockedUids: [] }));

export async function loadBlockedUsers() {
  const uids = await getItem<string[]>(StorageKeys.blockedUserUids);
  useBlockStore.setState({ blockedUids: uids ?? [] });
}

export const useIsBlocked = (userId: string) => useBlockStore((state) => state.blockedUids.includes(userId));

export async function getBlockedUsersList(): Promise<BlockedUser[]> {
  const jsonList = (await getItem<string[]>(StorageKeys.blockedUserDetailsJson)) ?? [];
  const legacyIds = (await getItem<string[]>(StorageKeys.blockedUserUids)) ?? [];
  const list: BlockedUser[] = [];
  for (const raw of jsonList) {
    try {
      const parsed = JSON.parse(raw) as Partial<BlockedUser>;
      if (parsed.uid) list.push({ uid: parsed.uid, name: parsed.name ?? 'Bilinmeyen Kullanıcı', imageUrl: parsed.imageUrl });
    } catch {}
  }
  for (const id of legacyIds) {
    if (!list.some((u) => u.uid === id)) list.push({ uid: id, name: `Eski Engellenen (${id})` });
  }
  return list;
}

export async function blockUser(userId: string, options: { name?: string; imageUrl?: string | null } = {}) {
  const blockedUsers = await getBlockedUsersList();
  if (blockedUsers.some((u) => u.uid === userId)) return;

  blockedUsers.push({ uid: userId, name: options.name ?? 'Kullanıcı', imageUrl: options.imageUrl ?? null });
  await setItem(
    StorageKeys.blockedUserDetailsJson,
    blockedUsers.map((u) => JSON.stringify({ uid: u.uid, name: u.name, imageUrl: u.imageUrl ?? null })),
  );

  const legacyList = (await getItem<string[]>(StorageKeys.blockedUserUids)) ?? [];
  if (!legacyList.includes(userId)) {
    legacyList.push(userId);
    await setItem(StorageKeys.blockedUserUids, legacyList);
  }
  useBlockStore.setState({ blockedUids: legacyList });
}

export async function unblockUser(userId: string) {
  const list = (await getBlockedUsersList()).filter((u) => u.uid !== userId);
  await setItem(
    StorageKeys.blockedUserDetailsJson,
    list.map((u) => JSON.stringify({ uid: u.uid, name: u.name, imageUrl: u.imageUrl ?? null })),
  );
  const legacyList = ((await getItem<string[]>(StorageKeys.blockedUserUids)) ?? []).filter((id) => id !== userId);
  await setItem(StorageKeys.blockedUserUids, legacyList);
  useBlockStore.setState({ blockedUids: legacyList });
}

export async function clearBlockedUsers() {
  await removeItem(StorageKeys.blockedUserDetailsJson);
  await removeItem(StorageKeys.blockedUserUids);
  useBlockStore.setState({ blockedUids: [] });
}
