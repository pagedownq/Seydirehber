import { FontAwesome, MaterialIcons } from '@expo/vector-icons';
import { doc, increment, updateDoc } from '@react-native-firebase/firestore';
import RNMaskedView from '@react-native-masked-view/masked-view';
import { LinearGradient } from 'expo-linear-gradient';
import { StatusBar } from 'expo-status-bar';
import type { ComponentProps, ComponentType, ReactElement, ReactNode } from 'react';
import { useEffect } from 'react';
import { Linking, Pressable, type StyleProp, StyleSheet, Text, View, type ViewStyle } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';

import { CollapsingHeaderScreen } from '@/components/collapsing-header-screen';
import { FavoriteButton } from '@/components/favorite-button';
import { HeaderCircleButton } from '@/components/header-circle-button';
import { ImageSlider } from '@/components/image-slider';
import { InteractiveMap } from '@/components/interactive-map';
import { ModernInfoRow } from '@/components/modern-info-row';
import { ReviewSection } from '@/components/review-section';
import { shareContent } from '@/components/share-button';
import { DetailShimmer } from '@/components/shimmer';
import { useDocument } from '@/features/firestore/use-document';
import { useCoordinates } from '@/features/map/use-coordinates';
import { db } from '@/services/firebase';
import { haptics } from '@/services/haptics';
import { getItem, setItem, viewedCompanyKey } from '@/services/storage';
import { colors, fonts } from '@/theme';
import { isTimestamp, str } from '@/utils/firestore-values';
import { openMapWithAddress } from '@/utils/map';
import { goBack } from '@/utils/navigation';

// Flutter lib/features/companies/screens/company_detail_screen.dart karşılığı.
type IconName = ComponentProps<typeof MaterialIcons>['name'];

const CONTACT_GREEN = '#2E7D32';

// masked-view'in sınıf bileşeni tipi React 19 JSX tipleriyle örtüşmüyor; çalışma zamanında aynı bileşen.
const MaskedView = RNMaskedView as unknown as ComponentType<{
  style?: StyleProp<ViewStyle>;
  maskElement: ReactElement;
  children?: ReactNode;
}>;

/** Cihaz başına bir kez görüntülenme artırır (is_viewed_<id>). */
async function incrementViewCount(companyId: string) {
  const key = viewedCompanyKey(companyId);
  if ((await getItem<boolean>(key)) === true) return;
  await setItem(key, true);
  await updateDoc(doc(db, 'firmalar', companyId), { goruntulenme: increment(1) }).catch(() => {});
}

async function launchUrl(url: string) {
  let link = url;
  try {
    if (link.startsWith('tel:')) {
      if (await Linking.canOpenURL(link)) await Linking.openURL(link);
      return;
    }
    if (!link.startsWith('http')) link = `https://${link}`;
    if (await Linking.canOpenURL(link)) await Linking.openURL(link);
  } catch {}
}

export function CompanyDetailScreen({ companyId }: { companyId: string }) {
  const company = useDocument('firmalar', companyId);
  const konum = company.status === 'ready' && typeof company.data.konum === 'string' ? company.data.konum : null;
  const coordinates = useCoordinates(konum);

  useEffect(() => {
    incrementViewCount(companyId);
  }, [companyId]);

  if (company.status === 'loading') {
    return (
      <View style={styles.screen}>
        <DetailShimmer />
      </View>
    );
  }
  if (company.status !== 'ready') {
    return (
      <View style={[styles.screen, styles.center]}>
        <Text>Firma bulunamadı</Text>
      </View>
    );
  }

  const { data } = company;
  if (isTimestamp(data.expiry_date) && data.expiry_date.toDate() < new Date()) {
    return <ExpiredCompany />;
  }

  const name = str(data.ad);
  const imageUrl = str(data.image_url, str(data.gorsel));
  const images = Array.isArray(data.images) ? data.images.map(String) : [];
  if (images.length === 0 && imageUrl) images.push(imageUrl);
  const hakkinda = str(data.hakkinda);
  const iletisim = str(data.iletisim);
  const yetkiliKisi = str(data.yetkili_kisi);
  const email = str(data.email);
  const category = str(data.kategori);
  const adres = str(data.adres, str(data.konum));
  const website = str(data.website);
  const instagram = str(data.instagram);
  const menuUrl = str(data.menu_url);

  return (
    <>
      <StatusBar style="dark" />
      <CollapsingHeaderScreen
        expandedHeight={450}
        barColor={colors.white}
        background={<ImageSlider images={images} />}
        overlayColors={['rgba(0, 0, 0, 0.4)', 'transparent', 'rgba(0, 0, 0, 0.2)']}
        leading={
          <HeaderCircleButton
            icon="arrow-back"
            color={colors.white}
            onPress={() => {
              haptics.selection();
              goBack();
            }}
          />
        }
        actions={
          <>
            <HeaderCircleButton
              icon="share"
              color={colors.primaryDark}
              accessibilityLabel="Paylaş"
              onPress={() => {
                haptics.selection();
                shareContent(`${name} firmasını Seydi Rehber'de keşfet!`);
              }}
            />
            <FavoriteButton id={companyId} type="company" />
          </>
        }>
        <View style={styles.content}>
          <Text style={styles.name}>{name}</Text>
          {category ? (
            <>
              <Text style={styles.category}>{category.toUpperCase()}</Text>
              <View style={{ height: 8 }} />
            </>
          ) : null}
          <View style={{ height: 32 }} />

          {hakkinda ? (
            <>
              <Text style={styles.description}>{hakkinda}</Text>
              <View style={{ height: 20 }} />
            </>
          ) : null}

          {menuUrl ? (
            <>
              <MenuActionCard url={menuUrl} category={category} />
              <View style={{ height: 40 }} />
            </>
          ) : null}

          <Text style={styles.contactTitle}>İletişim Bilgileri</Text>
          <View style={{ height: 16 }} />
          {yetkiliKisi ? <ContactRow icon="person" label="Yetkili Kişi" value={yetkiliKisi} /> : null}
          {iletisim ? (
            <ContactRow icon="phone" label="Telefon" value={iletisim} onPress={() => launchUrl(`tel:${iletisim}`)} />
          ) : null}
          {website ? (
            <ContactRow icon="language" label="Web Sitesi" value={website} onPress={() => launchUrl(website)} />
          ) : null}
          {email ? (
            <ContactRow icon="email" label="E-Posta" value={email} onPress={() => launchUrl(`mailto:${email}`)} />
          ) : null}
          {instagram ? (
            <>
              <View style={{ height: 16 }} />
              <InstagramButton onPress={() => launchUrl(instagram)} />
            </>
          ) : null}

          <View style={{ height: 40 }} />
          <Text style={styles.locationTitle}>Konum</Text>
          <View style={{ height: 16 }} />
          {adres ? (
            <ModernInfoRow
              icon={{ community: 'map-marker-outline' }}
              label="ADRES"
              value={adres}
              bottomSpacing={25}
              valueSize={16}
            />
          ) : null}
          {konum ? (
            <>
              {coordinates.status === 'done' && coordinates.coords && (
                <View style={{ marginBottom: 20 }}>
                  <InteractiveMap position={coordinates.coords} title={name} />
                </View>
              )}
              <Pressable
                onPress={() => {
                  haptics.selection();
                  openMapWithAddress(konum);
                }}
                style={styles.mapButton}>
                <MaterialIcons name="near-me" size={24} color={colors.primaryDark} />
                <Text style={styles.mapButtonText}>HARİTA ÜZERİNDEN BAK</Text>
              </Pressable>
            </>
          ) : null}
          <View style={{ height: 48 }} />

          <ReviewSection targetId={companyId} targetType="company" />
          <View style={{ height: 40 }} />
        </View>
      </CollapsingHeaderScreen>
    </>
  );
}

// Flutter: kayıt süresi dolmuş firma için varsayılan AppBar + bilgi mesajı.
function ExpiredCompany() {
  const insets = useSafeAreaInsets();
  return (
    <View style={styles.screen}>
      <StatusBar style="dark" />
      <View style={{ paddingTop: insets.top }}>
        <View style={styles.plainToolbar}>
          <Pressable hitSlop={8} style={styles.plainBack} onPress={goBack}>
            <MaterialIcons name="arrow-back" size={24} color={colors.textPrimary} />
          </Pressable>
        </View>
      </View>
      <View style={[styles.center, { flex: 1, padding: 24 }]}>
        <MaterialIcons name="timer-off" size={80} color="#BDBDBD" />
        <Text style={styles.expiredText}>
          Bu firmanın kayıt süresi dolmuş veya hizmet geçici olarak durdurulmuştur.
        </Text>
      </View>
    </View>
  );
}

function ContactRow({
  icon,
  label,
  value,
  onPress,
}: {
  icon: IconName;
  label: string;
  value: string;
  onPress?: () => void;
}) {
  return (
    <Pressable
      onPress={() => {
        haptics.selection();
        onPress?.();
      }}
      style={styles.contactRow}>
      <MaterialIcons name={icon} size={28} color={CONTACT_GREEN} />
      <Text style={styles.contactLabel}>{label}</Text>
      <Text style={styles.contactColon}>{' :  '}</Text>
      <Text style={styles.contactValue}>{value}</Text>
    </Pressable>
  );
}

// Flutter: beyaz daire içinde Instagram gradyanlı ikon (ShaderMask).
function InstagramButton({ onPress }: { onPress: () => void }) {
  return (
    <Pressable
      onPress={() => {
        haptics.selection();
        onPress();
      }}
      style={styles.socialButton}>
      <MaskedView style={styles.socialIcon} maskElement={<FontAwesome name="instagram" size={28} color="#000000" />}>
        <LinearGradient
          colors={['#fdf497', '#f58529', '#dd2a7b', '#8134af', '#515bd4']}
          locations={[0, 0.2, 0.5, 0.8, 1]}
          start={{ x: 0, y: 1 }}
          end={{ x: 1, y: 0 }}
          style={StyleSheet.absoluteFill}
        />
      </MaskedView>
    </Pressable>
  );
}

function MenuActionCard({ url, category }: { url: string; category: string }) {
  const lowerUrl = url.toLowerCase();
  const lowerCategory = category.toLowerCase();

  let title = 'DİJİTAL KATALOG';
  let subtitle = 'Ürünleri ve detayları incele';
  let icon: IconName = 'auto-awesome-motion';
  let gradient: [string, string] = ['#6366F1', '#8B5CF6'];

  if (lowerUrl.includes('shopier.com')) {
    title = 'SHOPİER MAĞAZASI';
    subtitle = 'Ürünleri incele ve hemen satın al';
    icon = 'shopping-bag';
    gradient = ['#EC4899', '#F43F5E'];
  } else if (['restoran', 'kafe', 'lokanta', 'pastane'].some((k) => lowerCategory.includes(k))) {
    title = 'DİJİTAL MENÜ';
    subtitle = 'Fiyatları ve ürünleri incele';
    icon = 'restaurant-menu';
    gradient = ['#FF8F00', '#FFB300'];
  } else if (['giyim', 'mağaza', 'butik', 'ayakkabı', 'aksesuar'].some((k) => lowerCategory.includes(k))) {
    title = 'DİJİTAL MAĞAZA';
    subtitle = 'Koleksiyonu ve ürünleri incele';
    icon = 'storefront';
    gradient = ['#0EA5E9', '#2563EB'];
  }

  return (
    <Pressable
      onPress={() => {
        haptics.medium();
        launchUrl(url);
      }}
      style={[styles.menuCard, { shadowColor: gradient[0], backgroundColor: gradient[0] }]}>
      <LinearGradient colors={gradient} start={{ x: 0, y: 0 }} end={{ x: 1, y: 1 }} style={styles.menuInner}>
        <View style={styles.menuIconBox}>
          <MaterialIcons name={icon} size={28} color={colors.white} />
        </View>
        <View style={{ flex: 1, marginLeft: 20 }}>
          <Text style={styles.menuTitle}>{title}</Text>
          <Text style={styles.menuSubtitle}>{subtitle}</Text>
        </View>
        <MaterialIcons name="arrow-forward-ios" size={18} color={colors.white} />
      </LinearGradient>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  screen: {
    flex: 1,
    backgroundColor: colors.white,
  },
  center: {
    alignItems: 'center',
    justifyContent: 'center',
  },
  content: {
    backgroundColor: colors.white,
    paddingTop: 10,
    paddingHorizontal: 25,
    paddingBottom: 120,
  },
  name: {
    fontFamily: fonts.black,
    fontSize: 22,
    lineHeight: 24.2,
    color: '#000000',
  },
  category: {
    fontFamily: fonts.extraBold,
    fontSize: 11,
    letterSpacing: 1.2,
    color: colors.primaryDark,
  },
  description: {
    fontFamily: fonts.regular,
    fontSize: 14,
    lineHeight: 21,
    color: '#424242',
  },
  contactTitle: {
    fontFamily: fonts.regular,
    fontSize: 24,
    color: '#000000',
  },
  contactRow: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: 8,
  },
  contactLabel: {
    width: 90,
    marginLeft: 12,
    fontFamily: fonts.regular,
    fontSize: 16,
    color: CONTACT_GREEN,
  },
  contactColon: {
    fontFamily: fonts.regular,
    fontSize: 16,
    color: CONTACT_GREEN,
  },
  contactValue: {
    flex: 1,
    fontFamily: fonts.regular,
    fontSize: 15,
    color: '#000000',
  },
  socialButton: {
    alignSelf: 'flex-start',
    padding: 12,
    borderRadius: 999,
    backgroundColor: colors.white,
    shadowColor: '#000000',
    shadowOpacity: 0.08,
    shadowRadius: 12,
    shadowOffset: { width: 0, height: 4 },
    elevation: 4,
  },
  socialIcon: {
    width: 28,
    height: 28,
  },
  locationTitle: {
    fontFamily: fonts.bold,
    fontSize: 18,
    color: '#000000',
  },
  mapButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 8,
    paddingVertical: 18,
    borderRadius: 15,
    backgroundColor: colors.primarySurface,
  },
  mapButtonText: {
    fontFamily: fonts.black,
    fontSize: 13,
    letterSpacing: 0.5,
    color: colors.primaryDark,
  },
  menuCard: {
    borderRadius: 20,
    shadowOpacity: 0.3,
    shadowRadius: 15,
    shadowOffset: { width: 0, height: 8 },
    elevation: 6,
  },
  menuInner: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: 20,
    borderRadius: 20,
  },
  menuIconBox: {
    padding: 10,
    borderRadius: 12,
    backgroundColor: 'rgba(255, 255, 255, 0.2)',
  },
  menuTitle: {
    fontFamily: fonts.black,
    fontSize: 16,
    letterSpacing: 1.1,
    color: colors.white,
  },
  menuSubtitle: {
    fontFamily: fonts.regular,
    fontSize: 12,
    color: 'rgba(255, 255, 255, 0.7)',
  },
  plainToolbar: {
    height: 56,
    justifyContent: 'center',
    paddingHorizontal: 4,
  },
  plainBack: {
    width: 48,
    height: 48,
    alignItems: 'center',
    justifyContent: 'center',
  },
  expiredText: {
    marginTop: 16,
    fontFamily: fonts.bold,
    fontSize: 14,
    color: colors.textPrimary,
    textAlign: 'center',
  },
});
