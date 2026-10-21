import { MaterialIcons } from '@expo/vector-icons';
import { useState } from 'react';
import { ActivityIndicator, Pressable, ScrollView, StyleSheet, Text, TextInput, View } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';

import { BottomSheet } from '@/components/bottom-sheet';
import { showSnackbar } from '@/components/snackbar';
import { editOwnPost, editOwnReply } from '@/features/forum/forum-service';
import { FORUM_CATEGORIES, type ForumPost, type ForumReply } from '@/features/forum/forum-types';
import { colors, fonts, typography } from '@/theme';

// Flutter lib/features/forum/widgets/forum_edit_sheet.dart karşılığı.
const errorMessage = (error: unknown) => (error instanceof Error ? error.message : String(error));

export function EditPostSheet({ post, visible, onClose }: { post: ForumPost; visible: boolean; onClose: () => void }) {
  return (
    <BottomSheet visible={visible} onClose={onClose} avoidKeyboard>
      {visible && <EditPostForm post={post} onClose={onClose} />}
    </BottomSheet>
  );
}

function EditPostForm({ post, onClose }: { post: ForumPost; onClose: () => void }) {
  const [title, setTitle] = useState(post.title);
  const [content, setContent] = useState(post.content);
  const [category, setCategory] = useState(post.category);
  const [pickerOpen, setPickerOpen] = useState(false);
  const [loading, setLoading] = useState(false);

  const save = async () => {
    if (!title.trim() || !content.trim()) {
      showSnackbar({ message: 'Başlık ve içerik boş bırakılamaz.', floating: false });
      return;
    }
    setLoading(true);
    try {
      await editOwnPost({ postId: post.id, title, content, category });
      onClose();
      showSnackbar({ message: 'Gönderi güncellendi.', floating: false });
    } catch (error) {
      showSnackbar({ message: `Hata: ${errorMessage(error)}`, floating: false });
    } finally {
      setLoading(false);
    }
  };

  const selected = FORUM_CATEGORIES.find((c) => c.value === category);

  return (
    <SheetFrame title="Gönderiyi Düzenle">
      <Pressable style={styles.field} onPress={() => setPickerOpen((v) => !v)}>
        <Text style={styles.fieldLabel}>Kategori</Text>
        <View style={styles.dropdownRow}>
          <Text style={[typography.bodyMedium, { flex: 1 }]}>{selected ? `${selected.emoji} ${selected.label}` : category}</Text>
          <MaterialIcons name="keyboard-arrow-down" size={24} color={colors.textSecondary} />
        </View>
      </Pressable>
      {pickerOpen && (
        <View style={styles.dropdownMenu}>
          {FORUM_CATEGORIES.filter((c) => c.value !== 'tumu').map((c) => (
            <Pressable
              key={c.value}
              style={styles.dropdownItem}
              onPress={() => {
                setCategory(c.value);
                setPickerOpen(false);
              }}>
              <Text style={typography.bodyMedium}>{`${c.emoji} ${c.label}`}</Text>
            </Pressable>
          ))}
        </View>
      )}
      <LabeledInput label="Başlık" value={title} onChangeText={setTitle} />
      <LabeledInput label="İçerik" value={content} onChangeText={setContent} multiline />
      <SheetButtons loading={loading} onCancel={onClose} onSave={save} />
    </SheetFrame>
  );
}

export function EditReplySheet({ reply, visible, onClose }: { reply: ForumReply; visible: boolean; onClose: () => void }) {
  return (
    <BottomSheet visible={visible} onClose={onClose} avoidKeyboard>
      {visible && <EditReplyForm reply={reply} onClose={onClose} />}
    </BottomSheet>
  );
}

function EditReplyForm({ reply, onClose }: { reply: ForumReply; onClose: () => void }) {
  const [content, setContent] = useState(reply.content);
  const [loading, setLoading] = useState(false);

  const save = async () => {
    if (!content.trim()) {
      showSnackbar({ message: 'İçerik boş bırakılamaz.', floating: false });
      return;
    }
    setLoading(true);
    try {
      await editOwnReply(reply.id, content);
      onClose();
      showSnackbar({ message: 'Yanıt güncellendi.', floating: false });
    } catch (error) {
      showSnackbar({ message: `Hata: ${errorMessage(error)}`, floating: false });
    } finally {
      setLoading(false);
    }
  };

  return (
    <SheetFrame title="Yanıtı Düzenle">
      <LabeledInput label="İçerik" value={content} onChangeText={setContent} multiline />
      <SheetButtons loading={loading} onCancel={onClose} onSave={save} />
    </SheetFrame>
  );
}

function SheetFrame({ title, children }: { title: string; children: React.ReactNode }) {
  const insets = useSafeAreaInsets();
  return (
    <View style={[styles.sheet, { marginTop: insets.top + 20 }]}>
      <ScrollView keyboardShouldPersistTaps="handled" contentContainerStyle={{ paddingBottom: 30 }}>
        <View style={styles.handle} />
        <Text style={[typography.heading3, styles.title]}>{title}</Text>
        {children}
      </ScrollView>
    </View>
  );
}

function LabeledInput({
  label,
  value,
  onChangeText,
  multiline = false,
}: {
  label: string;
  value: string;
  onChangeText: (value: string) => void;
  multiline?: boolean;
}) {
  const [focused, setFocused] = useState(false);
  return (
    <View style={[styles.field, focused && styles.fieldFocused]}>
      <Text style={[styles.fieldLabel, focused && { color: colors.primary }]}>{label}</Text>
      <TextInput
        value={value}
        onChangeText={onChangeText}
        multiline={multiline}
        numberOfLines={multiline ? 5 : 1}
        onFocus={() => setFocused(true)}
        onBlur={() => setFocused(false)}
        style={[styles.input, multiline && { minHeight: 72, maxHeight: 120 }]}
        textAlignVertical={multiline ? 'top' : 'center'}
      />
    </View>
  );
}

function SheetButtons({ loading, onCancel, onSave }: { loading: boolean; onCancel: () => void; onSave: () => void }) {
  return (
    <View style={styles.buttons}>
      <Pressable disabled={loading} style={styles.cancel} onPress={onCancel}>
        <Text style={[typography.bodyMedium, { fontFamily: fonts.semiBold }]}>İptal</Text>
      </Pressable>
      <Pressable disabled={loading} style={styles.save} onPress={onSave}>
        {loading ? (
          <ActivityIndicator color={colors.white} size="small" />
        ) : (
          <Text style={[typography.bodyMedium, { fontFamily: fonts.semiBold, color: colors.white }]}>Kaydet</Text>
        )}
      </Pressable>
    </View>
  );
}

const styles = StyleSheet.create({
  sheet: {
    paddingTop: 10,
    paddingHorizontal: 20,
    borderTopLeftRadius: 24,
    borderTopRightRadius: 24,
    backgroundColor: colors.white,
  },
  handle: {
    alignSelf: 'center',
    width: 40,
    height: 4,
    borderRadius: 2,
    backgroundColor: '#E0E0E0',
  },
  title: {
    marginTop: 20,
    marginBottom: 24,
    textAlign: 'center',
  },
  field: {
    marginBottom: 16,
    paddingHorizontal: 16,
    paddingTop: 8,
    paddingBottom: 10,
    borderRadius: 12,
    borderWidth: 1.5,
    borderColor: 'transparent',
    backgroundColor: colors.background,
  },
  fieldFocused: {
    borderColor: colors.primary,
  },
  fieldLabel: {
    ...typography.bodySmall,
    fontSize: 11,
    color: colors.textLight,
  },
  input: {
    ...typography.bodyMedium,
    paddingVertical: 4,
  },
  dropdownRow: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: 4,
  },
  dropdownMenu: {
    marginTop: -8,
    marginBottom: 16,
    borderRadius: 12,
    backgroundColor: colors.white,
    elevation: 6,
    shadowColor: '#000000',
    shadowOpacity: 0.12,
    shadowRadius: 8,
    shadowOffset: { width: 0, height: 4 },
  },
  dropdownItem: {
    paddingHorizontal: 16,
    paddingVertical: 14,
  },
  buttons: {
    marginTop: 8,
    flexDirection: 'row',
    gap: 16,
  },
  cancel: {
    flex: 1,
    alignItems: 'center',
    paddingVertical: 16,
    borderRadius: 12,
    borderWidth: 1,
    borderColor: colors.border,
  },
  save: {
    flex: 1,
    alignItems: 'center',
    paddingVertical: 16,
    borderRadius: 12,
    backgroundColor: colors.primary,
  },
});
