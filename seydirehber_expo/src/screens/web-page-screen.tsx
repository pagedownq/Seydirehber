import { type ComponentType, type Ref, useRef, useState } from 'react';
import { StyleSheet, View } from 'react-native';
import { WebView as RNWebView, type WebViewProps } from 'react-native-webview';

import { AppBar } from '@/components/app-bar';
import { ErrorView } from '@/components/error-view';
import { WebViewShimmer } from '@/components/shimmer';
import { haptics } from '@/services/haptics';
import { colors } from '@/theme';

// Flutter pharmacy_screen.dart / weather_screen.dart ortak yapısı: WebView yüklenirken shimmer,
// hata olursa ErrorView (Tekrar Dene sayfayı yeniden yükler).

// WebView'in sınıf bileşeni tipi React 19 JSX tipleriyle örtüşmüyor; çalışma zamanında aynı bileşen.
type WebViewHandle = { reload: () => void };
const WebView = RNWebView as unknown as ComponentType<WebViewProps & { ref?: Ref<WebViewHandle> }>;
type WebPageScreenProps = {
  title: string;
  url: string;
  errorMessage: string;
  /** Flutter AbsorbPointer: sayfa dokunmaya kapalı (hava durumu). */
  interactive?: boolean;
  /** Dış uygulamada açılması gereken linkler; true dönerse WebView o adrese gitmez. */
  onExternalLink?: (url: string) => boolean;
};

export function WebPageScreen({ title, url, errorMessage, interactive = true, onExternalLink }: WebPageScreenProps) {
  const webViewRef = useRef<WebViewHandle>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [hasError, setHasError] = useState(false);

  return (
    <View style={styles.container}>
      <AppBar title={title} />
      <View style={{ flex: 1 }}>
        <View style={StyleSheet.absoluteFill} pointerEvents={interactive ? 'auto' : 'none'}>
          <WebView
            ref={webViewRef}
            source={{ uri: url }}
            javaScriptEnabled
            onLoadStart={() => {
              setHasError(false);
              setIsLoading(true);
            }}
            onLoadEnd={() => setIsLoading(false)}
            onError={() => {
              setHasError(true);
              setIsLoading(false);
            }}
            onShouldStartLoadWithRequest={(request) => !(onExternalLink?.(request.url) ?? false)}
            style={{ flex: 1 }}
          />
        </View>
        {isLoading && !hasError && (
          <View style={[StyleSheet.absoluteFill, styles.cover]}>
            <WebViewShimmer />
          </View>
        )}
        {hasError && (
          <View style={[StyleSheet.absoluteFill, styles.cover]}>
            <ErrorView
              message={errorMessage}
              onRetry={() => {
                haptics.selection();
                setIsLoading(true);
                setHasError(false);
                webViewRef.current?.reload();
              }}
            />
          </View>
        )}
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.background,
  },
  cover: {
    backgroundColor: colors.background,
  },
});
