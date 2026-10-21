import { MaterialCommunityIcons, MaterialIcons } from '@expo/vector-icons';
import { collection, getDocs, limit, query, where } from '@react-native-firebase/firestore';
import { LinearGradient } from 'expo-linear-gradient';
import { type ComponentProps, useEffect, useState } from 'react';
import { Linking, Modal, Pressable, StyleSheet, Text, useWindowDimensions, View } from 'react-native';
import Animated, { Easing, FadeIn, ZoomIn } from 'react-native-reanimated';

import { showSnackbar } from '@/components/snackbar';
import { db } from '@/services/firebase';
import { haptics } from '@/services/haptics';
import { getItem, setItem, surveyCompletedKey } from '@/services/storage';
import { colors, fonts, typography } from '@/theme';

// Flutter lib/core/widgets/survey_dialog.dart karşılığı:
// "Ankete Başla" → form linki açılır, bir daha gösterilmez; "Sonra Hatırlat" → sonraki açılışta tekrar.
type Survey = { id: string; url: string; title: string; description: string | null };

async function findPendingSurvey(): Promise<Survey | null> {
  // 1. Firestore'dan aktif anketi çek
  const snapshot = await getDocs(query(collection(db, 'surveys'), where('isActive', '==', true), limit(1)));
  const doc = snapshot.docs[0];
  if (!doc) return null;

  const data = doc.data() as Record<string, unknown>;
  const url = typeof data.url === 'string' ? data.url : '';
  if (!url) return null;

  // 2. Bu anket ID'si tamamlanmış mı kontrol et
  if ((await getItem<boolean>(surveyCompletedKey(doc.id))) ?? false) return null;

  return {
    id: doc.id,
    url,
    title: typeof data.title === 'string' ? data.title : 'Görüşün Bizim İçin\nÇok Değerli! 💚',
    description: typeof data.description === 'string' ? data.description : null,
  };
}

/** MainShell açılışında (sekmeler yüklenince) bir kez kontrol eder. */
export function SurveyDialogHost() {
  const [survey, setSurvey] = useState<Survey | null>(null);

  useEffect(() => {
    let timer: ReturnType<typeof setTimeout> | undefined;
    let cancelled = false;
    findPendingSurvey()
      .then((found) => {
        if (!found || cancelled) return;
        // Ekran yüklendikten kısa bir süre sonra göster
        timer = setTimeout(() => setSurvey(found), 800);
      })
      .catch((error) => console.warn('SurveyDialog error:', error));
    return () => {
      cancelled = true;
      if (timer) clearTimeout(timer);
    };
  }, []);

  return <SurveyDialog survey={survey} onClose={() => setSurvey(null)} />;
}

function SurveyDialog({ survey, onClose }: { survey: Survey | null; onClose: () => void }) {
  const { width } = useWindowDimensions();
  if (!survey) return null;

  const onStart = async () => {
    haptics.medium();
    // URL şemasını kontrol et ve gerekirse https:// ekle
    const link = survey.url.startsWith('http') ? survey.url : `https://${survey.url}`;
    try {
      await Linking.openURL(link);
      // Sadece başarılı şekilde açıldıysa tamamlandı olarak işaretle → bir daha gösterilmeyecek
      await setItem(surveyCompletedKey(survey.id), true);
    } catch {
      showSnackbar({ message: 'Anket bağlantısı açılamadı.', backgroundColor: colors.error, borderRadius: 12 });
    }
    onClose();
  };

  const onSkip = () => {
    haptics.selection();
    // Sadece kapat – kaydetmiyoruz, bir sonraki açılışta tekrar gösterilecek
    onClose();
  };

  return (
    <Modal visible transparent animationType="none" statusBarTranslucent onRequestClose={onSkip}>
      <Animated.View entering={FadeIn.duration(400)} style={styles.barrier}>
        <Pressable style={StyleSheet.absoluteFill} onPress={onSkip} />
        <Animated.View
          entering={ZoomIn.duration(400).easing(Easing.out(Easing.back(1.7)))}
          style={[styles.dialog, { width: Math.min(width * 0.88, 400) }]}>
          <LinearGradient
            colors={['#43A047', '#66BB6A', '#81C784']}
            start={{ x: 0, y: 0 }}
            end={{ x: 1, y: 1 }}
            style={styles.header}>
            <View style={styles.headerIcon}>
              <MaterialCommunityIcons name="clipboard-text-outline" size={38} color={colors.white} />
            </View>
            <Text style={styles.title}>{survey.title}</Text>
          </LinearGradient>

          <View style={styles.body}>
            <View style={styles.infoCard}>
              <View style={styles.infoIcon}>
                <MaterialIcons name="emoji-events" size={22} color={colors.primary} />
              </View>
              <Text style={styles.infoText}>
                {survey.description
                  ? survey.description
                  : "Kısa anketimizi tamamlayarak Seydi Rehber'i daha iyi hale getirmemize yardımcı olabilirsiniz."}
              </Text>
            </View>

            <View style={styles.chips}>
              <InfoChip icon="timer" label="~2 dakika" />
              <InfoChip icon="lock-outline" label="Anonim" />
              <InfoChip icon="favorite-border" label="Gönüllü" />
            </View>

            <Pressable onPress={onStart} style={styles.startButton}>
              <MaterialIcons name="open-in-new" size={20} color={colors.white} />
              <Text style={[typography.button, { marginLeft: 10, fontSize: 16, fontFamily: fonts.bold }]}>
                Ankete Başla
              </Text>
            </Pressable>

            <Pressable onPress={onSkip} style={({ pressed }) => [styles.skipButton, pressed && { backgroundColor: '#F5F5F5' }]}>
              <Text style={[typography.bodyMedium, { color: colors.textLight, fontFamily: fonts.medium }]}>
                Sonra Hatırlat
              </Text>
            </Pressable>
          </View>
          <View style={{ height: 8 }} />
        </Animated.View>
      </Animated.View>
    </Modal>
  );
}

function InfoChip({ icon, label }: { icon: ComponentProps<typeof MaterialIcons>['name']; label: string }) {
  return (
    <View style={styles.chip}>
      <MaterialIcons name={icon} size={14} color={colors.primary} />
      <Text style={styles.chipText} numberOfLines={1}>
        {label}
      </Text>
    </View>
  );
}

const styles = StyleSheet.create({
  barrier: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: 'rgba(0, 0, 0, 0.5)',
  },
  dialog: {
    borderRadius: 28,
    overflow: 'hidden',
    backgroundColor: colors.white,
    shadowColor: colors.primary,
    shadowOpacity: 0.15,
    shadowRadius: 30,
    shadowOffset: { width: 0, height: 12 },
    elevation: 12,
  },
  header: {
    alignItems: 'center',
    paddingVertical: 28,
  },
  headerIcon: {
    width: 72,
    height: 72,
    alignItems: 'center',
    justifyContent: 'center',
    borderRadius: 22,
    borderWidth: 2,
    borderColor: 'rgba(255, 255, 255, 0.3)',
    backgroundColor: 'rgba(255, 255, 255, 0.2)',
  },
  title: {
    marginTop: 16,
    paddingHorizontal: 16,
    fontFamily: fonts.extraBold,
    fontSize: 20,
    lineHeight: 26,
    color: colors.white,
    textAlign: 'center',
  },
  body: {
    paddingTop: 24,
    paddingHorizontal: 24,
    paddingBottom: 8,
  },
  infoCard: {
    padding: 16,
    flexDirection: 'row',
    alignItems: 'center',
    borderRadius: 16,
    borderWidth: 1,
    borderColor: 'rgba(76, 175, 80, 0.15)',
    backgroundColor: colors.primarySurface,
  },
  infoIcon: {
    padding: 8,
    borderRadius: 10,
    backgroundColor: 'rgba(76, 175, 80, 0.15)',
  },
  infoText: {
    flex: 1,
    marginLeft: 12,
    fontFamily: fonts.regular,
    fontSize: 12.5,
    lineHeight: 17.5,
    color: colors.textPrimary,
  },
  chips: {
    marginTop: 12,
    flexDirection: 'row',
    gap: 8,
  },
  chip: {
    flex: 1,
    paddingVertical: 8,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    borderRadius: 10,
    borderWidth: 1,
    borderColor: 'rgba(224, 224, 224, 0.5)',
    backgroundColor: colors.background,
  },
  chipText: {
    flexShrink: 1,
    marginLeft: 4,
    fontFamily: fonts.semiBold,
    fontSize: 10,
    color: colors.textSecondary,
  },
  startButton: {
    height: 54,
    marginTop: 24,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    borderRadius: 16,
    backgroundColor: colors.primary,
  },
  skipButton: {
    height: 48,
    marginTop: 8,
    alignItems: 'center',
    justifyContent: 'center',
    borderRadius: 16,
  },
});
