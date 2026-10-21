import * as Location from 'expo-location';
import { useCallback, useEffect, useRef, useState } from 'react';
import { AppState, Platform } from 'react-native';

import type { LatLng } from '@/utils/map';

// Flutter seydi_map_screen.dart _checkPermissionAndGetLocation karşılığı:
// GPS kapalıysa Android'de sistem diyaloğu, iOS'ta "Konum Servisi Kapalı" diyaloğu; izin kalıcı reddedildiyse
// "Konum İzni Gerekli" diyaloğu. İzin alınınca konum alınır ve 10 m'de bir güncellenir.
export type LocationDialog = 'service-off' | 'permission-denied' | null;

export function useUserLocation() {
  const [userLocation, setUserLocation] = useState<LatLng | null>(null);
  const [dialog, setDialog] = useState<LocationDialog>(null);
  const subscription = useRef<Location.LocationSubscription | null>(null);
  const mounted = useRef(true);
  const lastLocation = useRef<LatLng | null>(null);

  const check = useCallback(async (): Promise<LatLng | null> => {
    // 1. Cihazın konum servisi açık mı? (GPS anahtarı)
    let serviceEnabled = await Location.hasServicesEnabledAsync().catch(() => false);
    if (!serviceEnabled) {
      if (!mounted.current) return null;
      if (Platform.OS === 'android') {
        // Android'de Google Play Servisleri diyaloğunu tetikle
        try {
          await Location.enableNetworkProviderAsync();
          serviceEnabled = true;
        } catch {
          return null;
        }
      } else {
        setDialog('service-off');
        return null;
      }
    }

    // 2. Uygulama izin durumunu kontrol et
    let permission = await Location.getForegroundPermissionsAsync();
    if (permission.status !== 'granted' && permission.canAskAgain) {
      permission = await Location.requestForegroundPermissionsAsync();
      // Kullanıcı reddetti
      if (permission.status !== 'granted' && permission.canAskAgain) return null;
    }
    if (permission.status !== 'granted') {
      if (mounted.current) setDialog('permission-denied');
      return null;
    }

    // 3. İzinler alındı, konumu al ve takibi başlat
    let current: LatLng | null = null;
    try {
      const position = await Location.getCurrentPositionAsync({ accuracy: Location.Accuracy.High });
      current = { latitude: position.coords.latitude, longitude: position.coords.longitude };
      lastLocation.current = current;
      if (mounted.current) setUserLocation(current);
    } catch (error) {
      console.warn('Error getting initial position:', error);
    }

    if (!subscription.current && mounted.current) {
      try {
        subscription.current = await Location.watchPositionAsync(
          { accuracy: Location.Accuracy.High, distanceInterval: 10 },
          (position) => {
            const next = { latitude: position.coords.latitude, longitude: position.coords.longitude };
            lastLocation.current = next;
            if (mounted.current) setUserLocation(next);
          },
          (reason) => console.warn('Location stream error:', reason),
        );
        if (!mounted.current) subscription.current.remove();
      } catch (error) {
        console.warn('Location stream error:', error);
      }
    }
    return current ?? lastLocation.current;
  }, []);

  useEffect(() => {
    mounted.current = true;
    // check asenkron: setState çağrıları await'lerden sonra (dış sistem yanıtında) yapılır.
    // eslint-disable-next-line react-hooks/set-state-in-effect
    check();

    // Flutter getServiceStatusStream: kullanıcı GPS'i bildirim panelinden açarsa tekrar dene.
    // RN'de servis durumu akışı yok; uygulamaya dönüldüğünde servis yeni açıldıysa kontrol edilir.
    let wasEnabled = true;
    Location.hasServicesEnabledAsync()
      .then((enabled) => (wasEnabled = enabled))
      .catch(() => {});
    const appState = AppState.addEventListener('change', async (state) => {
      if (state !== 'active') return;
      const enabled = await Location.hasServicesEnabledAsync().catch(() => false);
      if (enabled && !wasEnabled) check();
      wasEnabled = enabled;
    });

    return () => {
      mounted.current = false;
      appState.remove();
      subscription.current?.remove();
      subscription.current = null;
    };
  }, [check]);

  return { userLocation, recheck: check, dialog, closeDialog: () => setDialog(null) };
}

/** Geolocator.distanceBetween karşılığı (haversine, metre). */
export function distanceBetween(a: LatLng, b: LatLng) {
  const R = 6378137;
  const toRad = (deg: number) => (deg * Math.PI) / 180;
  const dLat = toRad(b.latitude - a.latitude);
  const dLng = toRad(b.longitude - a.longitude);
  const h =
    Math.sin(dLat / 2) ** 2 + Math.cos(toRad(a.latitude)) * Math.cos(toRad(b.latitude)) * Math.sin(dLng / 2) ** 2;
  return 2 * R * Math.asin(Math.sqrt(h));
}
