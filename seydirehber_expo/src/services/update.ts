import * as Application from 'expo-application';
import { Platform } from 'react-native';
import type { AndroidNeedsUpdateResponse, StatusUpdateEvent } from 'sp-react-native-in-app-updates';

// Flutter lib/core/services/update_service.dart karşılığı: sadece Android release'te Play uygulama içi güncelleme.
// Zorunlu (immediate) izinliyse onu, değilse esnek (flexible) güncellemeyi başlatır; esnek indirme bitince kurar.
let started = false;

export async function checkForUpdate(): Promise<void> {
  if (Platform.OS !== 'android' || __DEV__ || started) return;
  started = true;

  try {
    // Kütüphane yüklenirken react-native-device-info'ya bağlanıyor; iOS'ta hiç yüklenmesin diye burada.
    // eslint-disable-next-line @typescript-eslint/no-require-imports
    const lib = require('sp-react-native-in-app-updates') as typeof import('sp-react-native-in-app-updates');
    const { default: SpInAppUpdates, IAUInstallStatus, IAUUpdateKind } = lib;

    const inAppUpdates = new SpInAppUpdates(false);
    // Kütüphane mağaza versionCode'unu sürüm adıyla karşılaştırıyor; Flutter gibi versionCode'larla karşılaştırılsın.
    const result = (await inAppUpdates.checkNeedsUpdate({
      curVersion: Application.nativeBuildVersion ?? '0',
      customVersionComparator: (store, current) => Math.sign(Number(store) - Number(current)) as -1 | 0 | 1,
    })) as AndroidNeedsUpdateResponse;
    if (!result.shouldUpdate) return;

    if (result.other.isImmediateUpdateAllowed) {
      await inAppUpdates.startUpdate({ updateType: IAUUpdateKind.IMMEDIATE });
    } else if (result.other.isFlexibleUpdateAllowed) {
      const onStatus = (event: StatusUpdateEvent) => {
        if (event.status === IAUInstallStatus.DOWNLOADED) {
          inAppUpdates.removeStatusUpdateListener(onStatus);
          inAppUpdates.installUpdate();
        }
      };
      inAppUpdates.addStatusUpdateListener(onStatus);
      await inAppUpdates.startUpdate({ updateType: IAUUpdateKind.FLEXIBLE });
    }
  } catch (error) {
    console.warn('UpdateService Hatası:', error);
  }
}
