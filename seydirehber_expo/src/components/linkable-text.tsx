import { Linking, type StyleProp, StyleSheet, Text, type TextStyle } from 'react-native';

import { colors, fonts } from '@/theme';

// Flutter lib/core/widgets/linkable_text.dart karşılığı: metindeki http(s)/www linkleri tıklanabilir olur.
const URL_REGEX = /((https?:\/\/|www\.)[^\s]+)/gi;

type LinkableTextProps = {
  text: string;
  style?: StyleProp<TextStyle>;
  numberOfLines?: number;
};

async function openLink(url: string) {
  const cleanUrl = url.startsWith('http') ? url : `https://${url}`;
  try {
    if (await Linking.canOpenURL(cleanUrl)) await Linking.openURL(cleanUrl);
  } catch {}
}

export function LinkableText({ text, style, numberOfLines }: LinkableTextProps) {
  const parts = text.split(URL_REGEX);

  return (
    <Text style={style} numberOfLines={numberOfLines}>
      {parts.map((part, index) => {
        // split, yakalama gruplarını da döndürür: [metin, url, önek, metin, ...]
        if (index % 3 === 2) return null;
        if (index % 3 === 1) {
          return (
            <Text key={index} style={styles.link} onPress={() => openLink(part)}>
              {part}
            </Text>
          );
        }
        return part;
      })}
    </Text>
  );
}

const styles = StyleSheet.create({
  link: {
    color: colors.primary,
    textDecorationLine: 'underline',
    fontFamily: fonts.semiBold,
  },
});
