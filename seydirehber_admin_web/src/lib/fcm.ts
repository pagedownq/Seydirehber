import * as jose from 'jose';

// Firebase configuration is read directly from import.meta.env


async function getAccessToken() {
  const rawKey = import.meta.env.VITE_FIREBASE_PRIVATE_KEY || '';
  
  // 1. Her türlü tırnak, boşluk ve \n kaçışlarını temizle
  const cleaned = rawKey.trim().replace(/^"+|"+$/g, '');

  // 2. Base64 gövdesini ayıkla (Sadece yasal karakterleri bırak ve yapıştır)
  // Bu işlem başlıkları (BEGIN/END) siler ve tüm parçaları birleştirir.
  const finalBase64 = cleaned
    .replace(/-----BEGIN PRIVATE KEY-----/g, '')
    .replace(/-----END PRIVATE KEY-----/g, '')
    .replace(/[^A-Za-z0-9+/=]/g, '');

  if (finalBase64.length < 1500) {
    throw new Error(`Anahtar uzunluğu yetersiz (${finalBase64.length}). Lütfen terminali kapatıp "npm run dev" ile baştan başlatın.`);
  }

  // 3. PEM formatına geri döndür (Jose kütüphanesi için zorunlu)
  const pkcs8 = `-----BEGIN PRIVATE KEY-----\n${finalBase64}\n-----END PRIVATE KEY-----`;

  try {
    const alg = 'RS256';
    const privateKey = await jose.importPKCS8(pkcs8, alg);
    const now = Math.floor(Date.now() / 1000);

    const jwt = await new jose.SignJWT({
      iss: import.meta.env.VITE_FIREBASE_CLIENT_EMAIL,
      sub: import.meta.env.VITE_FIREBASE_CLIENT_EMAIL,
      aud: 'https://oauth2.googleapis.com/token',
      scope: 'https://www.googleapis.com/auth/firebase.messaging',
      iat: now,
      exp: now + 3600
    })
      .setProtectedHeader({ alg })
      .sign(privateKey);

    const response = await fetch('https://oauth2.googleapis.com/token', {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: new URLSearchParams({
        grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
        assertion: jwt,
      }),
    });

    const data = await response.json();
    if (data.error) throw new Error(data.error_description || data.error);
    return data.access_token;
  } catch (err: any) {
    console.error('TOKEN ERROR:', err);
    throw new Error(`FCM Token Alınamadı: ${err.message}`);
  }
}

export async function sendFCMNotification(
  title: string, 
  body: string, 
  targetRoute: string = '/', 
  targetToken?: string // Belirli bir cihaza göndermek için eklendi
) {
  try {
    const accessToken = await getAccessToken();
    const url = `https://fcm.googleapis.com/v1/projects/${import.meta.env.VITE_FIREBASE_PROJECT_ID}/messages:send`;
    
    const message = {
      message: {
        // Eğer token varsa token'a, yoksa 'all' konusuna gönder
        ...(targetToken ? { token: targetToken } : { topic: 'all' }),
        notification: { title, body },
        data: { 
          screen: targetRoute,
          click_action: 'FLUTTER_NOTIFICATION_CLICK'
        },
        android: {
          priority: 'high',
          notification: { 
            channel_id: 'seydirehberim_notifications',
            sound: 'default'
          },
        },
        apns: {
          payload: {
            aps: {
              sound: 'default',
              badge: 1
            }
          }
        }
      },
    };

    const response = await fetch(url, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${accessToken}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(message),
    });

    const result = await response.json();
    if (result.error) throw new Error(result.error.message);
    return result;
  } catch (error: any) {
    console.error('FCM Send Error:', error);
    throw error;
  }
}
