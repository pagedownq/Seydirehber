import { MaterialIcons } from '@expo/vector-icons';
import { useState } from 'react';
import { ActivityIndicator, Modal, Pressable, ScrollView, StyleSheet, Text, TextInput, View } from 'react-native';

import { appNotification } from '@/components/app-notification';
import { BottomSheet } from '@/components/bottom-sheet';
import { addReview, PROFANITY_DETECTED, type Review, updateReview } from '@/features/reviews/review-service';
import { haptics } from '@/services/haptics';
import { colors, fonts } from '@/theme';

// Flutter lib/core/widgets/post_review_bottom_sheet.dart karşılığı.
type PostReviewSheetProps = {
  visible: boolean;
  onClose: () => void;
  targetId: string;
  targetType: string;
  existingReview?: Review;
};

export function PostReviewSheet(props: PostReviewSheetProps) {
  return (
    <BottomSheet visible={props.visible} onClose={props.onClose} avoidKeyboard>
      {/* Sayfa her açılışta formu sıfırdan kursun diye yalnızca görünürken çizilir. */}
      {props.visible && <PostReviewForm {...props} />}
    </BottomSheet>
  );
}

function PostReviewForm({ onClose, targetId, targetType, existingReview }: PostReviewSheetProps) {
  const [rating, setRating] = useState(existingReview?.rating ?? 0);
  const [comment, setComment] = useState(existingReview?.comment ?? '');
  const [submitting, setSubmitting] = useState(false);
  // Zaten yorum yapmışsa onaylamıştır.
  const [isOver18, setIsOver18] = useState(existingReview != null);
  const [focused, setFocused] = useState(false);
  const [profanityVisible, setProfanityVisible] = useState(false);

  const canSubmit = !submitting && rating > 0 && isOver18;

  const submit = async () => {
    setSubmitting(true);
    try {
      if (existingReview) {
        await updateReview({ reviewId: existingReview.id, rating, comment });
      } else {
        await addReview({ targetId, targetType, rating, comment });
      }
      onClose();
      appNotification.success(existingReview ? 'Yorumunuz güncellendi.' : 'Yorumunuz başarıyla eklendi.');
    } catch (error) {
      if (error === PROFANITY_DETECTED) {
        setProfanityVisible(true);
      } else {
        appNotification.error(error instanceof Error ? error.message : 'Hata oluştu, tekrar deneyin.');
      }
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <View style={styles.sheet}>
      <ScrollView contentContainerStyle={styles.content} keyboardShouldPersistTaps="handled">
        <View style={styles.handle} />
        <View style={styles.header}>
          <Text style={styles.title}>{existingReview ? 'Yorumu Düzenle' : 'Deneyimini Paylaş'}</Text>
          <Pressable
            hitSlop={8}
            style={styles.closeButton}
            onPress={() => {
              haptics.selection();
              onClose();
            }}>
            <MaterialIcons name="close" size={20} color="#64748B" />
          </Pressable>
        </View>
        <Text style={styles.subtitle}>Bu yer/firma hakkında ne düşünüyorsun?</Text>

        <View style={styles.stars}>
          {Array.from({ length: 5 }, (_, index) => (
            <Pressable
              key={index}
              style={styles.star}
              onPress={() => {
                haptics.selection();
                setRating(index + 1);
              }}>
              <MaterialIcons name="star" size={48} color={index < rating ? '#FBBF24' : '#E2E8F0'} />
            </Pressable>
          ))}
        </View>

        <TextInput
          value={comment}
          onChangeText={setComment}
          multiline
          numberOfLines={4}
          placeholder="Fikirlerin başkalarına ilham verebilir..."
          placeholderTextColor="#BDBDBD"
          onFocus={() => setFocused(true)}
          onBlur={() => setFocused(false)}
          style={[styles.input, focused && styles.inputFocused]}
          textAlignVertical="top"
        />

        <Pressable
          style={styles.checkboxRow}
          onPress={() => {
            haptics.selection();
            setIsOver18((value) => !value);
          }}>
          <View style={[styles.checkbox, isOver18 && styles.checkboxChecked]}>
            {isOver18 && <MaterialIcons name="check" size={14} color={colors.white} />}
          </View>
          <View style={{ flex: 1 }}>
            <Text style={styles.checkboxTitle}>18 yaşından büyüğüm ve topluluk kurallarını kabul ediyorum</Text>
            <Text style={styles.checkboxSubtitle}>
              Yorumlarımın saygılı olacağını, hakaret içermeyeceğini ve uygunsuz içeriklerin moderatörler tarafından
              kaldırılabileceğini onaylıyorum.
            </Text>
          </View>
        </Pressable>

        <Pressable
          disabled={!canSubmit}
          onPress={() => {
            haptics.vibrate();
            submit();
          }}
          style={[styles.submit, !canSubmit && styles.submitDisabled]}>
          {submitting ? (
            <ActivityIndicator color={colors.white} size="small" />
          ) : (
            <Text style={[styles.submitText, !canSubmit && styles.submitTextDisabled]}>
              {existingReview ? 'Yorumu Güncelle' : 'Yorumu Gönder'}
            </Text>
          )}
        </Pressable>
        <View style={{ height: 24 }} />
      </ScrollView>

      <ProfanityDialog visible={profanityVisible} onClose={() => setProfanityVisible(false)} />
    </View>
  );
}

function ProfanityDialog({ visible, onClose }: { visible: boolean; onClose: () => void }) {
  return (
    <Modal visible={visible} transparent animationType="fade" onRequestClose={onClose}>
      <Pressable style={styles.dialogBarrier} onPress={onClose}>
        <Pressable style={styles.dialog}>
          <View style={styles.warningCircle}>
            <MaterialIcons name="warning-amber" size={40} color="#F44336" />
          </View>
          <Text style={styles.dialogTitle}>Uygunsuz İçerik!</Text>
          <Text style={styles.dialogText}>
            Yorumunuz topluluk kurallarımıza aykırı veya uygunsuz kelimeler içeriyor olabilir. Lütfen mesajınızı
            kontrol edip tekrar deneyin.
          </Text>
          <Pressable
            style={styles.dialogButton}
            onPress={() => {
              haptics.selection();
              onClose();
            }}>
            <Text style={styles.dialogButtonText}>Düzenle</Text>
          </Pressable>
        </Pressable>
      </Pressable>
    </Modal>
  );
}

const styles = StyleSheet.create({
  sheet: {
    maxHeight: '95%',
    borderTopLeftRadius: 32,
    borderTopRightRadius: 32,
    backgroundColor: colors.white,
    shadowColor: '#000000',
    shadowOpacity: 0.12,
    shadowRadius: 20,
    elevation: 16,
  },
  content: {
    paddingHorizontal: 24,
    alignItems: 'stretch',
  },
  handle: {
    alignSelf: 'center',
    width: 40,
    height: 4,
    marginTop: 12,
    marginBottom: 24,
    borderRadius: 2,
    backgroundColor: '#EEEEEE',
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
  },
  title: {
    fontFamily: fonts.black,
    fontSize: 22,
    letterSpacing: -0.5,
    color: '#1E293B',
  },
  closeButton: {
    padding: 4,
    margin: 8,
    borderRadius: 999,
    backgroundColor: '#F5F5F5',
  },
  subtitle: {
    marginTop: 12,
    fontFamily: fonts.regular,
    fontSize: 14,
    color: '#64748B',
    textAlign: 'center',
  },
  stars: {
    marginTop: 24,
    paddingVertical: 8,
    flexDirection: 'row',
    justifyContent: 'center',
  },
  star: {
    paddingHorizontal: 4,
  },
  input: {
    marginTop: 24,
    minHeight: 120,
    padding: 20,
    borderRadius: 20,
    borderWidth: 1,
    borderColor: '#F1F5F9',
    backgroundColor: '#F8FAFC',
    fontFamily: fonts.regular,
    fontSize: 15,
    color: colors.textPrimary,
  },
  inputFocused: {
    borderWidth: 1.5,
    borderColor: colors.primary,
  },
  checkboxRow: {
    marginTop: 16,
    flexDirection: 'row',
    alignItems: 'flex-start',
    gap: 16,
  },
  checkbox: {
    width: 18,
    height: 18,
    marginTop: 3,
    alignItems: 'center',
    justifyContent: 'center',
    borderRadius: 2,
    borderWidth: 2,
    borderColor: colors.textSecondary,
  },
  checkboxChecked: {
    borderColor: colors.primary,
    backgroundColor: colors.primary,
  },
  checkboxTitle: {
    fontFamily: fonts.semiBold,
    fontSize: 14,
    color: '#1E293B',
  },
  checkboxSubtitle: {
    fontFamily: fonts.regular,
    fontSize: 12,
    color: '#64748B',
  },
  submit: {
    height: 56,
    marginTop: 16,
    alignItems: 'center',
    justifyContent: 'center',
    borderRadius: 30,
    backgroundColor: colors.primary,
    shadowColor: colors.primary,
    shadowOpacity: 0.4,
    shadowRadius: 4,
    shadowOffset: { width: 0, height: 2 },
    elevation: 4,
  },
  submitDisabled: {
    backgroundColor: 'rgba(27, 27, 27, 0.12)',
    shadowOpacity: 0,
    elevation: 0,
  },
  submitText: {
    fontFamily: fonts.extraBold,
    fontSize: 16,
    color: colors.white,
  },
  submitTextDisabled: {
    color: 'rgba(27, 27, 27, 0.38)',
  },
  dialogBarrier: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    paddingHorizontal: 40,
    backgroundColor: colors.barrier,
  },
  dialog: {
    width: '100%',
    alignItems: 'center',
    padding: 24,
    borderRadius: 24,
    backgroundColor: colors.white,
  },
  warningCircle: {
    padding: 16,
    borderRadius: 999,
    backgroundColor: '#FFEBEE',
  },
  dialogTitle: {
    marginTop: 20,
    fontFamily: fonts.bold,
    fontSize: 20,
    color: '#1E293B',
  },
  dialogText: {
    marginTop: 12,
    fontFamily: fonts.regular,
    fontSize: 14,
    lineHeight: 21,
    color: '#64748B',
    textAlign: 'center',
  },
  dialogButton: {
    alignSelf: 'stretch',
    marginTop: 24,
    paddingVertical: 14,
    alignItems: 'center',
    borderRadius: 16,
    backgroundColor: '#1E293B',
  },
  dialogButtonText: {
    fontFamily: fonts.semiBold,
    fontSize: 14,
    color: colors.white,
  },
});
