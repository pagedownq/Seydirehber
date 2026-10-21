import { onAuthStateChanged } from '@react-native-firebase/auth';
import {
  collection,
  deleteDoc,
  doc,
  getDocs,
  query,
  serverTimestamp,
  setDoc,
  where,
} from '@react-native-firebase/firestore';
import {
  getAPNSToken,
  getInitialNotification,
  getMessaging,
  getToken,
  onMessage,
  onNotificationOpenedApp,
  onTokenRefresh,
  type RemoteMessage,
  setBackgroundMessageHandler,
  subscribeToTopic,
  unsubscribeFromTopic,
} from '@react-native-firebase/messaging';
import * as Notifications from 'expo-notifications';
import { AndroidImportance, SchedulableTriggerInputTypes } from 'expo-notifications';
import { Platform } from 'react-native';

import { auth, db } from '@/services/firebase';
import { getItem, setItem, StorageKeys } from '@/services/storage';

// Flutter lib/core/services/notification_service.dart + daily_notification_service.dart karşılığı.
// FCM: RNFirebase Messaging (topic'ler 'all' ve 'vefat_notif', user_tokens kaydı).
// Yerel bildirimler (ön planda gelen FCM mesajı, destek bildirimi, haftalık hatırlatmalar): expo-notifications.

export const NOTIFICATION_CHANNEL_ID = 'seydirehberim_notifications';
const messaging = getMessaging();

// Flutter: FirebaseMessaging.onBackgroundMessage(boş işleyici).
setBackgroundMessageHandler(messaging, async () => {});

// Flutter iOS'ta FCM'in kendi ön plan gösterimini kapatıp mesajı yerel bildirim olarak gösteriyor.
// Burada da uzak (push) bildirimler ön planda gösterilmez; onMessage içinde yerel bildirim olarak gösterilir.
const isPushTrigger = (trigger: Notifications.NotificationTrigger | null) =>
  trigger != null && 'type' in trigger && trigger.type === 'push';

Notifications.setNotificationHandler({
  handleNotification: async (notification) => {
    const isRemote = isPushTrigger(notification.request.trigger);
    return {
      shouldShowBanner: !isRemote,
      shouldShowList: !isRemote,
      shouldPlaySound: !isRemote,
      shouldSetBadge: !isRemote,
    };
  },
});

// ─── Bildirime dokununca yönlendirme ─────────────────────────────────────

type Navigator = (route: string) => void;
let navigator: Navigator | null = null;
let pendingRoute: string | null = null;
let lastOpened: { route: string; at: number } | null = null;

/** MainShell karşılığı (sekme düzeni) bağlanınca bekleyen yönlendirme uygulanır. */
export function setNotificationNavigator(next: Navigator | null) {
  navigator = next;
  if (navigator && pendingRoute) {
    const route = pendingRoute;
    pendingRoute = null;
    navigator(route);
  }
}

function openRoute(value: unknown) {
  if (typeof value !== 'string' || !value) return;
  // Admin duyurusu screen: 'notifications' (başında / yok) gönderiyor; kök yol olarak açılır.
  const route = value.startsWith('/') ? value : `/${value}`;
  // Aynı dokunuş iki kaynaktan (FCM + expo) gelirse bir kez işlenir.
  const now = Date.now();
  if (lastOpened && lastOpened.route === route && now - lastOpened.at < 2000) return;
  lastOpened = { route, at: now };

  if (navigator) navigator(route);
  else pendingRoute = route;
}

/** Açılışı tetikleyen bildirim daha önce işlenmediyse kaydeder ve true döner. */
async function markLaunchNotificationHandled(id: string | undefined) {
  if (!id) return true;
  if ((await getItem<string>(StorageKeys.lastHandledNotificationId)) === id) return false;
  await setItem(StorageKeys.lastHandledNotificationId, id);
  return true;
}

// ─── Ayarlar ────────────────────────────────────────────────────────────

/** Varsayılan: açık. */
export async function isNotificationsEnabled() {
  return (await getItem<boolean>(StorageKeys.notificationsEnabled)) ?? true;
}

export async function setNotificationsEnabled(enabled: boolean) {
  await setItem(StorageKeys.notificationsEnabled, enabled);

  // Firestore durumunu güncelle
  const token = await safeGetToken();
  if (token) await saveTokenToFirestore(token, enabled);

  if (enabled) {
    await subscribeToTopic(messaging, 'all').catch(logError('subscribe all'));
    // Ana bildirimler açıldığında günlük bildirimleri de yeniden planla
    scheduleDailyNotifications().catch(logError('DailyNotif reschedule'));
  } else {
    await unsubscribeFromTopic(messaging, 'all').catch(logError('unsubscribe all'));
    // Ana bildirimler kapatıldığında günlük bildirimleri de iptal et
    setDailyNotificationsEnabled(false).catch(logError('DailyNotif cancel'));
  }
}

/** Varsayılan: açık. */
export async function isVefatNotificationsEnabled() {
  return (await getItem<boolean>(StorageKeys.vefatNotificationsEnabled)) ?? true;
}

export async function setVefatNotificationsEnabled(enabled: boolean) {
  await setItem(StorageKeys.vefatNotificationsEnabled, enabled);
  if (enabled) await subscribeToTopic(messaging, 'vefat_notif').catch(logError('subscribe vefat'));
  else await unsubscribeFromTopic(messaging, 'vefat_notif').catch(logError('unsubscribe vefat'));
}

/** Varsayılan: açık. */
export async function isDailyNotificationsEnabled() {
  return (await getItem<boolean>(StorageKeys.dailyNotifEnabled)) ?? true;
}

export async function setDailyNotificationsEnabled(enabled: boolean) {
  await setItem(StorageKeys.dailyNotifEnabled, enabled);
  if (enabled) await scheduleDailyNotifications();
  else await cancelDailyNotifications();
}

// ─── Başlatma ───────────────────────────────────────────────────────────

let initialized = false;

/** Flutter NotificationService.initialize: açılışta arka planda çalışır. */
export async function initNotifications() {
  if (initialized) return;
  initialized = true;

  // 1. İlk kullanım tarihi (Bildirimler ekranı bu tarihten sonraki duyuruları gösterir)
  if ((await getItem<string>(StorageKeys.installationDate)) == null) {
    await setItem(StorageKeys.installationDate, toDartIsoString(new Date()));
  }

  await ensureChannel();

  // 2. Yerel bildirime dokunma (uygulama kapalıyken açıldıysa da).
  // Son yanıt ve ilk FCM mesajı sonraki açılışlarda / JS yenilemelerinde tekrar dönebiliyor;
  // aynı bildirim iki kez açılmasın diye kimliği saklanır.
  const lastResponse = await Notifications.getLastNotificationResponseAsync().catch(() => null);
  if (lastResponse) {
    Notifications.clearLastNotificationResponseAsync().catch(logError('clear last response'));
    if (await markLaunchNotificationHandled(lastResponse.notification.request.identifier)) {
      handleLocalResponse(lastResponse);
    }
  }
  Notifications.addNotificationResponseReceivedListener(handleLocalResponse);

  // 3. FCM bildirimine dokunma: uygulama kapalıyken / arka plandayken
  const initialMessage = await getInitialNotification(messaging).catch(() => null);
  if (initialMessage && (await markLaunchNotificationHandled(initialMessage.messageId))) {
    openRoute(initialMessage.data?.screen);
  }
  onNotificationOpenedApp(messaging, (message) => openRoute(message.data?.screen));

  // 4. Ön planda gelen mesaj yerel bildirim olarak gösterilir
  onMessage(messaging, (message) => {
    const notification = message.notification;
    if (!notification) return;
    showLocalNotification(notification.title ?? '', notification.body ?? '', screenOf(message));
  });

  // 5. Token + topic abonelikleri
  if (Platform.OS === 'ios') {
    // APNs'in token üretmesi için kısa süre bekle (iOS push için kritik)
    let apnsToken: string | null = null;
    for (let retry = 0; apnsToken == null && retry < 3; retry++) {
      apnsToken = await getAPNSToken(messaging).catch(() => null);
      if (apnsToken == null) await new Promise((resolve) => setTimeout(resolve, 2000));
    }
    if (apnsToken == null) console.warn('CRITICAL: APNs token could not be acquired after multiple attempts.');
  }

  const token = await safeGetToken();
  if (token) {
    const enabled = await isNotificationsEnabled();
    await saveTokenToFirestore(token, enabled);
    await (enabled ? subscribeToTopic : unsubscribeFromTopic)(messaging, 'all').catch(logError('topic all'));

    const vefatEnabled = await isVefatNotificationsEnabled();
    await (vefatEnabled ? subscribeToTopic : unsubscribeFromTopic)(messaging, 'vefat_notif').catch(
      logError('topic vefat'),
    );
  }

  // Giriş/çıkışta token kaydı kullanıcıyla eşlensin
  onAuthStateChanged(auth, async () => {
    const current = await safeGetToken();
    if (current) await saveTokenToFirestore(current, await isNotificationsEnabled());
  });

  // Uygulama çalışırken token yenilenirse
  onTokenRefresh(messaging, async (newToken) => {
    await saveTokenToFirestore(newToken, await isNotificationsEnabled());
  });
}

/** Flutter requestPermission'ın izin verildikten sonraki kısmı: token kaydı + 'all' aboneliği. */
export async function onNotificationPermissionGranted() {
  const token = await safeGetToken();
  if (!token) return;
  const enabled = await isNotificationsEnabled();
  await saveTokenToFirestore(token, enabled);
  if (enabled) await subscribeToTopic(messaging, 'all').catch(logError('subscribe all'));
}

// ─── Token kaydı ────────────────────────────────────────────────────────

async function safeGetToken() {
  try {
    return await getToken(messaging);
  } catch (error) {
    console.warn('FCM token alınamadı:', error);
    return null;
  }
}

async function saveTokenToFirestore(token: string, isEnabled: boolean) {
  try {
    const user = auth.currentUser;
    const platform = Platform.OS === 'android' ? 'android' : 'ios';

    // Yerelde farklı eski token varsa (yeniden kurulum / token değişimi) eski kaydı sil
    const oldToken = await getItem<string>(StorageKeys.lastRegisteredFcmToken);
    if (oldToken != null && oldToken !== token) {
      await deleteDoc(doc(db, 'user_tokens', oldToken)).catch(logError('stale token delete'));
    }

    // 1. Giriş yapılmışsa varlık kaydı
    if (user) {
      await setDoc(
        doc(db, 'user_presence', user.uid),
        { uid: user.uid, lastSeen: serverTimestamp(), platform, isAnonymous: user.isAnonymous },
        { merge: true },
      );
    }

    // 2. Bildirim token'ı
    await setDoc(
      doc(db, 'user_tokens', token),
      {
        token,
        userId: user?.uid ?? null,
        platform,
        lastUpdated: serverTimestamp(),
        isEnabled,
        lastSeen: serverTimestamp(),
      },
      { merge: true },
    );

    await setItem(StorageKeys.lastRegisteredFcmToken, token);

    // Bu kullanıcının 7 günden eski diğer token'larını temizle
    if (user) cleanOldUserTokens(user.uid, token);
  } catch (error) {
    console.warn('Token registration error:', error);
  }
}

async function cleanOldUserTokens(userId: string, currentToken: string) {
  try {
    const snapshot = await getDocs(query(collection(db, 'user_tokens'), where('userId', '==', userId)));
    for (const tokenDoc of snapshot.docs) {
      if (tokenDoc.id === currentToken) continue;
      const lastSeen = tokenDoc.data().lastSeen as { toDate?: () => Date } | null | undefined;
      const date = lastSeen?.toDate?.();
      if (!date || Date.now() - date.getTime() > 7 * 24 * 60 * 60 * 1000) {
        await deleteDoc(tokenDoc.ref);
      }
    }
  } catch (error) {
    console.warn('Token cleanup error:', error);
  }
}

// ─── Yerel bildirimler ──────────────────────────────────────────────────

async function ensureChannel() {
  if (Platform.OS !== 'android') return;
  await Notifications.setNotificationChannelAsync(NOTIFICATION_CHANNEL_ID, {
    name: 'Seydi Rehber Bildirimleri',
    description: 'Şehir duyuruları ve önemli bildirimler için kullanılır.',
    importance: AndroidImportance.MAX,
  }).catch(logError('channel'));
}

function handleLocalResponse(response: Notifications.NotificationResponse) {
  // Uzak bildirimler FCM tarafında işlenir.
  if (isPushTrigger(response.notification.request.trigger)) return;
  if (response.actionIdentifier !== Notifications.DEFAULT_ACTION_IDENTIFIER) return;
  openRoute(response.notification.request.content.data?.screen);
}

const screenOf = (message: RemoteMessage) =>
  typeof message.data?.screen === 'string' ? message.data.screen : undefined;

/** Anında yerel bildirim (Flutter showTestNotification / onMessage gösterimi). */
export async function showLocalNotification(title: string, body: string, screen?: string) {
  try {
    await ensureChannel();
    await Notifications.scheduleNotificationAsync({
      content: { title, body, sound: true, data: screen ? { screen } : {} },
      trigger: Platform.OS === 'android' ? { channelId: NOTIFICATION_CHANNEL_ID } : null,
    });
  } catch (error) {
    console.warn('Yerel bildirim gösterilemedi:', error);
  }
}

// ─── Haftalık hatırlatmalar (DailyNotificationService) ──────────────────

type Template = { title: string; body: string; route: string };

const MONDAY: Template[] = [
  { title: 'Yeni Haftaya Başlarken ☀️', body: 'Bugünün nöbetçi eczanesini ve güncel otobüs saatlerini hemen öğren!', route: '/pharmacy' },
  { title: 'Harika Bir Hafta Olsun! ☕', body: "Güne güzel bir başlangıç için Seydişehir'in en sevilen mekanlarını keşfet.", route: '/companies/popular' },
];
const THURSDAY: Template[] = [
  { title: 'Pazar Alışverişi Zamanı! 🍎', body: 'Bugün kurulan halk pazarı nerede? Taze alışveriş için yerini hemen öğren.', route: '/pazarlar' },
  { title: 'Perşembe Fırsatları 🎫', body: 'Hafta sonu öncesi indirim kuponlarına göz attın mı? Fırsatları kaçırma!', route: '/coupons' },
];
const FRIDAY: Template[] = [
  { title: 'Hafta Sonu Geldi! 🎉', body: 'Akşam kahvesi veya akşam yemeği için nereye gitmeli? Popüler mekanları keşfet.', route: '/companies/popular' },
  { title: 'Hafta Sonuna Özel 🍰', body: 'Rehbere yeni eklenen kafe, restoran ve butikleri incelemeye ne dersin?', route: '/companies/latest' },
];
const SUNDAY: Template[] = [
  { title: 'Bugün Neler Var? 📅', body: "Seydişehir'deki en güncel etkinlikleri kaçırma, planını hemen yap!", route: '/events' },
  { title: 'Pazar Keşfi 🗺️', body: "Seydişehir'in saklı kalmış doğal ve tarihi güzelliklerini keşfe çık!", route: '/places' },
];

// Kimlikler Flutter'dakiyle aynı: iOS'ta Flutter sürümünden kalan planlı bildirimler bunlarla değiştirilir.
// expo-notifications haftalık tetikleyicide weekday 1 = Pazar (Dart'ta 1 = Pazartesi).
const WEEKLY = [
  { id: '9101', templates: MONDAY, weekday: 2, hour: 9, minute: 30 },
  { id: '9102', templates: THURSDAY, weekday: 5, hour: 10, minute: 0 },
  { id: '9103', templates: FRIDAY, weekday: 6, hour: 18, minute: 0 },
  { id: '9104', templates: SUNDAY, weekday: 1, hour: 13, minute: 0 },
];

/** Pzt 09:30, Per 10:00, Cum 18:00, Paz 13:00 (cihaz saati) — her seferinde rastgele şablon. */
export async function scheduleDailyNotifications() {
  if (!(await isDailyNotificationsEnabled())) return;

  // Planı her seferinde tazele
  await cancelDailyNotifications();
  await ensureChannel();
  for (const slot of WEEKLY) {
    const template = slot.templates[Math.floor(Math.random() * slot.templates.length)];
    try {
      await Notifications.scheduleNotificationAsync({
        identifier: slot.id,
        content: { title: template.title, body: template.body, sound: true, data: { screen: template.route } },
        trigger: {
          type: SchedulableTriggerInputTypes.WEEKLY,
          weekday: slot.weekday,
          hour: slot.hour,
          minute: slot.minute,
          channelId: NOTIFICATION_CHANNEL_ID,
        },
      });
    } catch (error) {
      console.warn(`[DailyNotif] HATA! ID=${slot.id} planlanamadı:`, error);
    }
  }
}

async function cancelDailyNotifications() {
  for (const slot of WEEKLY) {
    await Notifications.cancelScheduledNotificationAsync(slot.id).catch(() => {});
  }
}

// ─── Yardımcılar ────────────────────────────────────────────────────────

const pad = (n: number, width = 2) => String(n).padStart(width, '0');

/** Dart DateTime.toIso8601String (yerel saat, saat dilimi eki yok) — Flutter'dan taşınan değerle uyumlu. */
function toDartIsoString(date: Date) {
  return (
    `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())}` +
    `T${pad(date.getHours())}:${pad(date.getMinutes())}:${pad(date.getSeconds())}.${pad(date.getMilliseconds(), 3)}`
  );
}

/** Dart DateTime.parse karşılığı (mikrosaniye ve saat dilimi eki olabilir). */
export function parseDartIsoString(value: string): Date | null {
  const match = value.match(/^(\d{4})-(\d{2})-(\d{2})[T ](\d{2}):(\d{2})(?::(\d{2})(?:\.(\d+))?)?(Z|[+-]\d{2}:?\d{2})?$/);
  if (!match) return null;
  const [, y, mo, d, h, mi, s = '0', frac = '0', zone] = match;
  const ms = Math.round(Number(`0.${frac}`) * 1000);
  if (!zone) return new Date(+y, +mo - 1, +d, +h, +mi, +s, ms);
  const utc = Date.UTC(+y, +mo - 1, +d, +h, +mi, +s, ms);
  if (zone === 'Z') return new Date(utc);
  const sign = zone.startsWith('-') ? -1 : 1;
  const digits = zone.slice(1).replace(':', '');
  const offsetMinutes = sign * (Number(digits.slice(0, 2)) * 60 + Number(digits.slice(2)));
  return new Date(utc - offsetMinutes * 60 * 1000);
}

export async function getInstallationDate(): Promise<Date | null> {
  const value = await getItem<string>(StorageKeys.installationDate);
  return value ? parseDartIsoString(value) : null;
}

const logError = (label: string) => (error: unknown) => console.warn(`[Notifications] ${label}:`, error);
