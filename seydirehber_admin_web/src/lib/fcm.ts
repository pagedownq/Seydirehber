import * as jose from 'jose';

// Service Account details
const SERVICE_ACCOUNT = {
  project_id: "seydirehber1",
  client_email: "firebase-adminsdk-fbsvc@seydirehber1.iam.gserviceaccount.com",
  private_key: `-----BEGIN PRIVATE KEY-----
MIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQDGKjw0dZlwIubk
UsNgLWIuVkOGAM+FrkOwSDEGJkqtfA23yGXc5Jt+Z6ErrLo3RdOLr9csvdE0awbX
II1qg5r+yS6g3UKozkHkMji34rm1bzjR656u6b3Le9IqZ1lJlvN0EgW6tFI3b8YW
ou3UkhY3BvIW3BMCzw2srEeyBtDM3XXuzlIXGM7sfgpwQuwJ1bFGb5n7yqbeXIlt
GLUzIIlJu2HHwRbe9cA6Z+pDoMp7K4BPqhYjVG53DEyEVbghy11M0OnBibmSDpaJ
auZD4FNhj190S4f2/E0+dBTexuvDNOEozNIpAsfCXrQsfx1ySGaCFfGW5ZwqgNWQ
tKLwCr25AgMBAAECggEAWUf4Hg6J1frzmhUrz25DGOtmur4swWb1OjwcUk/4P1dv
+siAFFivMfFQrRPCRlrgZ8QOpyrSUdKSn2QcMswejgJoTrPBb7qV91ElOrwcvYDh
0bpdoSLQjxg3ZUFw+fXXtAjWqfrKPA3Q6qv3iVlURvCLK/91VUOiPpTULIJjmpi0
VuzdArOGJ+TtSAsw5WErwMeRtnYGksae8kmZi2BfhSBwHdRcGD/6+RLZ2rKKZju2
4lTr9wRWaWQxn9XZKFJizTcLJG8mNTgo58mViOH3A6dfUtLv2p+2Yce5wg0v1QRf
Hv5uFdM8G/pfck7u40RlNmQ9IElGUZtTcDNyvm69PQKBgQD8uR+0y2uZuU1V+srD
mhAVsl1ELiEVFB9U67USMwKqOpJ1CyeIwoVKLqQL1VSRn/E6rT25v0FBJQs9/7qG
PvjG4/6M38jU6cy7KujVFYSJM5DtXCWxDyqGvVUY+Znp7B6Xdv/1hZN8TD4X1Gxr
VoZQUmlR4HypcBmo9Xk2Vme8IwKBgQDIvAOHfofFmH+0aDeruND7Tf0tEAii1kV6
jSiLEkW+5dJPHP01iGOi3pq9JohQMHqjJiYUPUzG6YrXOGR+5oLmdGOOhbW861e/
Zm2hCfLiHvTtGl+uF0HGWkuzBonfdjTUyOAFnpOmFmFLTKJLtrBr8X9jSVrWNqOT
9Q38LUh+cwKBgA8lqVjUuGZGTPRSS8TdfwlN33kuqpzwz8/vMLMei5JYYF7ThFMW
FZcUpJBxANiZlYPGzmRLqkWVSs80fKF/NLn3AFLBNvBL8xFkyP+8gm0WwiD33Op3
1jytLGSK0UbL+Clr4Ht+vhA9IZucB8OHNBWsWtOleNNO/Lq7u8Ad/amxAoGBAKI7
AYcyBbz2gM9nIwcP+SYBY8pVmQUxszlWeBvdiqy7xPrXbPUk45Gv4tNYHvbgF11f
6YqV+EUSXnmOQ/ojhkuGaSe4fKbQdTxlJdju13NUnZI6rHVgqnIKa/+mGyuUtyH5
rsQb4yxqDfvzVX9niLHUnaW6lUVnJ1DezoyudFZtAoGANhfTDAa1WAbPo485NlZ9
JcOZPME6MbSa0mL915CWJBiPxUlOtOeHK1BOy5rSfiJyNlW6u9+K6+qFut/+Kaf+
uQhJBMlrQi4Xm2tCLHGE7SUbVwPijnrptQo8yLR34WnBcEmlSaAhULH3rKGLdVVO
eL1KMmQ4hTLu8dg0SWYKPvo=
-----END PRIVATE KEY-----`,
};

async function getAccessToken() {
  const now = Math.floor(Date.now() / 1000);
  const expiry = now + 3600;

  const alg = 'RS256';
  const pkcs8 = SERVICE_ACCOUNT.private_key.trim();
  const privateKey = await jose.importPKCS8(pkcs8, alg);

  const jwt = await new jose.SignJWT({
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
  })
    .setProtectedHeader({ alg })
    .setIssuer(SERVICE_ACCOUNT.client_email)
    .setAudience('https://oauth2.googleapis.com/token')
    .setIssuedAt(now)
    .setExpirationTime(expiry)
    .sign(privateKey);

  const response = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`,
  });

  const data = await response.json();
  if (data.error) {
    throw new Error(`Cloud Messaging Access Token Error: ${data.error_description || data.error}`);
  }
  return data.access_token;
}

export async function sendFCMNotification(title: string, body: string, targetRoute: string = '/') {
  try {
    const accessToken = await getAccessToken();
    const url = `https://fcm.googleapis.com/v1/projects/${SERVICE_ACCOUNT.project_id}/messages:send`;

    const message = {
      message: {
        topic: 'all',
        notification: {
          title,
          body,
        },
        android: {
          priority: 'high',
          notification: {
            channel_id: 'seydirehberim_notifications',
            click_action: 'FLUTTER_NOTIFICATION_CLICK',
            sound: 'default',
          },
        },
        data: {
          click_action: 'FLUTTER_NOTIFICATION_CLICK',
          id: '1',
          status: 'done',
          screen: targetRoute,
        },
      },
    };

    const response = await fetch(url, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${accessToken}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(message),
    });

    const result = await response.json();
    if (result.error) {
        throw new Error(`FCM Error: ${result.error.message}`);
    }
    return result;
  } catch (error) {
    console.error('FCM Send Error:', error);
    throw error;
  }
}
