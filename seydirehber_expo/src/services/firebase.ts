import { getApp } from '@react-native-firebase/app';
import { getAuth } from '@react-native-firebase/auth';
import { CACHE_SIZE_UNLIMITED, initializeFirestore } from '@react-native-firebase/firestore';

// Flutter main.dart ile aynı: offline persistence açık, önbellek sınırsız.
// Native SDK google-services.json / GoogleService-Info.plist'ten kendiliğinden başlar.
export const db = initializeFirestore(getApp(), {
  persistence: true,
  cacheSizeBytes: CACHE_SIZE_UNLIMITED,
});

export const auth = getAuth();
