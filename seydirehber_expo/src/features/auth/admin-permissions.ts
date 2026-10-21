import { doc, onSnapshot } from '@react-native-firebase/firestore';
import { useEffect, useState } from 'react';

import { useAuthStore } from '@/features/auth/auth-store';
import { db } from '@/services/firebase';

// Flutter adminPermissionsProvider / isAdminProvider karşılığı.
export const ADMIN_EMAILS = ['mehmetirem305@gmail.com', 'bilgimgverse@gmail.com', 'seydirehber@gmail.com'];

export const PERMISSION_KEYS = [
  'canManageBanners',
  'canManageEvents',
  'canManageNotaries',
  'canManageMarkets',
  'canManageBuses',
  'canManagePlaces',
  'canManageCompanies',
  'canManageSupport',
  'canManageReviews',
  'canManageReports',
  'canManageNotifications',
  'canManageEsnaf',
  'canManageCoupons',
  'canManageAdmins',
  'canManageForum',
  'canManageSurveys',
  // Expo'ya özgü (Flutter'da yok)
  'canManageJobs',
] as const;

export type AdminPermission = (typeof PERMISSION_KEYS)[number];
export type AdminPermissions = Partial<Record<AdminPermission, boolean>>;

const ALL_PERMISSIONS = Object.fromEntries(PERMISSION_KEYS.map((key) => [key, true])) as AdminPermissions;

/** Admin değilse boş nesne döner. */
export function useAdminPermissions(): AdminPermissions {
  const email = useAuthStore((state) => state.user?.email?.toLowerCase() ?? '');
  const isSuperAdmin = ADMIN_EMAILS.includes(email);
  // Firestore cevabı hangi e-posta için geldiyse onunla birlikte tutulur; kullanıcı değişince eskisi kullanılmaz.
  const [fromDb, setFromDb] = useState<{ email: string; permissions: AdminPermissions }>({
    email: '',
    permissions: {},
  });

  useEffect(() => {
    if (!email || isSuperAdmin) return;
    return onSnapshot(
      doc(db, 'admins', email),
      (snapshot) => {
        const data = snapshot.data();
        const permissions =
          data && (data.isActive ?? false)
            ? (Object.fromEntries(PERMISSION_KEYS.map((key) => [key, data[key] ?? false])) as AdminPermissions)
            : {};
        setFromDb({ email, permissions });
      },
      () => setFromDb({ email, permissions: {} }),
    );
  }, [email, isSuperAdmin]);

  if (!email) return {};
  if (isSuperAdmin) return ALL_PERMISSIONS;
  return fromDb.email === email ? fromDb.permissions : {};
}

export const useIsAdmin = () => Object.keys(useAdminPermissions()).length > 0;
