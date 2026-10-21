import { MaterialIcons } from '@expo/vector-icons';
import { LinearGradient } from 'expo-linear-gradient';
import { type Href, router } from 'expo-router';
import type { ComponentProps } from 'react';
import { useState } from 'react';
import { Image, type ImageSourcePropType, Pressable, StyleSheet, Text, View } from 'react-native';

import { PatternCanvas, type Shape } from '@/components/pattern-canvas';
import { openForum } from '@/features/forum/forum-rules-sheet';
import {
  busPattern,
  forumPattern,
  mapPattern,
  marketPattern,
  newsPattern,
  vefatPattern,
} from '@/features/home/service-patterns';
import { haptics } from '@/services/haptics';
import { colors, fonts, typography } from '@/theme';

// Flutter lib/features/home/widgets/service_grid.dart karşılığı: 2 sütun, 12 boşluk, en/boy 1.6.
type IconName = ComponentProps<typeof MaterialIcons>['name'];

type ServiceCardProps = {
  title: string;
  icon?: IconName;
  image?: ImageSourcePropType;
  gradient?: [string, string];
  backgroundColor?: string;
  borderColor?: string;
  iconColor: string;
  textColor?: string;
  applyColorToImage?: boolean;
  imageSize?: number;
  pattern?: (width: number, height: number) => Shape[];
  /** Gölge rengi (Flutter: gradient'in ilk rengi ya da arka plan rengi). */
  shadowColor: string;
  /** Satırı tek başına kaplar (tek sayıda kart kaldığında). */
  wide?: boolean;
  onPress: () => void;
};

const GAP = 12;
const HORIZONTAL_PADDING = 16;
const ASPECT_RATIO = 1.6;

export function ServiceGrid() {
  const [width, setWidth] = useState(0);
  // Ölçülen genişlik yan boşlukları (16 + 16) da içeriyor.
  const cardWidth = Math.floor((width - HORIZONTAL_PADDING * 2 - GAP) / 2);
  const cardHeight = cardWidth / ASPECT_RATIO;

  const go = (href: Href) => () => router.push(href);

  const cards: ServiceCardProps[] = [
    {
      title: 'Nöbetçi Eczane',
      image: require('@/assets/images/eczane_logo.png'),
      gradient: ['#E53935', '#EF5350'],
      iconColor: colors.white,
      imageSize: 32,
      shadowColor: '#E53935',
      onPress: go('/pharmacy' as Href),
    },
    {
      title: 'Noterler',
      image: require('@/assets/images/noter.png'),
      backgroundColor: colors.white,
      borderColor: '#000000',
      textColor: '#000000',
      iconColor: '#000000',
      applyColorToImage: false,
      imageSize: 38,
      shadowColor: '#FFFFFF',
      onPress: go('/noterler' as Href),
    },
    {
      title: 'Halk Pazarları',
      icon: 'storefront',
      gradient: ['#FF8F00', '#FFB300'],
      iconColor: colors.white,
      pattern: marketPattern,
      shadowColor: '#FF8F00',
      onPress: go('/pazarlar' as Href),
    },
    {
      title: 'Otobüs Saatleri',
      icon: 'directions-bus',
      gradient: ['#00897B', '#26A69A'],
      iconColor: colors.white,
      pattern: busPattern,
      shadowColor: '#00897B',
      onPress: go('/otobus' as Href),
    },
    {
      title: 'Vefat Edenler',
      icon: 'person-off',
      gradient: ['#546E7A', '#78909C'],
      iconColor: colors.white,
      pattern: vefatPattern,
      shadowColor: '#546E7A',
      onPress: go('/vefat' as Href),
    },
    {
      title: 'Seydi Harita',
      icon: 'map',
      backgroundColor: colors.white,
      borderColor: 'rgba(76, 175, 80, 0.3)',
      textColor: colors.primary,
      iconColor: colors.primary,
      pattern: mapPattern,
      shadowColor: '#FFFFFF',
      onPress: go('/seydi-map' as Href),
    },
    {
      title: 'Haberler',
      icon: 'newspaper',
      gradient: ['#2E7D32', '#43A047'],
      iconColor: colors.white,
      pattern: newsPattern,
      shadowColor: '#2E7D32',
      onPress: go('/news'),
    },
    {
      title: 'Forum',
      icon: 'forum',
      gradient: ['#5C35CC', '#7B52E8'],
      iconColor: colors.white,
      pattern: forumPattern,
      shadowColor: '#5C35CC',
      // Forum kuralları onaylandıysa doğrudan açılır, değilse önce kurallar sayfası gösterilir.
      onPress: openForum,
    },
    // Expo'ya özgü (Flutter'da yok)
    {
      title: 'İş İlanları',
      icon: 'work',
      gradient: ['#6D4C41', '#8D6E63'],
      iconColor: colors.white,
      pattern: marketPattern,
      shadowColor: '#6D4C41',
      wide: true,
      onPress: go('/is-ilanlari' as Href),
    },
  ];

  return (
    <View style={styles.grid} onLayout={(event) => setWidth(event.nativeEvent.layout.width)}>
      {width > 0 &&
        cards.map((card) => (
          <View
            key={card.title}
            style={{ width: card.wide ? cardWidth * 2 + GAP : cardWidth, height: card.wide ? cardHeight * 0.75 : cardHeight }}>
            <ServiceCard {...card} />
          </View>
        ))}
    </View>
  );
}

function ServiceCard({
  title,
  icon,
  image,
  gradient,
  backgroundColor,
  borderColor,
  iconColor,
  textColor = colors.white,
  applyColorToImage = true,
  imageSize,
  pattern,
  shadowColor,
  onPress,
}: ServiceCardProps) {
  const size = imageSize ?? 28;

  return (
    <Pressable
      onPress={() => {
        haptics.selection();
        onPress();
      }}
      style={({ pressed }) => [
        styles.card,
        {
          // Gradyanlı kartlarda düz arka plan iOS'un gölgeyi verimli çizmesi için (gradyan üstünü kaplar).
          backgroundColor: backgroundColor ?? gradient?.[0],
          borderWidth: borderColor ? 1.5 : 0,
          borderColor,
          shadowColor,
          // Beyaz kartlarda Flutter gölgesi beyaz (görünmez); Android'in siyah elevation gölgesi kapatılır.
          elevation: shadowColor === '#FFFFFF' ? 0 : 4,
        },
        pressed && styles.pressed,
      ]}>
      <View style={styles.clip}>
        {gradient && (
          <LinearGradient colors={gradient} start={{ x: 0, y: 0.5 }} end={{ x: 1, y: 0.5 }} style={StyleSheet.absoluteFill} />
        )}
        {pattern && <PatternCanvas draw={pattern} />}
        <View style={styles.content}>
          <View style={[styles.iconBox, { backgroundColor: withOpacity(textColor, 0.1) }]}>
            {image ? (
              <Image
                source={image}
                style={{ width: size, height: size, tintColor: applyColorToImage ? iconColor : undefined }}
                resizeMode="contain"
              />
            ) : (
              <MaterialIcons name={icon ?? 'help-outline'} size={size} color={iconColor} />
            )}
          </View>
          <Text style={[styles.title, { color: textColor }]} numberOfLines={2}>
            {title}
          </Text>
        </View>
      </View>
    </Pressable>
  );
}

function withOpacity(color: string, opacity: number) {
  if (color.startsWith('#') && color.length === 7) {
    const r = parseInt(color.slice(1, 3), 16);
    const g = parseInt(color.slice(3, 5), 16);
    const b = parseInt(color.slice(5, 7), 16);
    return `rgba(${r}, ${g}, ${b}, ${opacity})`;
  }
  return color;
}

const styles = StyleSheet.create({
  grid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: GAP,
    paddingHorizontal: HORIZONTAL_PADDING,
  },
  card: {
    flex: 1,
    borderRadius: 16,
    shadowOpacity: 0.2,
    shadowRadius: 8,
    shadowOffset: { width: 0, height: 3 },
    elevation: 4,
  },
  pressed: {
    opacity: 0.9,
  },
  clip: {
    flex: 1,
    borderRadius: 16,
    overflow: 'hidden',
  },
  content: {
    flex: 1,
    justifyContent: 'space-between',
    paddingHorizontal: 16,
    paddingVertical: 12,
  },
  iconBox: {
    alignSelf: 'flex-start',
    padding: 6,
    borderRadius: 10,
  },
  title: {
    ...typography.bodyMedium,
    marginTop: 4,
    fontFamily: fonts.semiBold,
    fontSize: 13,
  },
});
