import { MaterialCommunityIcons, MaterialIcons } from '@expo/vector-icons';
import { LinearGradient } from 'expo-linear-gradient';
import * as Location from 'expo-location';
import LottieView from 'lottie-react-native';
import type { ComponentProps, ReactNode } from 'react';
import { useEffect, useRef, useState } from 'react';
import {
  Alert,
  Image,
  Linking,
  Platform,
  Pressable,
  ScrollView,
  StyleSheet,
  Text,
  useWindowDimensions,
  View,
} from 'react-native';
import Animated, {
  Easing,
  interpolate,
  useAnimatedScrollHandler,
  useAnimatedStyle,
  useSharedValue,
  withTiming,
  type SharedValue,
} from 'react-native-reanimated';
import { SafeAreaView } from 'react-native-safe-area-context';

import { PolicySheet } from '@/components/policy-sheet';
import { showSnackbar, snackbarColors } from '@/components/snackbar';
import {
  continueAsGuest,
  signInWithApple,
  signInWithGoogle,
  updateDisplayName,
  useAuthLoading,
} from '@/features/auth/auth-actions';
import { askForName, NameEntryDialogHost } from '@/features/auth/name-entry-dialog';
import { completeOnboarding } from '@/features/auth/onboarding-store';
import { KVKK_CONTENT, PRIVACY_POLICY_CONTENT, TERMS_OF_SERVICE_CONTENT } from '@/features/policies/content';
import { auth } from '@/services/firebase';
import { haptics } from '@/services/haptics';
import { getNotificationPermission, requestNotificationPermission } from '@/services/notification-permission';
import { colors, fonts, gradients, typography } from '@/theme';

// Flutter lib/features/auth/screens/onboarding_screen.dart karşılığı.
type IconName = ComponentProps<typeof MaterialIcons>['name'];

type PageData = {
  icon: IconName;
  lottie?: ComponentProps<typeof LottieView>['source'];
  title: string;
  description: string;
  hasPrivacyCheckbox?: boolean;
  hasAuthButtons?: boolean;
  hasNotificationButton?: boolean;
  hasLocationButton?: boolean;
  mockup?: 'services' | 'daily';
};

const PAGES: PageData[] = [
  {
    icon: 'location-city',
    lottie: require('@/assets/animations/merhaba.json'),
    title: "Seydi Rehber'e Hoş Geldin",
    description: 'Şehrindeki her şeyi keşfetmek için en doğru yerdesin. Modern ve hızlı rehberinle tanış!',
  },
  {
    icon: 'map',
    lottie: require('@/assets/animations/location.json'),
    title: 'Konum İzni',
    description:
      'Tamamen yenilenen haritamızla şehri keşfet. Önemli konumlar ve ulaşım her an parmaklarının ucunda!',
    hasLocationButton: true,
  },
  {
    icon: 'grid-view',
    title: 'Hızlı Hizmetler',
    description:
      'Nöbetçi eczaneler, otobüs saatleri ve pazar yerleri gibi ihtiyacın olan her şey elinin altında.',
    mockup: 'services',
  },
  {
    icon: 'explore',
    title: 'Şehri Keşfet',
    description: 'Hava durumunu takip et, en güncel haberleri oku ve sana özel fırsat kuponlarını kaçırma!',
    mockup: 'daily',
  },
  {
    icon: 'security',
    title: 'Gizlilik ve Güvenlik',
    description:
      'Verileriniz bizimle güvende. Devam etmeden önce lütfen kullanım koşullarımızı onaylayın.',
    hasPrivacyCheckbox: true,
  },
  {
    icon: 'notifications-active',
    title: 'Bildirimleri Aç',
    description:
      'En güncel duyurular, etkinlikler ve hizmetlerden anında haberdar olmak için bildirimleri aktif edin.',
    hasNotificationButton: true,
  },
  {
    icon: 'rocket-launch',
    title: 'Keşfetmeye Hazırsın!',
    description:
      'Google hesabınla giriş yaparak profilini oluşturabilir veya misafir olarak devam edebilirsin.',
    hasAuthButtons: true,
  },
];

const PRIVACY_PAGE = 4;

export function OnboardingScreen() {
  const { width, height } = useWindowDimensions();
  const isSmallScreen = height < 700;
  const scrollRef = useRef<Animated.ScrollView>(null);
  const scrollX = useSharedValue(0);
  const [currentPage, setCurrentPage] = useState(0);
  const [privacyAccepted, setPrivacyAccepted] = useState(false);
  const [policy, setPolicy] = useState<{ title: string; content: string } | null>(null);

  const scrollHandler = useAnimatedScrollHandler((event) => {
    scrollX.value = event.contentOffset.x;
  });

  const nextPage = () => {
    haptics.light();
    if (currentPage === PRIVACY_PAGE && !privacyAccepted) {
      showSnackbar({
        message: 'Devam etmek için gizlilik politikasını onaylayın',
        backgroundColor: colors.error,
        bottomRatio: 0.1,
        borderRadius: 12,
      });
      return;
    }
    if (currentPage < PAGES.length - 1) {
      scrollRef.current?.scrollTo({ x: (currentPage + 1) * width, animated: true });
    }
  };

  return (
    <View style={styles.root}>
      <LinearGradient
        colors={[colors.white, 'rgba(76, 175, 80, 0.01)', 'rgba(76, 175, 80, 0.05)']}
        style={StyleSheet.absoluteFill}
      />
      <SafeAreaView style={{ flex: 1 }}>
        <Animated.ScrollView
          ref={scrollRef}
          horizontal
          pagingEnabled
          bounces
          showsHorizontalScrollIndicator={false}
          scrollEnabled={!(currentPage === PRIVACY_PAGE && !privacyAccepted)}
          onScroll={scrollHandler}
          scrollEventThrottle={16}
          onMomentumScrollEnd={(event) =>
            setCurrentPage(Math.round(event.nativeEvent.contentOffset.x / width))
          }
          style={{ flex: 1 }}>
          {PAGES.map((page, index) => (
            <View key={page.title} style={{ width }}>
              <OnboardingPage
                page={page}
                active={index === currentPage}
                isSmallScreen={isSmallScreen}
                privacyAccepted={privacyAccepted}
                onTogglePrivacy={() => setPrivacyAccepted((value) => !value)}
                onOpenPolicy={setPolicy}
              />
            </View>
          ))}
        </Animated.ScrollView>

        <View style={[styles.bottom, { paddingVertical: isSmallScreen ? 8 : 16 }]}>
          <BottomActions page={PAGES[currentPage]} isSmallScreen={isSmallScreen} onNext={nextPage} />
          <View style={{ height: isSmallScreen ? 12 : 24 }} />
          <PageIndicator count={PAGES.length} scrollX={scrollX} pageWidth={width} />
        </View>
      </SafeAreaView>

      <PolicySheet policy={policy} onClose={() => setPolicy(null)} />
      <NameEntryDialogHost />
    </View>
  );
}

// Flutter ExpandingDotsEffect: 6x6 nokta, aktif olan 4 katı genişler, aralık 8.
function PageIndicator({
  count,
  scrollX,
  pageWidth,
}: {
  count: number;
  scrollX: SharedValue<number>;
  pageWidth: number;
}) {
  return (
    <View style={styles.indicator}>
      {Array.from({ length: count }, (_, index) => (
        <Dot key={index} index={index} scrollX={scrollX} pageWidth={pageWidth} />
      ))}
    </View>
  );
}

function Dot({ index, scrollX, pageWidth }: { index: number; scrollX: SharedValue<number>; pageWidth: number }) {
  const style = useAnimatedStyle(() => {
    const position = scrollX.value / pageWidth;
    const t = interpolate(Math.abs(position - index), [0, 1], [1, 0], 'clamp');
    return {
      width: 6 + 18 * t,
      backgroundColor: t > 0.5 ? colors.primary : 'rgba(76, 175, 80, 0.2)',
    };
  });
  return <Animated.View style={[styles.dot, style]} />;
}

// Flutter TweenAnimationBuilder: sayfa görünür olduğunda içerik süzülerek gelir.
function useEntrance(active: boolean, duration: number) {
  const progress = useSharedValue(0);
  useEffect(() => {
    if (active) {
      progress.value = 0;
      progress.value = withTiming(1, { duration, easing: Easing.linear });
    }
  }, [active, duration, progress]);
  return progress;
}

function FadeSlide({
  active,
  duration,
  offset,
  children,
}: {
  active: boolean;
  duration: number;
  offset: number;
  children: ReactNode;
}) {
  const progress = useEntrance(active, duration);
  const style = useAnimatedStyle(() => ({
    opacity: progress.value,
    transform: [{ translateY: offset * (1 - progress.value) }],
  }));
  return <Animated.View style={style}>{children}</Animated.View>;
}

function ScaleIn({ active, children }: { active: boolean; children: ReactNode }) {
  const progress = useEntrance(active, 1000);
  const style = useAnimatedStyle(() => ({
    opacity: progress.value,
    transform: [{ scale: progress.value }],
  }));
  return <Animated.View style={style}>{children}</Animated.View>;
}

function OnboardingPage({
  page,
  active,
  isSmallScreen,
  privacyAccepted,
  onTogglePrivacy,
  onOpenPolicy,
}: {
  page: PageData;
  active: boolean;
  isSmallScreen: boolean;
  privacyAccepted: boolean;
  onTogglePrivacy: () => void;
  onOpenPolicy: (policy: { title: string; content: string }) => void;
}) {
  const lottieBox = isSmallScreen ? 200 : 260;
  const iconBox = isSmallScreen ? 120 : 160;
  const iconInner = isSmallScreen ? 90 : 120;

  return (
    <ScrollView contentContainerStyle={styles.pageContent} bounces>
      <View style={{ flex: 2 }} />
      {page.mockup ? (
        <FadeSlide active={active} duration={800} offset={10}>
          <Mockup type={page.mockup} />
        </FadeSlide>
      ) : page.lottie ? (
        <ScaleIn active={active}>
          <View style={[styles.lottieCard, { width: lottieBox, height: lottieBox }]}>
            <View style={styles.lottieClip}>
              <LottieView source={page.lottie} autoPlay loop resizeMode="contain" style={{ flex: 1 }} />
            </View>
          </View>
        </ScaleIn>
      ) : (
        <View style={[styles.iconCard, { width: iconBox, height: iconBox }]}>
          <LinearGradient
            colors={['rgba(76, 175, 80, 0.2)', 'rgba(76, 175, 80, 0.05)']}
            start={{ x: 0, y: 0 }}
            end={{ x: 1, y: 1 }}
            style={[styles.iconInner, { width: iconInner, height: iconInner }]}
          />
          <MaterialIcons name={page.icon} size={isSmallScreen ? 50 : 70} color={colors.primary} />
        </View>
      )}

      <View style={{ height: isSmallScreen ? 24 : 48 }} />
      <FadeSlide active={active} duration={600} offset={20}>
        <Text style={[styles.title, { fontSize: isSmallScreen ? 22 : 28 }]}>{page.title}</Text>
      </FadeSlide>
      <View style={{ height: isSmallScreen ? 8 : 16 }} />
      <FadeSlide active={active} duration={800} offset={20}>
        <Text
          style={[
            styles.description,
            { fontSize: isSmallScreen ? 14 : 16, lineHeight: (isSmallScreen ? 14 : 16) * 1.4 },
          ]}>
          {page.description}
        </Text>
      </FadeSlide>
      <View style={{ flex: 3 }} />

      {page.hasPrivacyCheckbox && (
        <View style={[styles.privacyCard, { marginTop: isSmallScreen ? 16 : 32 }]}>
          <Pressable onPress={onTogglePrivacy} style={styles.privacyRow}>
            <View style={[styles.checkbox, privacyAccepted && styles.checkboxChecked]}>
              {privacyAccepted && <MaterialIcons name="check" size={14} color={colors.white} />}
            </View>
            <Text style={styles.privacyText}>
              <Text
                style={styles.policyLink}
                onPress={() => onOpenPolicy({ title: 'Gizlilik Politikası', content: PRIVACY_POLICY_CONTENT })}>
                Gizlilik Politikası
              </Text>
              {', '}
              <Text
                style={styles.policyLink}
                onPress={() => onOpenPolicy({ title: 'Kullanım Koşulları', content: TERMS_OF_SERVICE_CONTENT })}>
                Kullanım Koşulları
              </Text>
              {' ve '}
              <Text
                style={styles.policyLink}
                onPress={() => onOpenPolicy({ title: 'KVKK Aydınlatma Metni', content: KVKK_CONTENT })}>
                KVKK Metni
              </Text>
              {"'ni okudum ve kabul ediyorum"}
            </Text>
          </Pressable>
        </View>
      )}
      <View style={{ height: isSmallScreen ? 16 : 32 }} />
    </ScrollView>
  );
}

function Mockup({ type }: { type: 'services' | 'daily' }) {
  if (type === 'services') {
    return (
      <View style={{ gap: 12 }}>
        <View style={styles.mockupRow}>
          <MockupServiceCard title="Nöbetçi Eczane" icon="local-pharmacy" color="#EF5350" />
          <MockupServiceCard title="Otobüs Saatleri" icon="directions-bus" color="#26A69A" />
        </View>
        <View style={styles.mockupRow}>
          <MockupServiceCard title="Noterler" icon="gavel" color="#455A64" />
          <MockupServiceCard title="Halk Pazarları" icon="storefront" color="#FFB300" />
        </View>
      </View>
    );
  }

  return (
    <View style={{ alignItems: 'center' }}>
      <LinearGradient
        colors={gradients.weather}
        start={{ x: 0, y: 0 }}
        end={{ x: 1, y: 1 }}
        style={styles.weatherMockup}>
        <MaterialIcons name="cloud-queue" size={28} color={colors.white} />
        <View>
          <Text style={styles.weatherTitle}>Hava Durumu</Text>
          <Text style={styles.weatherSubtitle}>Seydişehir 18°C</Text>
        </View>
      </LinearGradient>
      <View style={{ height: 16 }} />
      <View style={styles.mockupRow}>
        <View style={styles.chip}>
          <MaterialIcons name="newspaper" size={18} color="#2E7D32" />
          <Text style={styles.chipText}>Güncel Haberler</Text>
        </View>
        <View style={styles.chip}>
          <MaterialIcons name="local-offer" size={18} color="#E53935" />
          <Text style={styles.chipText}>Kuponlar</Text>
        </View>
      </View>
    </View>
  );
}

function MockupServiceCard({ title, icon, color }: { title: string; icon: IconName; color: string }) {
  return (
    <View style={[styles.serviceCard, { backgroundColor: color, shadowColor: color }]}>
      <MaterialIcons name={icon} size={20} color={colors.white} />
      <Text style={styles.serviceTitle}>{title}</Text>
    </View>
  );
}

function PrimaryButton({ text, icon, onPress }: { text: string; icon?: IconName; onPress: () => void }) {
  return (
    <Pressable onPress={onPress} style={({ pressed }) => [styles.primaryButton, pressed && styles.pressed]}>
      {icon && <MaterialIcons name={icon} size={24} color={colors.primary} />}
      <Text style={styles.primaryButtonText}>{text}</Text>
    </Pressable>
  );
}

function SecondaryTextButton({ text, onPress }: { text: string; onPress: () => void }) {
  return (
    <Pressable onPress={onPress} style={styles.textButton}>
      <Text style={styles.textButtonText}>{text}</Text>
    </Pressable>
  );
}

function BottomActions({
  page,
  isSmallScreen,
  onNext,
}: {
  page: PageData;
  isSmallScreen: boolean;
  onNext: () => void;
}) {
  if (page.hasAuthButtons) return <AuthButtons isSmallScreen={isSmallScreen} />;

  if (page.hasNotificationButton) {
    return (
      <View>
        <PrimaryButton
          text="Bildirimleri Etkinleştir"
          icon="notifications-active"
          onPress={async () => {
            haptics.light();
            const status = await getNotificationPermission();
            if (status === 'permanentlyDenied') {
              const confirmed = await confirmPlatform(
                'Bildirim İzni Gerekli',
                'Bildirimleri alabilmek için ayarlardan izin vermeniz gerekmektedir. Ayarlara gitmek ister misiniz?',
                'Ayarlara Git',
                'Vazgeç',
              );
              if (confirmed) Linking.openSettings();
              return;
            }
            const granted = await requestNotificationPermission();
            if (granted) {
              showSnackbar({
                message: 'Bildirimler başarıyla açıldı!',
                backgroundColor: snackbarColors.green,
                floating: false,
              });
              onNext();
            } else {
              showSnackbar({
                message: 'Bildirim izni verilmedi.',
                backgroundColor: snackbarColors.error,
                floating: false,
              });
            }
          }}
        />
        <SecondaryTextButton text="Daha Sonra" onPress={onNext} />
      </View>
    );
  }

  if (page.hasLocationButton) {
    return (
      <View>
        <PrimaryButton
          text="Konum İznini Ver"
          icon="location-on"
          onPress={async () => {
            haptics.medium();

            // 1. Telefonun genel GPS'i açık mı?
            if (!(await Location.hasServicesEnabledAsync())) {
              showSnackbar({
                message:
                  "Telefonunuzun GPS'i kapalı. Ayarlar > Gizlilik ve Güvenlik > Konum Servisleri yolundan aktif edebilirsiniz.",
                backgroundColor: snackbarColors.redAccent,
                durationMs: 5000,
                action: { label: 'AYARLARA GİT', onPress: openLocationSettings },
              });
              return;
            }

            // 2. Uygulama izni kalıcı olarak reddedilmiş mi?
            const current = await Location.getForegroundPermissionsAsync();
            if (current.status === 'denied' && !current.canAskAgain) {
              showSnackbar({
                message: 'Konum izni kalıcı olarak reddedildi. Lütfen ayarlardan manuel açın.',
                backgroundColor: snackbarColors.orange,
                action: { label: 'AYARLAR', onPress: () => Linking.openSettings() },
              });
              return;
            }

            const result = await Location.requestForegroundPermissionsAsync();
            if (result.granted) {
              showSnackbar({ message: 'Konum izni başarıyla alındı!', backgroundColor: snackbarColors.green });
              onNext();
            } else if (!result.canAskAgain) {
              showSnackbar({
                message: 'Konum izni reddedildi. Özellikleri kullanmak için ayarlardan açabilirsiniz.',
                backgroundColor: snackbarColors.orange,
                action: { label: 'AYARLAR', onPress: () => Linking.openSettings() },
              });
            } else {
              showSnackbar({ message: 'Konum izni verilmedi.', backgroundColor: snackbarColors.error });
              // Apple, izin verilmese de akışın devam etmesini istiyor.
              onNext();
            }
          }}
        />
        <SecondaryTextButton text="Atla" onPress={onNext} />
      </View>
    );
  }

  return <PrimaryButton text="Devam Et" onPress={onNext} />;
}

function AuthButtons({ isSmallScreen }: { isSmallScreen: boolean }) {
  const loading = useAuthLoading((state) => state.loading);
  const buttonHeight = isSmallScreen ? 48 : 54;
  const fontSize = isSmallScreen ? 14 : 16;
  const gap = isSmallScreen ? 8 : 12;

  // Flutter'daki gibi: giriş iptal edilse ya da başarısız olsa da onboarding tamamlanır ve ana sayfaya geçilir.
  const finishAfterSignIn = async () => {
    const user = auth.currentUser;
    if (user && !user.displayName) {
      const name = await askForName();
      if (name) await updateDisplayName(name);
    }
    await completeOnboarding();
  };

  return (
    <View style={{ gap }}>
      {Platform.OS === 'ios' && (
        <Pressable
          disabled={loading}
          onPress={async () => {
            haptics.light();
            await signInWithApple();
            await finishAfterSignIn();
          }}
          style={[styles.authButton, styles.appleButton, { height: buttonHeight }]}>
          <MaterialCommunityIcons name="apple" size={isSmallScreen ? 22 : 26} color="#000000" />
          <Text style={[styles.authText, { fontSize, color: 'rgba(0, 0, 0, 0.85)' }]}>
            {loading ? 'Giriş yapılıyor...' : 'Apple ile Giriş Yap'}
          </Text>
        </Pressable>
      )}
      <Pressable
        disabled={loading}
        onPress={async () => {
          haptics.light();
          await signInWithGoogle();
          await finishAfterSignIn();
        }}
        style={[styles.authButton, styles.googleButton, { height: buttonHeight }]}>
        <GoogleIcon size={isSmallScreen ? 18 : 22} />
        <Text style={[styles.authText, { fontSize, color: colors.primary }]}>
          {loading ? 'Giriş yapılıyor...' : 'Google ile Giriş Yap'}
        </Text>
      </Pressable>
      <Pressable
        disabled={loading}
        onPress={async () => {
          haptics.selection();
          await continueAsGuest();
          await completeOnboarding();
        }}
        style={[styles.authButton, styles.guestButton, { height: buttonHeight }]}>
        <Text style={[styles.authText, { fontSize, color: 'rgba(76, 175, 80, 0.8)' }]}>
          Misafir Olarak Devam Et
        </Text>
      </Pressable>
    </View>
  );
}

// Flutter: Image.network('https://www.google.com/favicon.ico'), yüklenemezse login ikonu.
function GoogleIcon({ size }: { size: number }) {
  const [failed, setFailed] = useState(false);
  if (failed) return <MaterialIcons name="login" size={24} color={colors.primary} />;
  return (
    <Image
      source={{ uri: 'https://www.google.com/favicon.ico' }}
      style={{ width: size, height: size }}
      onError={() => setFailed(true)}
    />
  );
}

function openLocationSettings() {
  if (Platform.OS === 'android') {
    Linking.sendIntent('android.settings.LOCATION_SOURCE_SETTINGS').catch(() => Linking.openSettings());
  } else {
    Linking.openSettings();
  }
}

// Flutter _showPlatformConfirmDialog: iOS'ta Cupertino, Android'de Material sistem dialog'u.
function confirmPlatform(title: string, content: string, confirmText: string, cancelText: string) {
  return new Promise<boolean>((resolve) => {
    Alert.alert(
      title,
      content,
      [
        { text: cancelText, style: 'cancel', onPress: () => resolve(false) },
        { text: confirmText, onPress: () => resolve(true) },
      ],
      { cancelable: true, onDismiss: () => resolve(false) },
    );
  });
}

const styles = StyleSheet.create({
  root: {
    flex: 1,
    backgroundColor: colors.white,
  },
  bottom: {
    paddingHorizontal: 24,
  },
  indicator: {
    flexDirection: 'row',
    justifyContent: 'center',
    gap: 8,
  },
  dot: {
    height: 6,
    borderRadius: 3,
  },
  pageContent: {
    flexGrow: 1,
    alignItems: 'center',
    paddingHorizontal: 32,
  },
  lottieCard: {
    padding: 24,
    borderRadius: 48,
    backgroundColor: colors.white,
    shadowColor: colors.primary,
    shadowOpacity: 0.12,
    shadowRadius: 20,
    shadowOffset: { width: 0, height: 12 },
    elevation: 8,
  },
  lottieClip: {
    flex: 1,
    borderRadius: 32,
    overflow: 'hidden',
  },
  iconCard: {
    alignItems: 'center',
    justifyContent: 'center',
    borderRadius: 40,
    backgroundColor: colors.white,
    shadowColor: colors.primary,
    shadowOpacity: 0.15,
    shadowRadius: 15,
    shadowOffset: { width: 0, height: 10 },
    elevation: 8,
  },
  iconInner: {
    position: 'absolute',
    borderRadius: 32,
  },
  title: {
    ...typography.heading1,
    fontFamily: fonts.black,
    letterSpacing: -0.5,
    textAlign: 'center',
  },
  description: {
    ...typography.bodyLarge,
    paddingHorizontal: 16,
    color: colors.textSecondary,
    textAlign: 'center',
  },
  privacyCard: {
    alignSelf: 'stretch',
    borderRadius: 20,
    borderWidth: 1.2,
    borderColor: 'rgba(76, 175, 80, 0.2)',
    backgroundColor: 'rgba(255, 255, 255, 0.7)',
    shadowColor: '#000000',
    shadowOpacity: 0.02,
    shadowRadius: 10,
    shadowOffset: { width: 0, height: 4 },
  },
  privacyRow: {
    minHeight: 56,
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 8,
    paddingVertical: 8,
    gap: 16,
  },
  checkbox: {
    width: 18,
    height: 18,
    marginLeft: 8,
    alignItems: 'center',
    justifyContent: 'center',
    borderRadius: 2,
    borderWidth: 2,
    borderColor: colors.textSecondary,
  },
  checkboxChecked: {
    borderColor: colors.primary,
    backgroundColor: colors.primary,
  },
  privacyText: {
    ...typography.bodySmall,
    flex: 1,
    fontSize: 10,
  },
  policyLink: {
    fontFamily: fonts.bold,
    color: colors.primary,
    textDecorationLine: 'underline',
  },
  mockupRow: {
    flexDirection: 'row',
    justifyContent: 'center',
    gap: 12,
  },
  serviceCard: {
    width: 120,
    height: 70,
    padding: 12,
    justifyContent: 'space-between',
    borderRadius: 16,
    shadowOpacity: 0.3,
    shadowRadius: 8,
    shadowOffset: { width: 0, height: 4 },
    elevation: 4,
  },
  serviceTitle: {
    fontFamily: fonts.bold,
    fontSize: 10,
    color: colors.white,
  },
  weatherMockup: {
    width: 200,
    padding: 12,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
    borderRadius: 20,
    backgroundColor: gradients.weather[0],
    shadowColor: colors.primary,
    shadowOpacity: 0.2,
    shadowRadius: 15,
    shadowOffset: { width: 0, height: 8 },
    elevation: 6,
  },
  weatherTitle: {
    fontFamily: fonts.bold,
    fontSize: 13,
    color: colors.white,
  },
  weatherSubtitle: {
    fontFamily: fonts.regular,
    fontSize: 11,
    color: 'rgba(255, 255, 255, 0.8)',
  },
  chip: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    paddingHorizontal: 16,
    paddingVertical: 10,
    borderRadius: 16,
    backgroundColor: colors.white,
    shadowColor: '#000000',
    shadowOpacity: 0.05,
    shadowRadius: 10,
    elevation: 2,
  },
  chipText: {
    fontFamily: fonts.semiBold,
    fontSize: 12,
    color: colors.textPrimary,
  },
  primaryButton: {
    height: 56,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 8,
    borderRadius: 20,
    borderWidth: 1.5,
    borderColor: 'rgba(255, 255, 255, 0.2)',
    backgroundColor: 'rgba(76, 175, 80, 0.2)',
    shadowColor: colors.primary,
    shadowOpacity: 0.12,
    shadowRadius: 20,
    shadowOffset: { width: 0, height: 10 },
  },
  pressed: {
    opacity: 0.8,
  },
  primaryButtonText: {
    fontFamily: fonts.bold,
    fontSize: 16,
    letterSpacing: 0.5,
    color: colors.primary,
  },
  textButton: {
    alignSelf: 'center',
    paddingHorizontal: 12,
    paddingVertical: 10,
  },
  textButtonText: {
    fontFamily: fonts.medium,
    fontSize: 14,
    color: 'rgba(76, 175, 80, 0.7)',
  },
  authButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 8,
    borderRadius: 20,
    borderWidth: 1.5,
  },
  appleButton: {
    backgroundColor: 'rgba(255, 255, 255, 0.9)',
    borderColor: 'rgba(76, 175, 80, 0.15)',
    shadowColor: '#000000',
    shadowOpacity: 0.05,
    shadowRadius: 10,
    shadowOffset: { width: 0, height: 4 },
  },
  googleButton: {
    backgroundColor: 'rgba(76, 175, 80, 0.1)',
    borderColor: 'rgba(76, 175, 80, 0.2)',
  },
  guestButton: {
    backgroundColor: 'rgba(76, 175, 80, 0.05)',
    borderColor: 'rgba(76, 175, 80, 0.1)',
  },
  authText: {
    fontFamily: fonts.bold,
  },
});
