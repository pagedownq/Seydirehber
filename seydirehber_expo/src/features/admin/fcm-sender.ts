import { KJUR } from 'jsrsasign';

// Flutter admin_notifications_screen.dart / admin_support_screen.dart içindeki FCM v1 gönderimi karşılığı.
// Kullanıcı kararıyla (bkz. CLAUDE.md Güvenlik) Flutter'daki gibi service account anahtarı istemcide:
// JWT imzalanır → OAuth erişim token'ı alınır → FCM v1 messages:send çağrılır.
// İleride sunucuya taşınacaksa yalnızca bu dosya değişir.

const PROJECT_ID = process.env.EXPO_PUBLIC_FCM_PROJECT_ID ?? '';
const CLIENT_EMAIL = process.env.EXPO_PUBLIC_FCM_CLIENT_EMAIL ?? '';
// .env'de "\n" kaçışlı ya da gerçek satır sonlu olabilir (Flutter replaceAll("\\n", "\n")).
const PRIVATE_KEY = (process.env.EXPO_PUBLIC_FCM_PRIVATE_KEY ?? '').replace(/\\n/g, '\n');

const SCOPE = 'https://www.googleapis.com/auth/firebase.messaging';
const TOKEN_URI = 'https://oauth2.googleapis.com/token';

let cachedToken: { value: string; expiresAt: number } | null = null;

async function getAccessToken(): Promise<string> {
  if (cachedToken && cachedToken.expiresAt > Date.now() + 60_000) return cachedToken.value;
  if (!PROJECT_ID || !CLIENT_EMAIL || !PRIVATE_KEY) {
    throw new Error('FCM servis hesabı ayarları eksik (EXPO_PUBLIC_FCM_*).');
  }

  const now = Math.floor(Date.now() / 1000);
  const assertion = KJUR.jws.JWS.sign(
    'RS256',
    JSON.stringify({ alg: 'RS256', typ: 'JWT' }),
    JSON.stringify({ iss: CLIENT_EMAIL, sub: CLIENT_EMAIL, aud: TOKEN_URI, scope: SCOPE, iat: now, exp: now + 3600 }),
    PRIVATE_KEY,
  );

  const response = await fetch(TOKEN_URI, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: `grant_type=${encodeURIComponent('urn:ietf:params:oauth:grant-type:jwt-bearer')}&assertion=${assertion}`,
  });
  const data = (await response.json()) as { access_token?: string; expires_in?: number; error_description?: string; error?: string };
  if (!response.ok || !data.access_token) {
    throw new Error(data.error_description ?? data.error ?? `Token alınamadı (${response.status})`);
  }
  cachedToken = { value: data.access_token, expiresAt: Date.now() + (data.expires_in ?? 3600) * 1000 };
  return data.access_token;
}

type Target = { topic: string } | { token: string };

async function send(target: Target, title: string, body: string, data: Record<string, string>) {
  const accessToken = await getAccessToken();
  const response = await fetch(`https://fcm.googleapis.com/v1/projects/${PROJECT_ID}/messages:send`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${accessToken}` },
    body: JSON.stringify({
      message: {
        ...target,
        notification: { title, body },
        android: {
          priority: 'high',
          notification: {
            channel_id: 'seydirehberim_notifications',
            icon: 'ic_stat_s',
            click_action: 'FLUTTER_NOTIFICATION_CLICK',
          },
        },
        apns: {
          headers: { 'apns-priority': '10', 'apns-push-type': 'alert' },
          payload: { aps: { sound: 'default', badge: 1, 'content-available': 1, 'mutable-content': 1 } },
        },
        data,
      },
    }),
  });
  if (response.status !== 200) {
    throw new Error(`FCM Error ${response.status}: ${await response.text()}`);
  }
}

/** Bildirim Yönetimi: 'all' topic'ine duyuru (Flutter _sendFCMBroadcast; data.screen = 'notifications'). */
export function sendBroadcast(title: string, body: string) {
  return send({ topic: 'all' }, title, body, {
    click_action: 'FLUTTER_NOTIFICATION_CLICK',
    id: '1',
    status: 'done',
    screen: 'notifications',
  });
}

/** Destek talebi çözüldü bildirimi (Flutter _sendTargetedFCM). */
export function sendToToken(token: string, title: string, body: string) {
  return send({ token }, title, body, { click_action: 'FLUTTER_NOTIFICATION_CLICK', status: 'done' });
}
