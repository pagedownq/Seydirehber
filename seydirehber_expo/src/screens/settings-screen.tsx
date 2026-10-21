import { MaterialCommunityIcons, MaterialIcons } from '@expo/vector-icons';
import * as Application from 'expo-application';
import { type Href, router } from 'expo-router';
import { StatusBar } from 'expo-status-bar';
import { type ComponentProps, type ReactNode, useCallback, useEffect, useState } from 'react';
import {
  ActivityIndicator,
  AppState,
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
import { useSafeAreaInsets } from 'react-native-safe-area-context';

import { appNotification } from '@/components/app-notification';
import { BottomSheet } from '@/components/bottom-sheet';
import { MaterialSwitch } from '@/components/material-switch';
import { showSnackbar } from '@/components/snackbar';
import { useIsAdmin } from '@/features/auth/admin-permissions';
import {
  deleteAccount,
  signInWithApple,
  signInWithGoogle,
  signOut,
} from '@/features/auth/auth-actions';
import { useIsGuest, useUser } from '@/features/auth/auth-store';
import { type BlockedUser, getBlockedUsersList, unblockUser } from '@/features/block/block-service';
import { haptics, hapticsEnabled, setHapticsEnabled } from '@/services/haptics';
import { getNotificationPermission, requestNotificationPermission } from '@/services/notification-permission';
import {
  isDailyNotificationsEnabled,
  isNotificationsEnabled,
  isVefatNotificationsEnabled,
  setDailyNotificationsEnabled,
  setNotificationsEnabled,
  setVefatNotificationsEnabled,
} from '@/services/notifications';
import { colors, fonts, typography } from '@/theme';
import { alertConfirm } from '@/utils/alert-confirm';

// Flutter lib/features/settings/screens/settings_screen.dart karşılığı.
type IconName = ComponentProps<typeof MaterialIcons>['name'];

const APP_STORE_ID = '6762803524';
const PACKAGE_NAME = 'com.mgverse.seydirehberim';
const VEFAT_COLOR = '#1A3F6A';
const ORANGE = '#FF9800';
const RED = '#F44336';

function withOpacity(hex: string, opacity: number) {
  const r = parseInt(hex.slice(1, 3), 16);
  const g = parseInt(hex.slice(3, 5), 16);
  const b = parseInt(hex.slice(5, 7), 16);
  return `rgba(${r}, ${g}, ${b}, ${opacity})`;
}

/** Flutter _showPlatformConfirmDialog: iOS'ta Cupertino, Android'de Material uyarı penceresi. */
const showPlatformConfirmDialog = alertConfirm;

/** Flutter SettingsScreen.checkAndShowPermissionDialog. */
async function checkAndShowPermissionDialog(): Promise<boolean> {
  const status = await getNotificationPermission();
  if (status === 'granted') return true;

  if (status === 'permanentlyDenied') {
    const confirmed = await showPlatformConfirmDialog({
      title: 'Bildirim İzni Gerekli',
      content: 'Bildirimleri alabilmek için ayarlardan izin vermeniz gerekmektedir. Ayarlara gitmek ister misiniz?',
      confirmText: 'Ayarlara Git',
      cancelText: 'Vazgeç',
    });
    if (confirmed) await Linking.openSettings();
    return false;
  }

  return requestNotificationPermission();
}

/** in_app_review openStoreListing karşılığı. */
async function openStoreListing() {
  if (Platform.OS === 'ios') {
    await Linking.openURL(`itms-apps://itunes.apple.com/app/id${APP_STORE_ID}`).catch(() =>
      Linking.openURL(`https://apps.apple.com/app/id${APP_STORE_ID}`),
    );
  } else {
    await Linking.openURL(`market://details?id=${PACKAGE_NAME}`).catch(() =>
      Linking.openURL(`https://play.google.com/store/apps/details?id=${PACKAGE_NAME}`),
    );
  }
}

export function SettingsScreen() {
  const insets = useSafeAreaInsets();
  const user = useUser();
  const isGuest = useIsGuest();
  const isAdmin = useIsAdmin();
  const [blockedSheetVisible, setBlockedSheetVisible] = useState(false);
  const version = Application.nativeApplicationVersion;

  return (
    <View style={styles.container}>
      <StatusBar style="dark" />
      <View style={[styles.appBar, { paddingTop: insets.top }]}>
        <Text style={[typography.appBarTitle, styles.appBarTitle]}>Ayarlar</Text>
      </View>
      <ScrollView contentContainerStyle={styles.content}>
        {user == null || isGuest ? <GuestCard /> : <ProfileCard />}

        <View style={{ height: 20 }} />

        {isAdmin && (
          <>
            <SettingsItem
              icon="admin-panel-settings"
              title="Yönetim Paneli"
              subtitle="İçerik yönetimi"
              iconColor={colors.error}
              onPress={() => router.push('/admin' as Href)}
            />
            <Gap />
          </>
        )}

        <NotificationToggleItem />
        <Gap />
        <DailyNotificationToggleItem />
        <Gap />
        <VefatNotificationToggleItem />
        <Gap />
        <HapticToggleItem />
        <Gap />

        <SettingsItem
          icon="favorite-border"
          title="Favorilerim"
          subtitle="Kaydettiğiniz yerler ve firmalar"
          iconColor={RED}
          onPress={() => router.push('/favorites' as Href)}
        />
        <Gap />
        <SettingsItem
          icon="help-outline"
          title="Yardım & Destek"
          subtitle="Bize ulaşın"
          iconColor={colors.info}
          onPress={() => router.push('/support' as Href)}
        />
        <Gap />
        <SettingsItem
          icon="star-outline"
          title="Uygulamayı Değerlendir"
          subtitle={Platform.OS === 'ios' ? "App Store'da puanlayın" : "Play Store'da puanlayın"}
          iconColor={colors.warning}
          onPress={openStoreListing}
        />
        <Gap />
        <SettingsItem
          icon="person-remove"
          outlinedIcon="account-minus-outline"
          title="Engellenen Kullanıcılar"
          subtitle="Engellediğiniz kişileri yönetin"
          iconColor={colors.error}
          onPress={() => setBlockedSheetVisible(true)}
        />
        <Gap />
        <SettingsItem
          icon="privacy-tip"
          title="Politikalar"
          subtitle="Gizlilik ve kullanım koşulları"
          iconColor={colors.primary}
          onPress={() => router.push('/policies' as Href)}
        />
        <Gap />
        <SettingsItem
          icon="info-outline"
          title="Uygulama Hakkında"
          subtitle={version ? `Seydi Rehber v${version}` : 'Seydi Rehber'}
          iconColor={colors.textLight}
          onPress={() => {}}
        />

        <View style={{ height: 32 }} />
      </ScrollView>

      <BlockedUsersSheet visible={blockedSheetVisible} onClose={() => setBlockedSheetVisible(false)} />
    </View>
  );
}

const Gap = () => <View style={{ height: 8 }} />;

function Card({ children }: { children: ReactNode }) {
  return <View style={styles.card}>{children}</View>;
}

function ProfileCard() {
  const user = useUser();
  if (!user) return null;

  return (
    <Card>
      <View style={styles.row}>
        <View style={styles.avatar}>
          {user.photoURL ? (
            <Image source={{ uri: user.photoURL }} style={styles.avatarImage} />
          ) : (
            <MaterialIcons name="person" size={28} color={colors.primary} />
          )}
        </View>
        <View style={{ flex: 1, marginLeft: 14 }}>
          <Text style={typography.heading3}>{user.displayName ?? 'Kullanıcı'}</Text>
          <Text style={typography.bodySmall}>{user.email ?? ''}</Text>
        </View>
      </View>
      <View style={[styles.row, { marginTop: 16 }]}>
        <OutlinedButton
          icon="logout"
          label="Çıkış Yap"
          color={colors.error}
          borderColor={colors.error}
          onPress={async () => {
            haptics.vibrate();
            const confirmed = await showPlatformConfirmDialog({
              title: 'Çıkış Yap',
              content: 'Çıkış yapmak istediğinize emin misiniz?',
              confirmText: 'Çıkış Yap',
              isDestructive: true,
            });
            if (confirmed) await signOut();
          }}
        />
        <View style={{ width: 10 }} />
        <OutlinedButton
          icon="delete-outline"
          label="Hesabı Sil"
          color={colors.textLight}
          borderColor={colors.border}
          onPress={async () => {
            haptics.vibrate();
            const confirmed = await showPlatformConfirmDialog({
              title: 'Hesabı Sil',
              content: 'Hesabınız kalıcı olarak silinecek. Bu işlem geri alınamaz.',
              confirmText: 'Sil',
              isDestructive: true,
            });
            if (!confirmed) return;
            const error = await deleteAccount();
            // Flutter: AuthNotifier hata durumunda Ayarlar ekranı kırmızı SnackBar gösterir.
            if (error) showSnackbar({ message: error, backgroundColor: colors.error });
          }}
        />
      </View>
    </Card>
  );
}

function OutlinedButton({
  icon,
  label,
  color,
  borderColor,
  onPress,
}: {
  icon: IconName;
  label: string;
  color: string;
  borderColor: string;
  onPress: () => void;
}) {
  return (
    <Pressable onPress={onPress} style={[styles.outlinedButton, { borderColor }]}>
      <MaterialIcons name={icon} size={18} color={color} />
      <Text style={[styles.outlinedLabel, { color }]} numberOfLines={1}>
        {label}
      </Text>
    </Pressable>
  );
}

function GuestCard() {
  return (
    <Card>
      <View style={{ alignItems: 'center' }}>
        <View style={styles.avatar}>
          <MaterialIcons name="person-outline" size={28} color={colors.primary} />
        </View>
        <Text style={[typography.heading3, { marginTop: 12 }]}>Misafir Kullanıcı</Text>
        <Text style={[typography.bodySmall, { marginTop: 4 }]}>Giriş yaparak tüm özelliklere erişin</Text>
        <View style={{ height: 14 }} />
        {Platform.OS === 'ios' && (
          <>
            <Pressable
              onPress={() => {
                haptics.vibrate();
                signInWithApple();
              }}
              style={[styles.loginButton, styles.appleButton]}>
              <MaterialCommunityIcons name="apple" size={24} color="#000000" />
              <Text style={[styles.loginLabel, { color: '#000000' }]}>Apple ile Giriş Yap</Text>
            </Pressable>
            <View style={{ height: 12 }} />
          </>
        )}
        <Pressable
          onPress={() => {
            haptics.vibrate();
            signInWithGoogle();
          }}
          style={[styles.loginButton, { backgroundColor: colors.primary }]}>
          <Image source={{ uri: 'https://www.google.com/favicon.ico' }} style={{ width: 20, height: 20 }} />
          <Text style={[styles.loginLabel, { color: colors.white }]}>Google ile Giriş Yap</Text>
        </Pressable>
      </View>
    </Card>
  );
}

function ItemShell({
  icon,
  outlinedIcon,
  iconColor,
  title,
  subtitle,
  trailing,
  onPress,
}: {
  icon: IconName;
  outlinedIcon?: ComponentProps<typeof MaterialCommunityIcons>['name'];
  iconColor: string;
  title: string;
  subtitle: string;
  trailing: ReactNode;
  onPress: () => void;
}) {
  return (
    <Pressable onPress={onPress} style={({ pressed }) => [styles.item, pressed && { backgroundColor: '#F5F5F5' }]}>
      <View style={[styles.itemIcon, { backgroundColor: withOpacity(iconColor, 0.1) }]}>
        {outlinedIcon ? (
          <MaterialCommunityIcons name={outlinedIcon} size={22} color={iconColor} />
        ) : (
          <MaterialIcons name={icon} size={22} color={iconColor} />
        )}
      </View>
      <View style={{ flex: 1, marginHorizontal: 16 }}>
        <Text style={[typography.bodyMedium, { fontFamily: fonts.semiBold }]}>{title}</Text>
        <Text style={typography.caption}>{subtitle}</Text>
      </View>
      {trailing}
    </Pressable>
  );
}

function SettingsItem({
  icon,
  outlinedIcon,
  title,
  subtitle,
  iconColor,
  onPress,
}: {
  icon: IconName;
  outlinedIcon?: ComponentProps<typeof MaterialCommunityIcons>['name'];
  title: string;
  subtitle: string;
  iconColor: string;
  onPress: () => void;
}) {
  return (
    <ItemShell
      icon={icon}
      outlinedIcon={outlinedIcon}
      iconColor={iconColor}
      title={title}
      subtitle={subtitle}
      onPress={() => {
        haptics.selection();
        onPress();
      }}
      trailing={<MaterialIcons name="arrow-forward-ios" size={14} color={colors.textLight} />}
    />
  );
}

function ToggleItem({
  icon,
  outlinedIcon,
  iconColor,
  activeColor = colors.primary,
  title,
  subtitle,
  value,
  onChange,
}: {
  icon: IconName;
  outlinedIcon?: ComponentProps<typeof MaterialCommunityIcons>['name'];
  iconColor: string;
  activeColor?: string;
  title: string;
  subtitle: string;
  value: boolean | null;
  onChange: (value: boolean) => void;
}) {
  if (value == null) {
    return (
      <View style={{ height: 60, alignItems: 'center', justifyContent: 'center' }}>
        <ActivityIndicator size="large" color={colors.primary} />
      </View>
    );
  }
  return (
    <ItemShell
      icon={icon}
      outlinedIcon={outlinedIcon}
      iconColor={iconColor}
      title={title}
      subtitle={subtitle}
      onPress={() => onChange(!value)}
      trailing={<MaterialSwitch value={value} onValueChange={onChange} activeColor={activeColor} />}
    />
  );
}

/**
 * Bildirim anahtarları: ayar + sistem izni birlikte açıksa açık görünür; uygulamaya
 * dönüldüğünde (izin ayarlardan değişmiş olabilir) yeniden okunur.
 */
function useNotificationToggle(read: () => Promise<boolean>, write: (value: boolean) => Promise<void>) {
  const [enabled, setEnabled] = useState<boolean | null>(null);

  const load = useCallback(async () => {
    const [prefsEnabled, status] = await Promise.all([read(), getNotificationPermission()]);
    setEnabled(prefsEnabled && status === 'granted');
  }, [read]);

  useEffect(() => {
    // eslint-disable-next-line react-hooks/set-state-in-effect
    load();
    const subscription = AppState.addEventListener('change', (state) => {
      if (state === 'active') load();
    });
    return () => subscription.remove();
  }, [load]);

  const onChange = async (value: boolean) => {
    haptics.selection();
    if (value) {
      const hasPermission = await checkAndShowPermissionDialog();
      if (!hasPermission) return;
    }
    setEnabled(value);
    await write(value);
  };

  return [enabled, onChange] as const;
}

function NotificationToggleItem() {
  const [enabled, onChange] = useNotificationToggle(isNotificationsEnabled, setNotificationsEnabled);
  return (
    <ToggleItem
      icon="notifications-none"
      iconColor={colors.primary}
      title="Bildirimleri Al"
      subtitle={enabled ? 'Duyuruları alıyorsunuz' : 'Duyurular kapatıldı'}
      value={enabled}
      onChange={onChange}
    />
  );
}

function DailyNotificationToggleItem() {
  const [enabled, onChange] = useNotificationToggle(isDailyNotificationsEnabled, setDailyNotificationsEnabled);
  return (
    <ToggleItem
      icon="tips-and-updates"
      outlinedIcon="lightbulb-on-outline"
      iconColor={colors.info}
      title="Günlük Hatırlatmalar"
      subtitle={enabled ? 'Gün içinde öneriler alıyorsunuz' : 'Günlük öneriler kapatıldı'}
      value={enabled}
      onChange={onChange}
    />
  );
}

function VefatNotificationToggleItem() {
  const [enabled, onChange] = useNotificationToggle(isVefatNotificationsEnabled, setVefatNotificationsEnabled);
  return (
    <ToggleItem
      icon="history-edu"
      iconColor={VEFAT_COLOR}
      activeColor={VEFAT_COLOR}
      title="Vefat İlanları"
      subtitle={enabled ? 'Vefat ilanlarından haberdar oluyorsunuz' : 'Vefat ilanları bildirimi kapatıldı'}
      value={enabled}
      onChange={onChange}
    />
  );
}

function HapticToggleItem() {
  const [enabled, setEnabled] = useState(hapticsEnabled);
  // Anahtar açıkken "Kapat" etkin, yani titreşimler kapalı.
  const onChange = async (closeVibrations: boolean) => {
    const next = !closeVibrations;
    setEnabled(next);
    await setHapticsEnabled(next);
    if (next) haptics.medium();
  };
  return (
    <ToggleItem
      icon="vibration"
      iconColor={ORANGE}
      title="Titreşimleri Kapat"
      subtitle={enabled ? 'Baskı titreşimleri açık' : 'Titreşimler kapatıldı'}
      value={!enabled}
      onChange={onChange}
    />
  );
}

function BlockedUsersSheet({ visible, onClose }: { visible: boolean; onClose: () => void }) {
  const { height } = useWindowDimensions();
  return (
    <BottomSheet visible={visible} onClose={onClose}>
      <View style={[styles.blockedSheet, { height: height * 0.7 }]}>
        <View style={styles.handle} />
        <View style={styles.blockedHeader}>
          <MaterialIcons name="person-off" size={24} color={colors.error} />
          <Text style={[typography.heading2, { marginLeft: 12 }]}>Engellenen Kullanıcılar</Text>
        </View>
        <Text style={[typography.bodySmall, { marginTop: 8, paddingHorizontal: 24 }]}>
          Engelini kaldırmak istediğiniz kullanıcının yanındaki butona basın.
        </Text>
        <View style={styles.sheetDivider} />
        {visible && <BlockedUsersList />}
      </View>
    </BottomSheet>
  );
}

function BlockedUsersList() {
  const [list, setList] = useState<BlockedUser[] | null>(null);
  const [version, setVersion] = useState(0);

  useEffect(() => {
    let cancelled = false;
    getBlockedUsersList().then((users) => {
      if (!cancelled) setList(users);
    });
    return () => {
      cancelled = true;
    };
  }, [version]);

  if (list == null) {
    return (
      <View style={styles.sheetCenter}>
        <ActivityIndicator size="large" color={colors.primary} />
      </View>
    );
  }

  if (list.length === 0) {
    return (
      <View style={styles.sheetCenter}>
        <MaterialIcons name="person-outline" size={48} color={withOpacity(colors.textLight, 0.5)} />
        <Text style={[typography.bodySmall, { marginTop: 16 }]}>Henüz kimseyi engellemediniz.</Text>
      </View>
    );
  }

  return (
    <ScrollView style={{ flex: 1 }} contentContainerStyle={{ paddingHorizontal: 24, paddingBottom: 24 }}>
      {list.map((user, index) => (
        <View key={user.uid}>
          {index > 0 && <View style={styles.listDivider} />}
          <View style={styles.blockedRow}>
            <View style={styles.smallAvatar}>
              {user.imageUrl ? (
                <Image source={{ uri: user.imageUrl }} style={styles.smallAvatarImage} />
              ) : (
                <MaterialIcons name="person" size={20} color={colors.primary} />
              )}
            </View>
            <View style={{ flex: 1, marginHorizontal: 16 }}>
              <Text style={{ fontFamily: fonts.semiBold, fontSize: 14, color: colors.textPrimary }}>{user.name}</Text>
              <Text style={typography.caption}>{`UID: ${user.uid.substring(0, 8)}...`}</Text>
            </View>
            <Pressable
              style={styles.unblockButton}
              onPress={async () => {
                haptics.selection();
                await unblockUser(user.uid);
                setVersion((v) => v + 1);
                appNotification.success('Engel kaldırıldı.');
              }}>
              <Text style={styles.unblockLabel}>Engeli Kaldır</Text>
            </Pressable>
          </View>
        </View>
      ))}
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.background,
  },
  appBar: {
    backgroundColor: colors.white,
  },
  appBarTitle: {
    height: 56,
    lineHeight: 56,
    paddingHorizontal: 16,
  },
  content: {
    padding: 16,
  },
  card: {
    padding: 16,
    borderRadius: 16,
    backgroundColor: colors.white,
    shadowColor: '#000000',
    shadowOpacity: 0.05,
    shadowRadius: 10,
    shadowOffset: { width: 0, height: 2 },
    elevation: 2,
  },
  row: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  avatar: {
    width: 56,
    height: 56,
    alignItems: 'center',
    justifyContent: 'center',
    borderRadius: 28,
    overflow: 'hidden',
    backgroundColor: colors.primarySurface,
  },
  avatarImage: {
    width: 56,
    height: 56,
  },
  outlinedButton: {
    flex: 1,
    height: 40,
    paddingHorizontal: 12,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    borderRadius: 20,
    borderWidth: 1,
  },
  outlinedLabel: {
    flexShrink: 1,
    marginLeft: 8,
    fontFamily: fonts.medium,
    fontSize: 14,
  },
  loginButton: {
    alignSelf: 'stretch',
    height: 52,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    borderRadius: 16,
  },
  appleButton: {
    borderWidth: 1,
    borderColor: 'rgba(0, 0, 0, 0.1)',
    backgroundColor: colors.white,
  },
  loginLabel: {
    marginLeft: 8,
    fontFamily: fonts.bold,
    fontSize: 14,
  },
  item: {
    minHeight: 72,
    paddingLeft: 16,
    paddingRight: 24,
    paddingVertical: 8,
    flexDirection: 'row',
    alignItems: 'center',
    borderRadius: 14,
    backgroundColor: colors.white,
  },
  itemIcon: {
    padding: 8,
    borderRadius: 10,
  },
  blockedSheet: {
    borderTopLeftRadius: 32,
    borderTopRightRadius: 32,
    backgroundColor: colors.white,
  },
  handle: {
    alignSelf: 'center',
    width: 40,
    height: 4,
    marginTop: 12,
    marginBottom: 24,
    borderRadius: 2,
    backgroundColor: colors.border,
  },
  blockedHeader: {
    paddingHorizontal: 24,
    flexDirection: 'row',
    alignItems: 'center',
  },
  sheetDivider: {
    height: 1,
    marginVertical: 15.5,
    backgroundColor: '#E0E0E0',
  },
  sheetCenter: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
  listDivider: {
    height: 1,
    backgroundColor: '#E0E0E0',
  },
  blockedRow: {
    minHeight: 72,
    flexDirection: 'row',
    alignItems: 'center',
  },
  smallAvatar: {
    width: 40,
    height: 40,
    alignItems: 'center',
    justifyContent: 'center',
    borderRadius: 20,
    overflow: 'hidden',
    backgroundColor: colors.primarySurface,
  },
  smallAvatarImage: {
    width: 40,
    height: 40,
  },
  unblockButton: {
    minHeight: 40,
    paddingHorizontal: 12,
    alignItems: 'center',
    justifyContent: 'center',
  },
  unblockLabel: {
    fontFamily: fonts.bold,
    fontSize: 13,
    color: colors.primary,
  },
});
