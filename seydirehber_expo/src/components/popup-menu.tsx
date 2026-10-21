import { MaterialIcons } from '@expo/vector-icons';
import type { ComponentProps, ComponentRef, ReactNode } from 'react';
import { useRef, useState } from 'react';
import {
  Modal,
  Pressable,
  type StyleProp,
  StyleSheet,
  Text,
  type TextStyle,
  useWindowDimensions,
  View,
} from 'react-native';

import { colors, fonts } from '@/theme';

// Flutter PopupMenuButton karşılığı: üç nokta ikonuna basınca hemen yanında açılan menü.
export type PopupMenuItem = {
  value: string;
  label: string;
  icon: ReactNode;
  labelStyle?: StyleProp<TextStyle>;
};

type PopupMenuProps = {
  items: PopupMenuItem[];
  onSelect: (value: string) => void;
  icon?: ComponentProps<typeof MaterialIcons>['name'];
  iconSize?: number;
  iconColor?: string;
  /** Flutter PopupMenuPosition: 'over' butonun üstünde, 'under' butonun 5 px altında açılır. */
  position?: 'over' | 'under';
  /** Menü açılırken (ör. klavyeyi kapatmak için) çağrılır. */
  onOpen?: () => void;
};

const MENU_WIDTH = 220;

export function PopupMenu({
  items,
  onSelect,
  icon = 'more-vert',
  iconSize = 20,
  iconColor = '#64748B',
  position: placement = 'over',
  onOpen,
}: PopupMenuProps) {
  const anchorRef = useRef<ComponentRef<typeof View>>(null);
  const [position, setPosition] = useState<{ top: number; right: number } | null>(null);
  const { width: screenWidth } = useWindowDimensions();

  const open = () => {
    onOpen?.();
    anchorRef.current?.measureInWindow((x, y, width, height) => {
      setPosition({
        top: placement === 'under' ? y + height + 5 : y,
        right: Math.max(8, screenWidth - (x + width)),
      });
    });
  };

  if (items.length === 0) return null;

  return (
    <>
      <View ref={anchorRef} collapsable={false}>
        <Pressable onPress={open} hitSlop={4} style={styles.trigger}>
          <MaterialIcons name={icon} size={iconSize} color={iconColor} />
        </Pressable>
      </View>
      <Modal visible={position != null} transparent animationType="fade" onRequestClose={() => setPosition(null)}>
        <Pressable style={StyleSheet.absoluteFill} onPress={() => setPosition(null)} />
        {position && (
          <View style={[styles.menu, { top: position.top, right: position.right }]}>
            {items.map((item) => (
              <Pressable
                key={item.value}
                style={({ pressed }) => [styles.item, pressed && styles.itemPressed]}
                onPress={() => {
                  setPosition(null);
                  onSelect(item.value);
                }}>
                {item.icon}
                <Text style={[styles.label, item.labelStyle]}>{item.label}</Text>
              </Pressable>
            ))}
          </View>
        )}
      </Modal>
    </>
  );
}

const styles = StyleSheet.create({
  trigger: {
    width: 40,
    height: 40,
    alignItems: 'center',
    justifyContent: 'center',
  },
  menu: {
    position: 'absolute',
    minWidth: 112,
    maxWidth: MENU_WIDTH + 60,
    paddingVertical: 8,
    borderRadius: 16,
    backgroundColor: colors.white,
    shadowColor: '#000000',
    shadowOpacity: 0.2,
    shadowRadius: 12,
    shadowOffset: { width: 0, height: 6 },
    elevation: 10,
  },
  item: {
    minHeight: 48,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    paddingHorizontal: 16,
  },
  itemPressed: {
    backgroundColor: 'rgba(0, 0, 0, 0.05)',
  },
  label: {
    fontFamily: fonts.regular,
    fontSize: 16,
    color: colors.textPrimary,
  },
});
