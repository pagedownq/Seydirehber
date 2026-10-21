import * as Location from 'expo-location';
import { ActionSheetIOS, Linking, Platform } from 'react-native';

// Flutter lib/core/utils/map_helper.dart karşılığı.
export type LatLng = { latitude: number; longitude: number };

async function openExternal(url: string) {
  try {
    if (await Linking.canOpenURL(url)) await Linking.openURL(url);
  } catch {}
}

// iOS'ta Google Maps yüklüyse "Harita Seçimi" sorulur, değilse Apple Maps açılır.
async function handleIosMapSelection(appleMapsUrl: string, googleMapsUrl: string) {
  const hasGoogleMaps = await Linking.canOpenURL('comgooglemaps://').catch(() => false);
  if (!hasGoogleMaps) {
    await openExternal(appleMapsUrl);
    return;
  }

  ActionSheetIOS.showActionSheetWithOptions(
    {
      title: 'Harita Seçimi',
      message: 'Hangi uygulama ile açmak istersiniz?',
      options: ['Apple Maps', 'Google Maps', 'İptal'],
      cancelButtonIndex: 2,
    },
    (index) => {
      if (index === 0) Linking.openURL(appleMapsUrl).catch(() => {});
      if (index === 1) Linking.openURL(googleMapsUrl).catch(() => {});
    },
  );
}

/** Harici harita uygulamasında koordinatı açar. */
export async function openOnMap(lat: number, lng: number) {
  if (Platform.OS === 'ios') {
    await handleIosMapSelection(
      `https://maps.apple.com/?q=${lat},${lng}`,
      `comgooglemaps://?q=${lat},${lng}`,
    );
  } else {
    await openExternal(`https://www.google.com/maps/search/?api=1&query=${lat},${lng}`);
  }
}

/** Adres, koordinat ya da harita linkini harici harita uygulamasında açar. */
export async function openMapWithAddress(address: string) {
  if (!address) return;
  const encodedAddress = encodeURIComponent(address);

  if (Platform.OS === 'ios') {
    let appleUrl: string;
    let googleUrl: string;
    if (address.startsWith('http')) {
      const coords = await getCoordinates(address);
      if (coords) {
        appleUrl = `https://maps.apple.com/?q=${coords.latitude},${coords.longitude}`;
        googleUrl = `comgooglemaps://?q=${coords.latitude},${coords.longitude}`;
      } else {
        appleUrl = `https://maps.apple.com/?q=${encodedAddress}`;
        googleUrl = address;
      }
    } else {
      appleUrl = `https://maps.apple.com/?q=${encodedAddress}`;
      googleUrl = `comgooglemaps://?q=${encodedAddress}`;
    }
    await handleIosMapSelection(appleUrl, googleUrl);
  } else {
    const url = address.startsWith('http')
      ? address
      : `https://www.google.com/maps/search/?api=1&query=${encodedAddress}`;
    await openExternal(url);
  }
}

const isValid = (lat: number, lng: number) =>
  Number.isFinite(lat) && Number.isFinite(lng) && lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180;

function convertDmsToDecimal(degrees: number, minutes: number, seconds: number, direction: string) {
  const decimal = degrees + minutes / 60 + seconds / 3600;
  const dir = direction.toUpperCase();
  return dir === 'S' || dir === 'W' ? -decimal : decimal;
}

/** Google Maps linki, DMS, "lat, lng" ya da metin adresi koordinata çevirir. */
export async function getCoordinates(locationData: string): Promise<LatLng | null> {
  if (!locationData) return null;

  try {
    // 1. Google Maps URL
    const urlMatch = locationData.match(/(!3d|!4d|@|ll=)(-?\d+\.\d+),(-?\d+\.\d+)/);
    if (urlMatch) {
      const lat = parseFloat(urlMatch[2]);
      const lng = parseFloat(urlMatch[3]);
      if (isValid(lat, lng)) return { latitude: lat, longitude: lng };
    }

    // 2. DMS (36°46'52.9"N 31°26'39.0"E)
    const dmsMatch = locationData.match(
      /(\d+)°(\d+)'([\d.]+)"([NSEW])\s+(\d+)°(\d+)'([\d.]+)"([NSEW])/i,
    );
    if (dmsMatch) {
      const lat = convertDmsToDecimal(+dmsMatch[1], +dmsMatch[2], +dmsMatch[3], dmsMatch[4]);
      const lng = convertDmsToDecimal(+dmsMatch[5], +dmsMatch[6], +dmsMatch[7], dmsMatch[8]);
      if (isValid(lat, lng)) return { latitude: lat, longitude: lng };
    }

    // 3. "lat, lng"
    const plainMatch = locationData.trim().match(/^(-?\d+\.\d+),\s*(-?\d+\.\d+)$/);
    if (plainMatch) {
      const lat = parseFloat(plainMatch[1]);
      const lng = parseFloat(plainMatch[2]);
      if (isValid(lat, lng)) return { latitude: lat, longitude: lng };
    }

    // 4. Metin adres (geocoding)
    const locations = await Location.geocodeAsync(locationData);
    const first = locations[0];
    if (first && isValid(first.latitude, first.longitude)) {
      return { latitude: first.latitude, longitude: first.longitude };
    }
  } catch (error) {
    console.warn('Location Parsing Error:', error);
  }
  return null;
}

/** Link/GPS/DMS verisini okunabilir adrese çevirir; zaten adresse olduğu gibi döner. */
export async function getReadableAddress(locationData: string): Promise<string> {
  if (!locationData) return 'Adres belirtilmemiş';

  if (
    !locationData.includes('http') &&
    !locationData.includes('°') &&
    !/^-?\d+\./.test(locationData.trim())
  ) {
    return locationData;
  }

  try {
    const coords = await getCoordinates(locationData);
    if (coords) {
      const [p] = await Location.reverseGeocodeAsync(coords);
      if (p) {
        const street = p.street ?? p.name ?? '';
        const subLocality = p.district ?? p.city ?? '';
        const city = p.region ?? '';
        return `${subLocality}, ${street} CP: ${p.postalCode}, ${city}`.replaceAll(', ,', ',');
      }
    }
  } catch (error) {
    console.warn('Reverse Geocoding Error:', error);
  }
  return locationData;
}
