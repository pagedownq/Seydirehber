import { MaterialIcons } from '@expo/vector-icons';
import { useScrollToTop } from 'expo-router';
import { StatusBar } from 'expo-status-bar';
import * as WebBrowser from 'expo-web-browser';
import type { ComponentProps, ComponentRef } from 'react';
import { useRef, useState } from 'react';
import {
  FlatList,
  Linking,
  Modal,
  Pressable,
  RefreshControl,
  ScrollView,
  StyleSheet,
  Text,
  useWindowDimensions,
  View,
} from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';

import { CachedImage } from '@/components/cached-image';
import { ErrorView } from '@/components/error-view';
import { NewsCardShimmer } from '@/components/shimmer';
import { showSnackbar } from '@/components/snackbar';
import { formattedDate, type News, useNews } from '@/features/news/news-query';
import { haptics } from '@/services/haptics';
import { colors, fonts, typography } from '@/theme';

// Flutter lib/features/news/screens/news_screen.dart karşılığı.
type IconName = ComponentProps<typeof MaterialIcons>['name'];

export function NewsScreen() {
  const insets = useSafeAreaInsets();
  const { data, isPending, isError, isRefetching, refetch } = useNews();
  const [disclaimerVisible, setDisclaimerVisible] = useState(false);
  const listRef = useRef<ComponentRef<typeof FlatList<News>>>(null);
  useScrollToTop(listRef as unknown as Parameters<typeof useScrollToTop>[0]);

  const retry = () => {
    haptics.selection();
    refetch();
  };

  let body;
  if (isPending) {
    body = (
      <View style={{ padding: 16, gap: 16 }}>
        {Array.from({ length: 3 }, (_, i) => (
          <NewsCardShimmer key={i} />
        ))}
      </View>
    );
  } else if (isError) {
    body = (
      <ErrorView
        message="Haberler yüklenirken bir hata oluştu. Lütfen internet bağlantınızı kontrol edip tekrar deneyin."
        onRetry={retry}
      />
    );
  } else if (!data || data.length === 0) {
    body = (
      <ErrorView
        title="Haber Bulunamadı"
        message="Şu an görüntülenecek bir haber bulunamadı veya internet bağlantınızda bir sorun var."
        onRetry={retry}
      />
    );
  } else {
    body = (
      <FlatList
        ref={listRef}
        data={data}
        keyExtractor={(item, index) => `${item.link}-${index}`}
        contentContainerStyle={{ padding: 16 }}
        ItemSeparatorComponent={() => <View style={{ height: 16 }} />}
        renderItem={({ item }) => <NewsCard news={item} />}
        ListFooterComponent={<MoreNewsFooter />}
        refreshControl={
          <RefreshControl
            refreshing={isRefetching}
            onRefresh={() => {
              refetch();
            }}
            colors={[colors.primary]}
            tintColor={colors.primary}
          />
        }
      />
    );
  }

  return (
    <View style={styles.container}>
      <StatusBar style="dark" />
      <View style={[styles.appBar, { paddingTop: insets.top }]}>
        <View style={styles.toolbar}>
          <Text style={[typography.appBarTitle, { flex: 1 }]}>Haberler</Text>
          <Pressable hitSlop={8} style={styles.iconButton} onPress={() => setDisclaimerVisible(true)}>
            <MaterialIcons name="info-outline" size={24} color={colors.textSecondary} />
          </Pressable>
        </View>
      </View>
      <View style={{ flex: 1 }}>{body}</View>
      <LegalDisclaimer visible={disclaimerVisible} onClose={() => setDisclaimerVisible(false)} />
    </View>
  );
}

async function openNews(link: string) {
  haptics.selection();
  if (!link) return;
  try {
    // Flutter LaunchMode.platformDefault: uygulama içi tarayıcı (SFSafariViewController / Custom Tab).
    await WebBrowser.openBrowserAsync(link);
  } catch {
    showSnackbar({ message: 'Haber bağlantısı açılamadı.', floating: false });
  }
}

function NewsCard({ news }: { news: News }) {
  return (
    <Pressable onPress={() => openNews(news.link)} style={styles.card}>
      <View style={styles.imageWrap}>
        {news.imageUrl ? (
          <CachedImage imageUrl={news.imageUrl} height={200} />
        ) : (
          <View style={styles.imagePlaceholder}>
            <MaterialIcons name="newspaper" size={50} color={colors.primary} />
          </View>
        )}
        <View style={styles.sourceBadge}>
          <Text style={styles.sourceText}>{news.source}</Text>
        </View>
      </View>
      <View style={styles.cardBody}>
        <Text style={styles.title} numberOfLines={2}>
          {news.title}
        </Text>
        <Text style={styles.description} numberOfLines={3}>
          {news.description}
        </Text>
        <View style={styles.dateRow}>
          <MaterialIcons name="access-time" size={14} color={colors.textLight} />
          <Text style={styles.date}>{formattedDate(news)}</Text>
        </View>
        <View style={styles.readButton}>
          <Text style={styles.readText}>Haberi Kaynağında Oku</Text>
          <MaterialIcons name="arrow-forward" size={16} color={colors.primary} />
        </View>
      </View>
    </Pressable>
  );
}

function MoreNewsFooter() {
  return (
    <View style={styles.footer}>
      <MaterialIcons name="auto-awesome-motion" size={40} color={colors.textLight} />
      <Text style={styles.footerTitle}>Tüm haberleri gördünüz</Text>
      <Text style={styles.footerText}>Daha fazlası ve arşiv için haber sitesini ziyaret edin.</Text>
      <Pressable
        style={styles.footerButton}
        onPress={async () => {
          haptics.selection();
          const url = 'https://www.seydisehirhaber.com';
          try {
            if (await Linking.canOpenURL(url)) await Linking.openURL(url);
          } catch {}
        }}>
        <MaterialIcons name="open-in-new" size={18} color={colors.white} />
        <Text style={typography.button}>Haber Sitesine Git</Text>
      </Pressable>
      <View style={{ height: 40 }} />
    </View>
  );
}

function LegalDisclaimer({ visible, onClose }: { visible: boolean; onClose: () => void }) {
  const { height } = useWindowDimensions();
  return (
    <Modal visible={visible} transparent animationType="fade" statusBarTranslucent onRequestClose={onClose}>
      <Pressable style={styles.barrier} onPress={onClose}>
        <Pressable style={[styles.dialog, { maxHeight: height * 0.7 }]}>
          <View style={styles.dialogHeader}>
            <MaterialIcons name="gavel" size={40} color={colors.primary} />
            <Text style={styles.dialogTitle}>Yasal Bilgilendirme</Text>
          </View>
          <ScrollView style={{ flexGrow: 0 }} contentContainerStyle={styles.dialogContent}>
            <LegalPoint icon="newspaper" text="Haberler, resmi izinli web sitesinden otomatik olarak çekilmektedir." />
            <LegalPoint icon="copyright" text="Tüm telif hakları ve sorumluluk haberin asıl sahibi olan kuruluşa aittir." />
            <LegalPoint icon="link" text="Sadece kısa özet sunulmakta, içerik tamamı için orijinal siteye yönlendirilmektedir." />
            <LegalPoint icon="contact-mail" text="İçerik kaldırma talepleri için: seydirehber@gmail.com" />
          </ScrollView>
          <View style={styles.dialogFooter}>
            <Pressable
              style={styles.dialogButton}
              onPress={() => {
                haptics.selection();
                onClose();
              }}>
              <Text style={styles.dialogButtonText}>Anladım ve Kabul Ediyorum</Text>
            </Pressable>
          </View>
        </Pressable>
      </Pressable>
    </Modal>
  );
}

function LegalPoint({ icon, text }: { icon: IconName; text: string }) {
  return (
    <View style={styles.legalPoint}>
      <MaterialIcons name={icon} size={20} color={colors.primary} />
      <Text style={styles.legalText}>{text}</Text>
    </View>
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
  toolbar: {
    height: 56,
    flexDirection: 'row',
    alignItems: 'center',
    paddingLeft: 16,
    paddingRight: 8,
  },
  iconButton: {
    width: 48,
    height: 48,
    marginRight: 8,
    alignItems: 'center',
    justifyContent: 'center',
  },
  card: {
    borderRadius: 20,
    backgroundColor: colors.white,
    shadowColor: '#000000',
    shadowOpacity: 0.06,
    shadowRadius: 15,
    shadowOffset: { width: 0, height: 5 },
    elevation: 3,
  },
  imageWrap: {
    height: 200,
    borderTopLeftRadius: 20,
    borderTopRightRadius: 20,
    overflow: 'hidden',
  },
  imagePlaceholder: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: colors.primarySurface,
  },
  sourceBadge: {
    position: 'absolute',
    top: 12,
    right: 12,
    paddingHorizontal: 10,
    paddingVertical: 4,
    borderRadius: 8,
    backgroundColor: 'rgba(76, 175, 80, 0.9)',
  },
  sourceText: {
    fontFamily: fonts.bold,
    fontSize: 10,
    color: colors.white,
  },
  cardBody: {
    padding: 20,
  },
  title: {
    ...typography.bodyMedium,
    fontFamily: fonts.bold,
    fontSize: 16,
  },
  description: {
    ...typography.bodySmall,
    marginTop: 10,
    lineHeight: 18,
    color: colors.textLight,
  },
  dateRow: {
    marginTop: 16,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
  },
  date: {
    fontFamily: fonts.regular,
    fontSize: 12,
    color: colors.textLight,
  },
  readButton: {
    marginTop: 14,
    paddingVertical: 12,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 8,
    borderRadius: 12,
    borderWidth: 1,
    borderColor: 'rgba(76, 175, 80, 0.2)',
    backgroundColor: 'rgba(76, 175, 80, 0.1)',
  },
  readText: {
    fontFamily: fonts.bold,
    fontSize: 14,
    color: colors.primary,
  },
  footer: {
    alignItems: 'center',
    paddingTop: 40,
  },
  footerTitle: {
    ...typography.bodyMedium,
    marginTop: 12,
    fontFamily: fonts.medium,
    color: colors.textSecondary,
  },
  footerText: {
    ...typography.bodySmall,
    marginTop: 8,
    color: colors.textLight,
    textAlign: 'center',
  },
  footerButton: {
    marginTop: 20,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    paddingHorizontal: 24,
    paddingVertical: 12,
    borderRadius: 12,
    backgroundColor: colors.primary,
  },
  barrier: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    paddingHorizontal: 32,
    paddingVertical: 60,
    backgroundColor: colors.barrier,
  },
  dialog: {
    width: '100%',
    maxWidth: 400,
    borderRadius: 24,
    overflow: 'hidden',
    backgroundColor: colors.white,
    elevation: 8,
  },
  dialogHeader: {
    alignItems: 'center',
    paddingVertical: 20,
    backgroundColor: colors.primarySurface,
  },
  dialogTitle: {
    marginTop: 8,
    fontFamily: fonts.bold,
    fontSize: 18,
    color: colors.primary,
  },
  dialogContent: {
    paddingHorizontal: 20,
    paddingVertical: 16,
    gap: 10,
  },
  legalPoint: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    gap: 12,
    padding: 12,
    borderRadius: 16,
    borderWidth: 1,
    borderColor: 'rgba(76, 175, 80, 0.05)',
    backgroundColor: colors.background,
  },
  legalText: {
    flex: 1,
    fontFamily: fonts.regular,
    fontSize: 13,
    lineHeight: 19.5,
    color: colors.textPrimary,
  },
  dialogFooter: {
    paddingHorizontal: 20,
    paddingBottom: 20,
  },
  dialogButton: {
    alignItems: 'center',
    paddingVertical: 14,
    borderRadius: 12,
    backgroundColor: colors.primary,
  },
  dialogButtonText: {
    fontFamily: fonts.bold,
    fontSize: 14,
    color: colors.white,
  },
});
