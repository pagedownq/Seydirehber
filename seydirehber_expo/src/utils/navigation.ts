import { type Href, router } from 'expo-router';

/**
 * Flutter context.pop() karşılığı. Geçmiş yoksa (bildirimden/bağlantıdan doğrudan açılan ekran,
 * geri tuşuna art arda basma) GO_BACK hatası vermek yerine Ana Sayfa'ya döner.
 */
export function goBack() {
  if (router.canGoBack()) router.back();
  else router.replace('/' as Href);
}
