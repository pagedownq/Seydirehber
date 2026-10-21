import { MaterialIcons } from '@expo/vector-icons';
import { Pressable, Share, StyleSheet } from 'react-native';

import { getShareText } from '@/constants';
import { haptics } from '@/services/haptics';
import { colors } from '@/theme';

// Flutter lib/core/widgets/share_button.dart karşılığı: içeriğe mağaza linkleri eklenip paylaşılır.
type ShareButtonProps = {
  content: string;
  subject?: string;
  color?: string;
};

export async function shareContent(content: string, subject?: string) {
  try {
    await Share.share({ message: getShareText(content), title: subject }, { subject });
  } catch {}
}

export function ShareButton({ content, subject, color = colors.textPrimary }: ShareButtonProps) {
  return (
    <Pressable
      accessibilityLabel="Paylaş"
      onPress={() => {
        haptics.vibrate();
        shareContent(content, subject);
      }}
      style={({ pressed }) => [styles.button, pressed && styles.pressed]}>
      <MaterialIcons name="share" size={24} color={color} />
    </Pressable>
  );
}

const styles = StyleSheet.create({
  button: {
    width: 48,
    height: 48,
    borderRadius: 24,
    alignItems: 'center',
    justifyContent: 'center',
  },
  pressed: {
    backgroundColor: 'rgba(0, 0, 0, 0.08)',
  },
});
