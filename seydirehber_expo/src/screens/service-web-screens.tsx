import { Linking } from 'react-native';

import { WebPageScreen } from '@/screens/web-page-screen';
import { openMapWithAddress } from '@/utils/map';

// Flutter pharmacy_screen.dart ve weather_screen.dart karşılıkları.
const PHARMACY_URL = 'https://enyakineczane.com.tr/iframe/?city=42&district=1617&zoom=1';
const WEATHER_URL =
  'https://weather-screen.web-apps-prod.wo-cloud.com/v2/screen/?locale=tr-TR&name=Seydi%C5%9Fehir&geoObjectKey=11636345&airPressureUnit=hpa&temperatureUnit=celsius&windUnit=kmh&systemOfMeasurement=metric&timeFormat=HH%3Amm';

/** Eczane sayfasındaki telefon ve harita linkleri WebView içinde değil, telefonda açılır. */
function handlePharmacyLink(url: string) {
  if (url.startsWith('tel:')) {
    Linking.canOpenURL(url)
      .then((can) => (can ? Linking.openURL(url) : undefined))
      .catch(() => {});
    return true;
  }
  if (url.startsWith('geo:') || url.includes('maps.google.com') || url.includes('google.com/maps')) {
    openMapWithAddress(url);
    return true;
  }
  return false;
}

export function PharmacyScreen() {
  return (
    <WebPageScreen
      title="Nöbetçi Eczane"
      url={PHARMACY_URL}
      errorMessage="Nöbetçi eczaneleri görüntülemek için lütfen internet bağlantınızı açın."
      onExternalLink={handlePharmacyLink}
    />
  );
}

export function WeatherScreen() {
  return (
    <WebPageScreen
      title="Hava Durumu"
      url={WEATHER_URL}
      errorMessage="Hava durumu bilgilerini görüntülemek için lütfen internet bağlantınızı açın."
      interactive={false}
    />
  );
}
