import { type Href, router } from 'expo-router';
import { Tabs } from 'expo-router/js-tabs';
import { useEffect, useState } from 'react';
import { AppState } from 'react-native';

import { MainTabBar } from '@/components/main-tab-bar';
import { updateDisplayName } from '@/features/auth/auth-actions';
import { useAuthStore } from '@/features/auth/auth-store';
import { NameRequestDialog } from '@/features/auth/name-request-dialog';
import { SurveyDialogHost } from '@/features/survey/survey-dialog';
import { scheduleDailyNotifications, setNotificationNavigator } from '@/services/notifications';
import { checkForUpdate } from '@/services/update';

// Flutter main_shell.dart karşılığı: Ana Sayfa / Haberler / Ayarlar. Android geri tuşu önce Ana Sayfa'ya döner.
// Açılışta aktif anket varsa anket penceresi gösterilir ve Android'de mağaza güncellemesi kontrol edilir.
const TAB_ROUTES = new Set(['/', '/news', '/settings']);

export default function TabsLayout() {
  const needsName = useAuthStore(
    (state) => state.user != null && !state.user.isAnonymous && !state.user.displayName?.trim(),
  );
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    checkForUpdate();

    // Bildirim yönlendirmesi: sekme yolları sekme değiştirir, diğerleri sayfa açar.
    setNotificationNavigator((route) => {
      setTimeout(() => {
        if (TAB_ROUTES.has(route)) router.navigate(route as Href);
        else router.push(route as Href);
      }, 0);
    });

    // Uygulama ön plana geldiğinde bildirim planını güncelle (yeni gün için)
    const subscription = AppState.addEventListener('change', (state) => {
      if (state === 'active') {
        scheduleDailyNotifications().catch((error) => console.warn('DailyNotif reschedule error:', error));
      }
    });

    return () => {
      setNotificationNavigator(null);
      subscription.remove();
    };
  }, []);

  return (
    <>
      <Tabs
        tabBar={(props) => <MainTabBar {...props} />}
        backBehavior="firstRoute"
        screenOptions={{ headerShown: false }}>
        <Tabs.Screen name="index" />
        <Tabs.Screen name="news" />
        <Tabs.Screen name="settings" />
      </Tabs>
      <SurveyDialogHost />
      <NameRequestDialog
        visible={needsName && !saving}
        onSave={async (fullName) => {
          setSaving(true);
          try {
            await updateDisplayName(fullName);
          } finally {
            setSaving(false);
          }
        }}
      />
    </>
  );
}
