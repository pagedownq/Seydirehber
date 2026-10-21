import * as Notifications from 'expo-notifications';

import { onNotificationPermissionGranted } from '@/services/notifications';

// Flutter NotificationService.getPermissionStatus / requestPermission karşılığı.
export type PermissionState = 'granted' | 'denied' | 'permanentlyDenied' | 'undetermined';

export async function getNotificationPermission(): Promise<PermissionState> {
  const { status, canAskAgain } = await Notifications.getPermissionsAsync();
  if (status === 'granted') return 'granted';
  if (status === 'denied') return canAskAgain ? 'denied' : 'permanentlyDenied';
  return 'undetermined';
}

export async function requestNotificationPermission(): Promise<boolean> {
  const { status } = await Notifications.requestPermissionsAsync({
    ios: { allowAlert: true, allowBadge: true, allowSound: true },
  });
  const granted = status === 'granted';
  // İzin verildiyse token kaydı ve 'all' aboneliği hemen yapılır.
  if (granted) onNotificationPermissionGranted().catch((error) => console.warn('Token kaydı hatası:', error));
  return granted;
}
