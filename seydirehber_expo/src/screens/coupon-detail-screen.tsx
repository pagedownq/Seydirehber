import { MaterialIcons } from '@expo/vector-icons';
import {
  addDoc,
  collection,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  limit,
  onSnapshot,
  query,
  serverTimestamp,
  Timestamp,
  where,
} from '@react-native-firebase/firestore';
import { Image } from 'expo-image';
import { type Href, router } from 'expo-router';
import { useEffect, useRef, useState } from 'react';
import { ActivityIndicator, Modal, Pressable, ScrollView, StyleSheet, Text, View } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';

import { AppBar } from '@/components/app-bar';
import { DetailShimmer } from '@/components/shimmer';
import { showSnackbar } from '@/components/snackbar';
import type { FirestoreData } from '@/features/firestore/live-query';
import { useAllCoupons, useAlphabeticalCompanies } from '@/features/home/home-queries';
import { auth, db } from '@/services/firebase';
import { colors, fonts } from '@/theme';
import { formatDots } from '@/utils/date';
import { isTimestamp, str } from '@/utils/firestore-values';
import { goBack } from '@/utils/navigation';

// Flutter lib/features/coupons/screens/coupon_detail_screen.dart karşılığı.
const CODE_LIFETIME_MS = 5 * 60 * 1000;
const GREEN = '#4CAF50';
const RED = '#F44336';
const GREY = '#9E9E9E';

/** Firma adının ilk 2 harfi (Türkçe harfler sadeleştirilir) + 4 rastgele harf/rakam. */
function generateRandomCode(companyName: string) {
  let prefix = 'SY';
  if (companyName.length >= 2) prefix = companyName.substring(0, 2).toUpperCase();
  else if (companyName.length > 0) prefix = `${companyName[0]}X`.toUpperCase();
  prefix = prefix
    .replaceAll('İ', 'I')
    .replaceAll('Ğ', 'G')
    .replaceAll('Ü', 'U')
    .replaceAll('Ş', 'S')
    .replaceAll('Ö', 'O')
    .replaceAll('Ç', 'C');

  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  let suffix = '';
  for (let i = 0; i < 4; i++) suffix += chars[Math.floor(Math.random() * chars.length)];
  return prefix + suffix;
}

export function CouponDetailScreen({ couponId }: { couponId: string }) {
  const coupons = useAllCoupons();
  const preloaded = coupons.docs.find((d) => d.id === couponId)?.data ?? null;

  const [couponData, setCouponData] = useState<FirestoreData | null>(preloaded);
  const [isChecking, setIsChecking] = useState(true);
  const [isUsed, setIsUsed] = useState(false);
  const [activeCodeId, setActiveCodeId] = useState<string | null>(null);
  const [expiresAt, setExpiresAt] = useState<Date | null>(null);
  const [isGenerating, setIsGenerating] = useState(false);
  const [confirmVisible, setConfirmVisible] = useState(false);
  const initialized = useRef(false);

  useEffect(() => {
    if (initialized.current) return;
    initialized.current = true;

    (async () => {
      let data = couponData;
      if (!data) {
        try {
          const snapshot = await getDoc(doc(db, 'coupons', couponId));
          data = (snapshot.data() as FirestoreData | undefined) ?? null;
          if (data) setCouponData(data);
        } catch (error) {
          console.warn('Error fetching coupon data:', error);
        }
      }
      if (data?.isInformational !== true) await checkExistingActiveCode();
      setIsChecking(false);
    })();

    async function checkExistingActiveCode() {
      const user = auth.currentUser;
      if (!user) return;
      try {
        // Ömür boyu tek kullanım: daha önce kullanıldıysa o kod gösterilir.
        const used = await getDocs(
          query(
            collection(db, 'generated_codes'),
            where('userId', '==', user.uid),
            where('couponId', '==', couponId),
            where('status', '==', 'used'),
            limit(1),
          ),
        );
        if (!used.empty) {
          setIsUsed(true);
          setActiveCodeId(used.docs[0].id);
          return;
        }

        const pending = await getDocs(
          query(
            collection(db, 'generated_codes'),
            where('userId', '==', user.uid),
            where('couponId', '==', couponId),
            where('status', '==', 'pending'),
          ),
        );
        let found = false;
        for (const codeDoc of pending.docs) {
          const expires = (codeDoc.data().expiresAt as Timestamp).toDate();
          if (expires > new Date()) {
            if (!found) {
              found = true;
              setActiveCodeId(codeDoc.id);
              setExpiresAt(expires);
            }
          } else {
            // Kullanılmadan süresi dolan kod silinir.
            await deleteDoc(codeDoc.ref).catch((error) => console.warn('Error deleting expired code:', error));
          }
        }
      } catch (error) {
        console.warn('Coupon code check error:', error);
      }
    }
  }, [couponData, couponId]);

  const generateCode = async () => {
    const user = auth.currentUser;
    if (!user) {
      showSnackbar({ message: 'Lütfen önce giriş yapın.', floating: false });
      return;
    }
    setIsGenerating(true);
    try {
      const code = generateRandomCode(str(couponData?.companyName, 'SY'));
      const expires = new Date(Date.now() + CODE_LIFETIME_MS);
      const ref = await addDoc(collection(db, 'generated_codes'), {
        couponId,
        companyId: couponData?.companyId ?? null,
        userId: user.uid,
        code,
        status: 'pending',
        createdAt: serverTimestamp(),
        expiresAt: Timestamp.fromDate(expires),
      });
      setActiveCodeId(ref.id);
      setExpiresAt(expires);
    } catch {
      // Flutter'da mesaj kaçış hatası yüzünden hata metni yerine "$e" yazıyor; birebir korunuyor.
      showSnackbar({ message: 'Kod oluşturulamadı: $e', floating: false });
    } finally {
      setIsGenerating(false);
    }
  };

  if (isChecking) {
    return (
      <View style={styles.container}>
        <DetailShimmer />
      </View>
    );
  }

  const isInformational = couponData?.isInformational === true;

  if (!isInformational && activeCodeId) {
    return (
      <View style={styles.container}>
        <AppBar title="Kupon Kodu" />
        <ActiveCodeView codeId={activeCodeId} expiresAt={expiresAt} isUsed={isUsed} />
      </View>
    );
  }

  const isExpiredGlobal = isTimestamp(couponData?.expiry_date) && couponData.expiry_date.toDate() < new Date();
  const totalLimit = typeof couponData?.total_limit === 'number' ? couponData.total_limit : null;
  const usedCount = typeof couponData?.used_count === 'number' ? couponData.used_count : 0;
  const isLimitReached = totalLimit != null && usedCount >= totalLimit;

  let buttonText = 'Kuponu Kullan';
  let disabled = isGenerating || isUsed || isExpiredGlobal || isLimitReached;
  if (isUsed) buttonText = 'Bu Kuponu Kullandınız';
  else if (isExpiredGlobal) buttonText = 'Kupon Süresi Doldu';
  else if (isLimitReached) buttonText = 'Kupon Stoğu Tükendi';
  if (isInformational) {
    buttonText = 'Firmaya Git';
    disabled = false;
  }

  return (
    <View style={styles.container}>
      <AppBar title="Kupon Detayı" />
      <ScrollView bounces={false}>
        <CouponHeader data={couponData} />
        <View style={{ padding: 20 }}>
          <Text style={styles.aboutTitle}>Kupon Hakkında</Text>
          <Text style={styles.aboutText}>{str(couponData?.description, 'Detaylı bilgi bulunmuyor.')}</Text>
        </View>
      </ScrollView>
      <BottomButton
        text={buttonText}
        disabled={disabled}
        loading={isGenerating}
        showStoreIcon={isInformational}
        onPress={() => {
          if (isInformational) {
            const companyId = str(couponData?.companyId);
            if (companyId) router.push(`/companies/${companyId}` as Href);
            else showSnackbar({ message: 'Firma bilgisi bulunamadı.', floating: false });
          } else {
            setConfirmVisible(true);
          }
        }}
      />
      <ConfirmUseDialog
        visible={confirmVisible}
        onCancel={() => setConfirmVisible(false)}
        onConfirm={() => {
          setConfirmVisible(false);
          generateCode();
        }}
      />
    </View>
  );
}

function CouponHeader({ data }: { data: FirestoreData | null }) {
  const companies = useAlphabeticalCompanies();
  const title = str(data?.title, 'Kupon');
  const companyId = str(data?.companyId);
  const companyName = str(data?.companyName);
  const discount = typeof data?.discountPercentage === 'number' ? data.discountPercentage : 0;
  const expiry = isTimestamp(data?.expiry_date) ? data.expiry_date : null;
  const totalLimit = typeof data?.total_limit === 'number' ? data.total_limit : null;
  const usedCount = typeof data?.used_count === 'number' ? data.used_count : 0;
  const isOrange = data?.isInformational === true && discount === 0;

  const company = companies.docs.find((c) => c.id === companyId);
  const companyImage = company ? str(company.data.image_url, str(company.data.gorsel)) : '';

  return (
    <View style={[styles.header, { backgroundColor: isOrange ? colors.warning : colors.primary }]}>
      {companyImage ? (
        <>
          <Image source={{ uri: companyImage }} style={StyleSheet.absoluteFill} contentFit="cover" cachePolicy="memory-disk" />
          <View style={[StyleSheet.absoluteFill, { backgroundColor: 'rgba(0, 0, 0, 0.55)' }]} />
        </>
      ) : null}
      <View style={styles.discountBadge}>
        <Text style={styles.discountText}>{discount > 0 ? `%${discount} İNDİRİM` : 'ÖZEL FIRSAT'}</Text>
      </View>
      <Text style={styles.headerTitle}>{title}</Text>
      <View style={styles.headerRow}>
        <MaterialIcons name="storefront" size={16} color="rgba(255, 255, 255, 0.7)" />
        <Text style={styles.headerCompany}>{companyName}</Text>
      </View>
      {(expiry || totalLimit != null) && (
        <View style={[styles.headerRow, { marginTop: 12 }]}>
          {expiry && (
            <>
              <MaterialIcons name="event-available" size={14} color="rgba(255, 255, 255, 0.7)" />
              <Text style={styles.headerMeta}>Bitiş: {formatDots(expiry.toDate())}</Text>
              {totalLimit != null && <View style={{ width: 12 }} />}
            </>
          )}
          {totalLimit != null && (
            <>
              <MaterialIcons name="group" size={14} color="rgba(255, 255, 255, 0.7)" />
              <Text style={styles.headerMeta}>
                Limit: {usedCount}/{totalLimit}
              </Text>
            </>
          )}
        </View>
      )}
    </View>
  );
}

function BottomButton({
  text,
  disabled,
  loading,
  showStoreIcon,
  onPress,
}: {
  text: string;
  disabled: boolean;
  loading: boolean;
  showStoreIcon: boolean;
  onPress: () => void;
}) {
  const insets = useSafeAreaInsets();
  return (
    <View style={[styles.bottom, { paddingBottom: 20 + insets.bottom }]}>
      <Pressable
        disabled={disabled}
        onPress={onPress}
        style={[styles.bottomButton, { backgroundColor: disabled && !loading ? GREY : colors.primary }]}>
        {loading ? (
          <ActivityIndicator color={colors.white} />
        ) : (
          <>
            {showStoreIcon && <MaterialIcons name="storefront" size={24} color={colors.white} />}
            <Text style={styles.bottomText}>{text}</Text>
          </>
        )}
      </Pressable>
    </View>
  );
}

function ConfirmUseDialog({ visible, onCancel, onConfirm }: { visible: boolean; onCancel: () => void; onConfirm: () => void }) {
  return (
    <Modal visible={visible} transparent animationType="fade" statusBarTranslucent onRequestClose={onCancel}>
      <Pressable style={styles.barrier} onPress={onCancel}>
        <Pressable style={styles.dialog}>
          <View style={styles.dialogTop}>
            <View style={styles.dialogIcon}>
              <MaterialIcons name="qr-code-scanner" size={44} color={colors.primary} />
            </View>
          </View>
          <View style={styles.dialogBody}>
            <Text style={styles.dialogTitle}>Kuponu Kullanalım mı?</Text>
            <Text style={styles.dialogText}>
              Kupon kodunu oluşturduktan sonra 5 dakika süreniz başlar. Görevliye bu kodu göstererek indirimden
              faydalanabilirsiniz.
            </Text>
            <View style={styles.dialogButtons}>
              <Pressable style={[styles.dialogButton, { backgroundColor: '#F5F5F5' }]} onPress={onCancel}>
                <Text style={[styles.dialogButtonText, { color: colors.textPrimary }]}>Vazgeç</Text>
              </Pressable>
              <Pressable style={[styles.dialogButton, { backgroundColor: colors.primary }]} onPress={onConfirm}>
                <Text style={[styles.dialogButtonText, { color: colors.white }]}>Kodu Oluştur</Text>
              </Pressable>
            </View>
          </View>
        </Pressable>
      </Pressable>
    </Modal>
  );
}

/** Üretilen kodu canlı dinler: esnaf panelinde kullanılınca "Kupon Başarıyla Kullanıldı!" ekranına geçer. */
function ActiveCodeView({ codeId, expiresAt, isUsed }: { codeId: string; expiresAt: Date | null; isUsed: boolean }) {
  const [codeData, setCodeData] = useState<{ id: string; data: FirestoreData | null } | null>(null);
  const [timeLeftMs, setTimeLeftMs] = useState(() => (expiresAt ? Math.max(0, expiresAt.getTime() - Date.now()) : 0));

  useEffect(
    () =>
      onSnapshot(doc(db, 'generated_codes', codeId), (snapshot) =>
        setCodeData({ id: codeId, data: (snapshot.data() as FirestoreData | undefined) ?? null }),
      ),
    [codeId],
  );

  useEffect(() => {
    if (!expiresAt) return;
    const tick = () => {
      const left = Math.max(0, expiresAt.getTime() - Date.now());
      setTimeLeftMs(left);
      return left;
    };
    const timer = setInterval(() => {
      if (tick() === 0) clearInterval(timer);
    }, 1000);
    return () => clearInterval(timer);
  }, [expiresAt]);

  if (!codeData || codeData.id !== codeId) return <DetailShimmer />;
  if (!codeData.data) {
    return (
      <View style={styles.center}>
        <Text>Kod bulunamadı.</Text>
      </View>
    );
  }

  const status = str(codeData.data.status, 'pending');
  const code = str(codeData.data.code);

  if (status === 'used') {
    return (
      <View style={styles.center}>
        <View style={styles.usedCircle}>
          <MaterialIcons name="check-circle-outline" size={80} color={GREEN} />
        </View>
        <Text style={styles.usedTitle}>Kupon Başarıyla Kullanıldı!</Text>
        <Text style={styles.usedText}>Bizi tercih ettiğiniz için teşekkür ederiz.</Text>
        <Pressable style={styles.backButton} onPress={goBack}>
          <Text style={styles.backText}>Geri Dön</Text>
        </Pressable>
      </View>
    );
  }

  const totalSeconds = Math.floor(timeLeftMs / 1000);
  const minutes = String(Math.floor(totalSeconds / 60) % 60).padStart(2, '0');
  const seconds = String(totalSeconds % 60).padStart(2, '0');
  const isExpired = totalSeconds <= 0;

  return (
    <View style={[styles.center, { padding: 24 }]}>
      <Text style={styles.codeLabel}>Kupon Kodunuz</Text>
      <View
        style={[
          styles.codeBox,
          {
            backgroundColor: isExpired ? '#EEEEEE' : 'rgba(76, 175, 80, 0.1)',
            borderColor: isExpired ? GREY : colors.primary,
          },
        ]}>
        <Text style={[styles.code, { color: isExpired ? GREY : colors.primary }]}>{code}</Text>
      </View>
      {isUsed ? (
        <View style={{ alignItems: 'center' }}>
          <MaterialIcons name="check-circle-outline" size={80} color={GREEN} />
          <Text style={styles.usedInline}>Kupon Başarıyla Kullanıldı</Text>
          <Text style={[styles.usedText, { marginTop: 8, fontSize: 14 }]}>Bu kupondan daha önce faydalandınız.</Text>
        </View>
      ) : (
        <>
          <Text style={[styles.timeLabel, { color: isExpired ? RED : colors.textLight }]}>
            {isExpired ? 'Süre Doldu' : 'Kalan Süre'}
          </Text>
          <Text style={[styles.time, { color: isExpired ? RED : colors.textPrimary }]}>
            {minutes}:{seconds}
          </Text>
        </>
      )}
      <Text style={styles.instruction}>Lütfen bu kodu kasadatki görevliye gösterin</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.background,
  },
  center: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
  header: {
    alignItems: 'center',
    paddingHorizontal: 24,
    paddingVertical: 48,
    borderBottomLeftRadius: 30,
    borderBottomRightRadius: 30,
    overflow: 'hidden',
  },
  discountBadge: {
    paddingHorizontal: 16,
    paddingVertical: 8,
    borderRadius: 20,
    backgroundColor: 'rgba(255, 255, 255, 0.2)',
  },
  discountText: {
    fontFamily: fonts.bold,
    fontSize: 16,
    color: colors.white,
  },
  headerTitle: {
    marginTop: 16,
    fontFamily: fonts.bold,
    fontSize: 24,
    color: colors.white,
    textAlign: 'center',
  },
  headerRow: {
    marginTop: 8,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 6,
  },
  headerCompany: {
    fontFamily: fonts.regular,
    fontSize: 16,
    color: 'rgba(255, 255, 255, 0.7)',
  },
  headerMeta: {
    fontFamily: fonts.regular,
    fontSize: 13,
    color: 'rgba(255, 255, 255, 0.7)',
  },
  aboutTitle: {
    fontFamily: fonts.bold,
    fontSize: 18,
    color: colors.textPrimary,
  },
  aboutText: {
    marginTop: 12,
    fontFamily: fonts.regular,
    fontSize: 15,
    lineHeight: 22.5,
    color: colors.textLight,
  },
  bottom: {
    paddingTop: 8,
    paddingHorizontal: 20,
  },
  bottomButton: {
    height: 56,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 8,
    borderRadius: 16,
  },
  bottomText: {
    fontFamily: fonts.bold,
    fontSize: 16,
    color: colors.white,
  },
  barrier: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    paddingHorizontal: 40,
    backgroundColor: colors.barrier,
  },
  dialog: {
    width: '100%',
    borderRadius: 28,
    overflow: 'hidden',
    backgroundColor: colors.white,
  },
  dialogTop: {
    alignItems: 'center',
    paddingVertical: 30,
    backgroundColor: 'rgba(76, 175, 80, 0.05)',
  },
  dialogIcon: {
    padding: 16,
    borderRadius: 999,
    backgroundColor: 'rgba(76, 175, 80, 0.1)',
  },
  dialogBody: {
    paddingTop: 24,
    paddingHorizontal: 24,
    paddingBottom: 32,
  },
  dialogTitle: {
    fontFamily: fonts.black,
    fontSize: 22,
    letterSpacing: -0.5,
    color: colors.textPrimary,
    textAlign: 'center',
  },
  dialogText: {
    marginTop: 12,
    fontFamily: fonts.regular,
    fontSize: 15,
    lineHeight: 22.5,
    color: colors.textSecondary,
    textAlign: 'center',
  },
  dialogButtons: {
    marginTop: 32,
    flexDirection: 'row',
    gap: 12,
  },
  dialogButton: {
    flex: 1,
    alignItems: 'center',
    paddingVertical: 16,
    borderRadius: 16,
  },
  dialogButtonText: {
    fontFamily: fonts.bold,
    fontSize: 16,
  },
  usedCircle: {
    padding: 24,
    borderRadius: 999,
    backgroundColor: 'rgba(76, 175, 80, 0.1)',
  },
  usedTitle: {
    marginTop: 24,
    fontFamily: fonts.bold,
    fontSize: 24,
    color: colors.textPrimary,
  },
  usedText: {
    marginTop: 12,
    fontFamily: fonts.regular,
    fontSize: 16,
    color: colors.textLight,
  },
  backButton: {
    marginTop: 32,
    paddingHorizontal: 24,
    paddingVertical: 14,
    borderRadius: 12,
    backgroundColor: colors.primary,
  },
  backText: {
    fontFamily: fonts.semiBold,
    fontSize: 14,
    color: colors.white,
  },
  codeLabel: {
    fontFamily: fonts.regular,
    fontSize: 18,
    color: colors.textLight,
  },
  codeBox: {
    marginTop: 16,
    marginBottom: 32,
    paddingHorizontal: 32,
    paddingVertical: 16,
    borderRadius: 16,
    borderWidth: 2,
  },
  code: {
    fontFamily: fonts.bold,
    fontSize: 48,
    letterSpacing: 8,
  },
  usedInline: {
    marginTop: 16,
    fontFamily: fonts.bold,
    fontSize: 24,
    color: GREEN,
  },
  timeLabel: {
    fontFamily: fonts.regular,
    fontSize: 16,
  },
  time: {
    marginTop: 8,
    fontFamily: fonts.bold,
    fontSize: 32,
  },
  instruction: {
    marginTop: 40,
    fontFamily: fonts.regular,
    fontSize: 14,
    color: colors.textLight,
    textAlign: 'center',
  },
});
