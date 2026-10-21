import * as Haptics from 'expo-haptics';
import { Platform, Vibration } from 'react-native';

import { getItem, setItem, StorageKeys } from '@/services/storage';

// Flutter lib/core/services/haptic_service.dart karşılığı. Ayarlardaki anahtar kapalıysa hiçbiri titreşmez.
let enabled = true;

export async function initHaptics(): Promise<void> {
  enabled = (await getItem<boolean>(StorageKeys.hapticsEnabled)) ?? true;
}

export const hapticsEnabled = () => enabled;

export async function setHapticsEnabled(value: boolean): Promise<void> {
  enabled = value;
  await setItem(StorageKeys.hapticsEnabled, value);
}

export const haptics = {
  light() {
    if (enabled) Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
  },
  medium() {
    if (enabled) Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium);
  },
  heavy() {
    if (enabled) Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Heavy);
  },
  selection() {
    if (enabled) Haptics.selectionAsync();
  },
  // Flutter HapticFeedback.vibrate: Android'de uzun basma geri bildirimi, iOS'ta sistem titreşimi.
  vibrate() {
    if (!enabled) return;
    if (Platform.OS === 'android') {
      Haptics.performAndroidHapticsAsync(Haptics.AndroidHaptics.Long_Press);
    } else {
      Vibration.vibrate();
    }
  },
};
