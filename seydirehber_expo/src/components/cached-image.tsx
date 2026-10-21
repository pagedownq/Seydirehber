import { MaterialIcons } from '@expo/vector-icons';
import { Image, type ImageContentFit } from 'expo-image';
import { useState } from 'react';
import { type DimensionValue, Image as NativeImage, StyleSheet, View } from 'react-native';

import { Shimmer } from '@/components/shimmer';
import { colors } from '@/theme';

// Flutter lib/core/widgets/cached_image_widget.dart karşılığı (expo-image disk + bellek önbelleği).
type CachedImageProps = {
  imageUrl: string;
  width?: DimensionValue;
  height?: DimensionValue;
  contentFit?: ImageContentFit;
  borderRadius?: number;
  isCompany?: boolean;
  isEvent?: boolean;
};

// Paketteki yer tutucular RN Image ile çizilir: expo-image yerel (require) kaynaklarda
// RN Image.resolveAssetSource'a gidiyor; cihazda Image.js'te 'undefined is not a function'
// hatası görüldükten sonra bu yola geçildi (kesin neden yığın izinden doğrulanmadı).
const EVENT_PLACEHOLDER = require('@/assets/images/etkinlikyok.png');
const PHOTO_PLACEHOLDER = require('@/assets/images/fotoyok.png');

export function CachedImage({
  imageUrl,
  width = '100%',
  height = '100%',
  contentFit = 'cover',
  borderRadius = 0,
  isCompany = false,
  isEvent = false,
}: CachedImageProps) {
  const [loaded, setLoaded] = useState(false);
  const [failed, setFailed] = useState(false);

  const box = { width, height, borderRadius };
  const hasAssetFallback = isCompany || isEvent;

  if (!imageUrl || failed) {
    return (
      <View style={[styles.fallback, box]}>
        {hasAssetFallback ? (
          <NativeImage
            source={isEvent ? EVENT_PLACEHOLDER : PHOTO_PLACEHOLDER}
            style={StyleSheet.absoluteFill}
            resizeMode={contentFit === 'contain' ? 'contain' : 'cover'}
          />
        ) : (
          <MaterialIcons
            name={imageUrl ? 'broken-image' : 'image-not-supported'}
            size={24}
            color={colors.primaryDark}
          />
        )}
      </View>
    );
  }

  return (
    <View style={[styles.container, box]}>
      <Image
        source={{ uri: imageUrl }}
        style={StyleSheet.absoluteFill}
        contentFit={contentFit}
        cachePolicy="memory-disk"
        transition={500}
        onLoad={() => setLoaded(true)}
        onError={() => setFailed(true)}
      />
      {!loaded && (
        <View style={StyleSheet.absoluteFill}>
          <Shimmer borderRadius={borderRadius} />
        </View>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    overflow: 'hidden',
  },
  fallback: {
    overflow: 'hidden',
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: colors.primarySurface,
  },
});
