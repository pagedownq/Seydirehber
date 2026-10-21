import {
  Poppins_400Regular,
  Poppins_500Medium,
  Poppins_600SemiBold,
  Poppins_700Bold,
  Poppins_800ExtraBold,
  Poppins_900Black,
  useFonts,
} from '@expo-google-fonts/poppins';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { DefaultTheme, Stack, ThemeProvider } from 'expo-router';
import * as SplashScreen from 'expo-splash-screen';
import { StatusBar } from 'expo-status-bar';
import { useEffect, useState } from 'react';
import { GestureHandlerRootView } from 'react-native-gesture-handler';
import { SafeAreaProvider } from 'react-native-safe-area-context';

import { AppNotificationHost } from '@/components/app-notification';
import { ConfirmDialogHost } from '@/components/confirm-dialog';
import { SnackbarHost } from '@/components/snackbar';
import { useOnboardingStore } from '@/features/auth/onboarding-store';
import { ForumRulesSheetHost } from '@/features/forum/forum-rules-sheet';
import { useScreenTracking } from '@/services/analytics';
import { initApp } from '@/services/startup';
import { colors } from '@/theme';

SplashScreen.preventAutoHideAsync();

const queryClient = new QueryClient();

const navigationTheme = {
  ...DefaultTheme,
  colors: {
    ...DefaultTheme.colors,
    primary: colors.primary,
    background: colors.background,
    card: colors.white,
    text: colors.textPrimary,
    border: colors.divider,
  },
};

export default function RootLayout() {
  const [fontsLoaded, fontError] = useFonts({
    Poppins_400Regular,
    Poppins_500Medium,
    Poppins_600SemiBold,
    Poppins_700Bold,
    Poppins_800ExtraBold,
    Poppins_900Black,
  });
  const [servicesReady, setServicesReady] = useState(false);
  const onboardingCompleted = useOnboardingStore((state) => state.completed);

  useEffect(() => {
    // Flutter StartupWrapper gibi: servisler hazır olana kadar açılış ekranı kalır.
    initApp()
      .catch((error) => console.warn('Kritik Hata:', error))
      .finally(() => setServicesReady(true));
  }, []);

  const ready = (fontsLoaded || fontError != null) && servicesReady;

  useEffect(() => {
    if (ready) SplashScreen.hideAsync();
  }, [ready]);

  if (!ready) return null;

  return (
    <GestureHandlerRootView style={{ flex: 1 }}>
      <SafeAreaProvider>
        <QueryClientProvider client={queryClient}>
          <ThemeProvider value={navigationTheme}>
            <ScreenTracker />
            <StatusBar style="dark" />
            {/* Flutter router redirect: onboarding bitmeden diğer ekranlara gidilmez. */}
            <Stack screenOptions={{ headerShown: false }}>
              {/* redirectTo açıkça verilmeli; yoksa Expo Router kilitli ekrandan ilk açık rotaya (ör. /vefat) atıyor. */}
              <Stack.Protected guard={!onboardingCompleted} redirectTo="/">
                <Stack.Screen name="onboarding" />
              </Stack.Protected>
              <Stack.Protected guard={onboardingCompleted} redirectTo="/onboarding">
                <Stack.Screen name="(tabs)" />
              </Stack.Protected>
            </Stack>
            <ForumRulesSheetHost />
            <ConfirmDialogHost />
            <AppNotificationHost />
            <SnackbarHost />
          </ThemeProvider>
        </QueryClientProvider>
      </SafeAreaProvider>
    </GestureHandlerRootView>
  );
}

function ScreenTracker() {
  useScreenTracking();
  return null;
}
