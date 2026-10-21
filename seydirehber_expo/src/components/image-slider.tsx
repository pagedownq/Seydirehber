import { type ComponentRef, useEffect, useRef, useState } from 'react';
import { ScrollView, StyleSheet, useWindowDimensions, View } from 'react-native';
import Animated, { useAnimatedStyle, withTiming } from 'react-native-reanimated';

import { CachedImage } from '@/components/cached-image';

// Flutter lib/core/widgets/image_slider.dart karşılığı: birden fazla görselde 4 sn'de bir otomatik geçiş,
// altta beyaz nokta göstergesi (aktif olan 24 px genişler).
export function ImageSlider({ images }: { images: string[] }) {
  const { width } = useWindowDimensions();
  const scrollRef = useRef<ComponentRef<typeof ScrollView>>(null);
  const [currentPage, setCurrentPage] = useState(0);
  const pageRef = useRef(0);

  useEffect(() => {
    if (images.length <= 1) return;
    const timer = setInterval(() => {
      pageRef.current = pageRef.current < images.length - 1 ? pageRef.current + 1 : 0;
      scrollRef.current?.scrollTo({ x: pageRef.current * width, animated: true });
    }, 4000);
    return () => clearInterval(timer);
  }, [images.length, width]);

  if (images.length === 0) return <CachedImage imageUrl="" isCompany />;

  return (
    <View style={StyleSheet.absoluteFill}>
      <ScrollView
        ref={scrollRef}
        horizontal
        pagingEnabled
        showsHorizontalScrollIndicator={false}
        onMomentumScrollEnd={(event) => {
          const page = Math.round(event.nativeEvent.contentOffset.x / width);
          pageRef.current = page;
          setCurrentPage(page);
        }}>
        {images.map((url, index) => (
          <View key={`${url}-${index}`} style={{ width, height: '100%' }}>
            <CachedImage imageUrl={url} isCompany />
          </View>
        ))}
      </ScrollView>
      {images.length > 1 && (
        <View pointerEvents="none" style={styles.dots}>
          {images.map((url, index) => (
            <Dot key={`${url}-${index}`} active={index === currentPage} />
          ))}
        </View>
      )}
    </View>
  );
}

function Dot({ active }: { active: boolean }) {
  const style = useAnimatedStyle(() => ({
    width: withTiming(active ? 24 : 8, { duration: 300 }),
    backgroundColor: withTiming(active ? '#FFFFFF' : 'rgba(255, 255, 255, 0.5)', { duration: 300 }),
  }));
  return <Animated.View style={[styles.dot, style]} />;
}

const styles = StyleSheet.create({
  dots: {
    position: 'absolute',
    bottom: 30,
    left: 0,
    right: 0,
    flexDirection: 'row',
    justifyContent: 'center',
  },
  dot: {
    height: 8,
    marginHorizontal: 4,
    borderRadius: 4,
  },
});
