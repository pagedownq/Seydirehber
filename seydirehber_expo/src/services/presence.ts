import { doc, serverTimestamp, setDoc } from '@react-native-firebase/firestore';
import { Platform } from 'react-native';

import { auth, db } from '@/services/firebase';

// Flutter NotificationService.updatePresence karşılığı: canlı istatistikler için user_presence/{uid}.
export async function updatePresence() {
  try {
    const user = auth.currentUser;
    if (!user) return;
    await setDoc(
      doc(db, 'user_presence', user.uid),
      {
        uid: user.uid,
        lastSeen: serverTimestamp(),
        platform: Platform.OS === 'android' ? 'android' : 'ios',
        isAnonymous: user.isAnonymous,
      },
      { merge: true },
    );
  } catch (error) {
    console.warn('Presence update error:', error);
  }
}
