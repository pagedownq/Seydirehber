/// <reference types="node" />
import fs from 'node:fs';
import path from 'node:path';

import type { ExpoConfig } from 'expo/config';

// Mağazadaki canlı Flutter sürümü 1.0.10+32. Expo sürümü güncelleme olarak çıkacağı için
// version ve build numaraları her zaman bundan büyük olmalı.
const VERSION = '1.0.12';
const BUILD_NUMBER = 39;

// Firebase dosyaları git'e girmez. EAS'te file env variable olarak verilir,
// yerelde proje kökündeki kopyalar kullanılır.
const GOOGLE_SERVICES_JSON = process.env.GOOGLE_SERVICES_JSON ?? './google-services.json';
const GOOGLE_SERVICE_INFO_PLIST =
  process.env.GOOGLE_SERVICE_INFO_PLIST ?? './GoogleService-Info.plist';

// Google Sign-In iOS URL şeması = plist'teki REVERSED_CLIENT_ID.
function readReversedClientId(): string {
  try {
    const plist = fs.readFileSync(path.resolve(__dirname, GOOGLE_SERVICE_INFO_PLIST), 'utf8');
    const match = plist.match(/<key>REVERSED_CLIENT_ID<\/key>\s*<string>([^<]+)<\/string>/);
    if (match) return match[1];
  } catch {}
  // Dosya yokken (ör. `expo config`) plugin doğrulamasından geçmek için yer tutucu.
  return 'com.googleusercontent.apps.missing';
}

const LOCATION_PERMISSION =
  'Harita üzerinde konumunuzu görmek ve size en yakın noktaları bulmak için konum izni gereklidir.';

const config: ExpoConfig = {
  name: 'Seydi Rehber',
  slug: 'seydirehber',
  owner: 'mgversemehmet',
  version: VERSION,
  orientation: 'portrait',
  icon: './assets/images/SeydiRehber.png',
  scheme: 'seydirehberim',
  userInterfaceStyle: 'light',
  backgroundColor: '#F5F9F6',
  ios: {
    bundleIdentifier: 'com.mgverse.seydirehberim',
    buildNumber: String(BUILD_NUMBER),
    supportsTablet: true,
    googleServicesFile: GOOGLE_SERVICE_INFO_PLIST,
    usesAppleSignIn: true,
    infoPlist: {
      LSApplicationQueriesSchemes: ['tel', 'mailto', 'comgooglemaps'],
      UIBackgroundModes: ['fetch', 'remote-notification'],
      ITSAppUsesNonExemptEncryption: false,
    },
  },
  android: {
    package: 'com.mgverse.seydirehberim',
    versionCode: BUILD_NUMBER,
    googleServicesFile: GOOGLE_SERVICES_JSON,
    predictiveBackGestureEnabled: false,
    permissions: ['android.permission.VIBRATE', 'android.permission.RECEIVE_BOOT_COMPLETED'],
  },
  plugins: [
    // Mod'lar ters sırada çalışır: en başta olduğu için expo-notifications ve RNFirebase'den sonra uygulanır.
    './plugins/with-fcm-manifest-fix',
    'expo-router',
    [
      'expo-splash-screen',
      {
        backgroundColor: '#FFFFFF',
        // İkon yerine sade yeşil yazı (Poppins ExtraBold, #4CAF50, şeffaf zemin).
        image: './assets/images/splash-wordmark.png',
        imageWidth: 220,
        // Android 12+ splash görseli ~192dp'lik daire maskesine giriyor; geniş yazı taşmasın.
        android: { image: './assets/images/splash-wordmark.png', imageWidth: 180 },
      },
    ],
    [
      'expo-build-properties',
      {
        // Firebase iOS SDK 13+ sadece SPM ile geliyor; RNFirebase dinamik framework istiyor.
        ios: { useFrameworks: 'dynamic' },
      },
    ],
    '@react-native-firebase/app',
    // SDK 58 SceneDelegate şablonunda RNFirebase plugin'i FirebaseApp.configure() ekleyemiyor (bkz. plugin).
    './plugins/with-firebase-configure',
    '@react-native-firebase/auth',
    '@react-native-firebase/messaging',
    '@react-native-firebase/analytics',
    ['@react-native-google-signin/google-signin', { iosUrlScheme: readReversedClientId() }],
    'expo-apple-authentication',
    [
      'expo-notifications',
      {
        icon: './assets/notification/ic_stat_s.png',
        color: '#4CAF50',
        defaultChannel: 'seydirehberim_notifications',
      },
    ],
    [
      'expo-location',
      {
        locationWhenInUsePermission: LOCATION_PERMISSION,
      },
    ],
    [
      'expo-image-picker',
      {
        photosPermission:
          'Profil resmi güncellemek veya içeriklere fotoğraf eklemek için galerinize erişim izni gerekebilir.',
        cameraPermission:
          'İçeriklere fotoğraf eklemek veya profil resmi çekmek için kameranıza erişim izni gerekebilir.',
        microphonePermission: false,
      },
    ],
    '@maplibre/maplibre-react-native',
  ],
  experiments: {
    typedRoutes: true,
    reactCompiler: true,
  },
  extra: {
    eas: {
      projectId: '17f1fa43-d093-4136-9cf7-5873cc01fe2b',
    },
  },
};

export default config;
