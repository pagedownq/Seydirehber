import { MaterialIcons } from '@expo/vector-icons';
import {
  addDoc,
  collection,
  doc,
  getDocs,
  limit,
  onSnapshot,
  orderBy,
  query,
  serverTimestamp,
  setDoc,
  Timestamp,
} from '@react-native-firebase/firestore';
import * as ImagePicker from 'expo-image-picker';
import { useEffect, useState } from 'react';
import {
  ActivityIndicator,
  FlatList,
  Image,
  KeyboardAvoidingView,
  Modal,
  Pressable,
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  View,
} from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';

import { CachedImage } from '@/components/cached-image';
import { DateTimePickerModal } from '@/components/date-time-picker-modal';
import { MaterialSwitch } from '@/components/material-switch';
import { OutlinedTextField } from '@/components/outlined-text-field';
import { showSnackbar } from '@/components/snackbar';
import { type FieldConfig, getFields, isReorderable } from '@/features/admin/manage-config';
import { db } from '@/services/firebase';
import { supabase } from '@/services/supabase';
import { colors, fonts, typography } from '@/theme';
import { isTimestamp } from '@/utils/firestore-values';

// Flutter admin_manage_screen.dart _showAddEditDialog karşılığı.
export type EditTarget = { docId: string | null; data: Record<string, unknown> | null };

type PickedImage = { uri: string; mimeType: string };

const pad = (n: number) => String(n).padStart(2, '0');
const formatDate = (date: Date) => `${pad(date.getDate())}.${pad(date.getMonth() + 1)}.${date.getFullYear()}`;

function initialText(field: FieldConfig, value: unknown) {
  if (value != null) return isTimestamp(value) ? formatDate(value.toDate()) : String(value);
  if (field.defaultValue != null) return String(field.defaultValue);
  return '';
}

export function AdminEditSheet({
  target,
  collectionName,
  bucket,
  onClose,
}: {
  target: EditTarget | null;
  collectionName: string;
  bucket: string | null;
  onClose: () => void;
}) {
  // Flutter'da alttan açılan sayfaydı; uzun formlarda (iş ilanı) ekranı kaplayıp klavyeyle karıştığı için
  // kullanıcı isteğiyle tam ekran sayfa yapıldı. Klavye açılınca sadece alan listesi küçülür.
  return (
    <Modal
      visible={target != null}
      animationType="slide"
      // Android: içerik sistem çubuklarının altına uzansın ki güvenli alan boşlukları doğru hesaplansın
      statusBarTranslucent
      navigationBarTranslucent
      onRequestClose={onClose}>
      {target && (
        <EditForm
          key={target.docId ?? 'new'}
          target={target}
          collectionName={collectionName}
          bucket={bucket}
          onClose={onClose}
        />
      )}
    </Modal>
  );
}

function EditForm({
  target,
  collectionName,
  bucket,
  onClose,
}: {
  target: EditTarget;
  collectionName: string;
  bucket: string | null;
  onClose: () => void;
}) {
  const insets = useSafeAreaInsets();
  const { docId, data: existingData } = target;
  const fields = getFields(collectionName);

  const [values, setValues] = useState<Record<string, string>>(() =>
    Object.fromEntries(fields.filter((fd) => !fd.isBoolean).map((fd) => [fd.key, initialText(fd, existingData?.[fd.key])])),
  );
  const [bools, setBools] = useState<Record<string, boolean>>(() =>
    Object.fromEntries(
      fields
        .filter((fd) => fd.isBoolean)
        .map((fd) => {
          const existing = existingData?.[fd.key];
          return [fd.key, typeof existing === 'boolean' ? existing : Boolean(fd.defaultValue)];
        }),
    ),
  );
  const [existingImages, setExistingImages] = useState<string[]>(() => {
    const images = Array.isArray(existingData?.images) ? existingData.images.map(String) : [];
    if (images.length === 0 && typeof existingData?.image_url === 'string') images.push(existingData.image_url);
    return images;
  });
  const [selectedImages, setSelectedImages] = useState<PickedImage[]>([]);
  const [imagesToDelete, setImagesToDelete] = useState<string[]>([]);
  // Flutter: firmalarda bitiş tarihi yoksa "Sınırsız Gösterim" işaretli başlar.
  const [isUnlimited, setIsUnlimited] = useState(
    () => collectionName === 'firmalar' && existingData?.expiry_date == null,
  );
  // Flutter firma seçiminde kategoriyi existingData'ya yazar; yeni kayıtta existingData olmadığı için kaydedilmez.
  const [companyCategory, setCompanyCategory] = useState<unknown>(existingData?.companyCategory);
  const [loading, setLoading] = useState(false);
  const [picker, setPicker] = useState<{ key: string; mode: 'date' | 'time' } | null>(null);
  const [companyPickerKey, setCompanyPickerKey] = useState<string | null>(null);

  const setValue = (key: string, value: string) => setValues((prev) => ({ ...prev, [key]: value }));

  const pickImages = async () => {
    const result = await ImagePicker.launchImageLibraryAsync({
      mediaTypes: ['images'],
      allowsMultipleSelection: true,
      quality: 0.7,
    });
    if (!result.canceled && result.assets.length > 0) {
      setSelectedImages((prev) => [
        ...prev,
        ...result.assets.map((asset) => ({ uri: asset.uri, mimeType: asset.mimeType ?? 'image/jpeg' })),
      ]);
    }
  };

  const save = async () => {
    // Zorunlu alanlar
    for (const field of fields) {
      if (field.required && !(values[field.key] ?? '')) {
        showSnackbar({ message: `${field.label} zorunlu` });
        return;
      }
    }

    setLoading(true);
    try {
      const allImageUrls = [...existingImages];

      // Yeni görselleri Supabase'e paralel yükle
      if (selectedImages.length > 0 && bucket) {
        const newUrls = await Promise.all(
          selectedImages.map(async (image, index) => {
            const fileName = `${Date.now()}_${index}_${image.uri.split('/').pop()}`;
            const buffer = await (await fetch(image.uri)).arrayBuffer();
            const { error } = await supabase.storage
              .from(bucket)
              .upload(fileName, buffer, { contentType: image.mimeType });
            if (error) throw error;
            return supabase.storage.from(bucket).getPublicUrl(fileName).data.publicUrl;
          }),
        );
        allImageUrls.push(...newUrls);
      }

      // Kaldırılan görselleri Supabase'den sil
      for (const url of imagesToDelete) {
        try {
          await supabase.storage.from(bucket ?? '').remove([url.split('/').pop() ?? '']);
        } catch (error) {
          console.warn('Error deleting image:', error);
        }
      }

      // Belge verisi
      const docData: Record<string, unknown> = {};
      for (const field of fields) {
        if (field.isBoolean) {
          docData[field.key] = bools[field.key] ?? false;
          continue;
        }
        const value = (values[field.key] ?? '').trim();
        if (!value) {
          docData[field.key] = null;
        } else if (field.isNumber) {
          const parsed = /^[+-]?\d+$/.test(value) ? parseInt(value, 10) : 0;
          docData[field.key] = parsed;
        } else if (field.key === 'expiry_date' || field.isDate) {
          const parsed = parseDate(value);
          if (parsed) docData[field.key] = Timestamp.fromDate(parsed);
        } else if (field.key === 'instagram') {
          docData[field.key] = value.startsWith('http') ? value : `https://www.instagram.com/${value}`;
        } else if (field.isCompanyPicker) {
          docData[field.key] = value.split(' | ').pop();
          if (companyCategory != null && existingData) docData.companyCategory = companyCategory;
        } else {
          docData[field.key] = value;
        }
      }

      docData.images = allImageUrls;
      docData.image_url = allImageUrls[0] ?? '';

      if (docId == null) {
        docData.created_at = serverTimestamp();

        // Sıralanabilir koleksiyonlarda yeni kayıt en sona eklenir
        if (isReorderable(collectionName)) {
          const last = await getDocs(query(collection(db, collectionName), orderBy('order', 'desc'), limit(1)));
          let nextOrder = 0;
          if (!last.empty) {
            const lastOrder = last.docs[0].data().order;
            if (typeof lastOrder === 'number') nextOrder = Math.trunc(lastOrder) + 1;
          } else {
            const all = await getDocs(collection(db, collectionName));
            for (const item of all.docs) {
              const order = item.data().order ?? -1;
              if (typeof order === 'number' && order >= nextOrder) nextOrder = Math.trunc(order) + 1;
            }
          }
          docData.order = nextOrder;
        }

        if (collectionName === 'admins') {
          const email = String(docData.email ?? '').toLowerCase().trim();
          if (!email) throw 'Email gereklidir';
          await setDoc(doc(db, collectionName, email), docData);
        } else {
          await addDoc(collection(db, collectionName), docData);
        }
      } else {
        await setDoc(doc(db, collectionName, docId), docData, { merge: true });
      }

      onClose();
      showSnackbar({
        message: docId == null ? 'Başarıyla eklendi!' : 'Başarıyla güncellendi!',
        backgroundColor: colors.success,
      });
    } catch (error) {
      setLoading(false);
      showSnackbar({ message: `Hata: ${String(error)}`, backgroundColor: colors.error });
    }
  };

  const isInfo = bools.isInformational ?? false;
  const buttonLabel =
    selectedImages.length > 0 ? 'Fotoğraflar Yükleniyor...' : docId == null ? 'Ekle' : 'Güncelle';

  return (
    <View style={[styles.page, { paddingTop: insets.top }]}>
      <View style={styles.pageHeader}>
        <Pressable hitSlop={8} onPress={onClose} style={styles.headerButton} accessibilityLabel="Kapat">
          <MaterialIcons name="close" size={24} color={colors.textPrimary} />
        </Pressable>
        <Text style={[typography.heading3, { flex: 1 }]} numberOfLines={1}>
          {docId == null ? 'Yeni Ekle' : 'Düzenle'}
        </Text>
      </View>
      <KeyboardAvoidingView style={{ flex: 1 }} behavior="padding">
        <ScrollView
          style={{ flex: 1 }}
          keyboardShouldPersistTaps="handled"
          keyboardDismissMode="interactive"
          contentContainerStyle={{ padding: 20, paddingBottom: 32 }}>
          {bucket != null && (
            <>
              <Text style={styles.sectionLabel}>Fotoğraflar</Text>
              <ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={styles.imageRow}>
                <Pressable onPress={pickImages} style={styles.addImage}>
                  <MaterialIcons name="add-a-photo" size={24} color={colors.primary} />
                </Pressable>
                {existingImages.map((url) => (
                  <View key={url} style={styles.imageWrap}>
                    <CachedImage imageUrl={url} width={80} height={80} borderRadius={12} />
                    <Pressable
                      hitSlop={6}
                      style={[styles.removeImage, { backgroundColor: '#F44336' }]}
                      onPress={() => {
                        setExistingImages((prev) => prev.filter((u) => u !== url));
                        setImagesToDelete((prev) => [...prev, url]);
                      }}>
                      <MaterialIcons name="close" size={16} color={colors.white} />
                    </Pressable>
                  </View>
                ))}
                {selectedImages.map((image) => (
                  <View key={image.uri} style={[styles.imageWrap, { marginRight: 12, marginTop: 8 }]}>
                    <Image source={{ uri: image.uri }} style={styles.localImage} />
                    <Pressable
                      hitSlop={6}
                      style={[styles.removeImage, { backgroundColor: '#000000' }]}
                      onPress={() => setSelectedImages((prev) => prev.filter((i) => i !== image))}>
                      <MaterialIcons name="close" size={16} color={colors.white} />
                    </Pressable>
                  </View>
                ))}
              </ScrollView>
              <View style={{ height: 16 }} />
            </>
          )}

          {fields.map((field) => {
            if (collectionName === 'coupons' && isInfo && (field.key === 'discountPercentage' || field.key === 'total_limit')) {
              return null;
            }
            const isExpiryField = field.key === 'expiry_date';
            const value = values[field.key] ?? '';

            return (
              <View key={field.key}>
                {isExpiryField && collectionName === 'firmalar' && (
                  <Pressable
                    style={styles.checkboxRow}
                    onPress={() => {
                      const next = !isUnlimited;
                      setIsUnlimited(next);
                      if (next) setValue(field.key, '');
                    }}>
                    <MaterialIcons
                      name={isUnlimited ? 'check-box' : 'check-box-outline-blank'}
                      size={24}
                      color={isUnlimited ? colors.primary : '#49454F'}
                    />
                    <Text style={styles.checkboxLabel}>Sınırsız Gösterim</Text>
                  </Pressable>
                )}

                {field.key === 'isInformational' ? (
                  <CouponTypeSelect value={isInfo} onChange={(v) => setBools((prev) => ({ ...prev, [field.key]: v }))} />
                ) : field.isBoolean ? (
                  <Pressable
                    style={styles.switchRow}
                    onPress={() => setBools((prev) => ({ ...prev, [field.key]: !prev[field.key] }))}>
                    <Text style={styles.switchLabel}>{field.label}</Text>
                    <MaterialSwitch
                      value={bools[field.key] ?? false}
                      onValueChange={(v) => setBools((prev) => ({ ...prev, [field.key]: v }))}
                    />
                  </Pressable>
                ) : null}

                {field.isTimeList && (
                  <TimeListPicker
                    field={field}
                    value={value}
                    onChange={(next) => setValue(field.key, next)}
                    onCopyToAll={() => {
                      setValues((prev) => ({
                        ...prev,
                        saatler_haftaici: value,
                        saatler_cumartesi: value,
                        saatler_pazar: value,
                      }));
                      showSnackbar({ message: 'Tüm günlere kopyalandı' });
                    }}
                  />
                )}

                {!field.isTimeList && !field.isBoolean && !(isExpiryField && isUnlimited) && (
                  <View style={{ marginBottom: 12 }}>
                    <FieldInput
                      field={field}
                      value={value}
                      onChange={(next) => setValue(field.key, next)}
                      onPick={() => {
                        if (field.readOnly) return;
                        if (field.isDate) setPicker({ key: field.key, mode: 'date' });
                        else if (field.isTime) setPicker({ key: field.key, mode: 'time' });
                        else if (field.isCompanyPicker) setCompanyPickerKey(field.key);
                      }}
                    />
                  </View>
                )}
              </View>
            );
          })}

        </ScrollView>

        {/* Kaydet butonu her zaman görünür; klavye açıkken klavyenin hemen üstünde durur. */}
        <View style={[styles.footer, { paddingBottom: 12 + insets.bottom }]}>
          <Pressable disabled={loading} onPress={save} style={[styles.saveButton, loading && styles.saveDisabled]}>
            {loading ? (
              <ActivityIndicator size={20} color={colors.white} />
            ) : (
              <Text style={typography.button}>{buttonLabel}</Text>
            )}
          </Pressable>
        </View>
      </KeyboardAvoidingView>

      {picker && (
        <DateTimePickerModal
          mode={picker.mode}
          initial={new Date()}
          minimumDate={picker.mode === 'date' ? new Date(2024, 0, 1) : undefined}
          maximumDate={picker.mode === 'date' ? new Date(2030, 0, 1) : undefined}
          onDone={(date) => {
            const key = picker.key;
            setPicker(null);
            if (!date) return;
            setValue(key, picker.mode === 'date' ? formatDate(date) : `${pad(date.getHours())}:${pad(date.getMinutes())}`);
          }}
        />
      )}

      <CompanyPicker
        visible={companyPickerKey != null}
        onClose={() => setCompanyPickerKey(null)}
        onSelect={(company) => {
          const key = companyPickerKey;
          setCompanyPickerKey(null);
          if (!key) return;
          const name = typeof company.data.ad === 'string' ? company.data.ad : 'İsimsiz';
          setValues((prev) => ({
            ...prev,
            [key]: `${name} | ${company.id}`,
            // companyName alanı olan koleksiyonlarda otomatik doldur
            ...('companyName' in prev ? { companyName: name } : {}),
          }));
          setCompanyCategory(company.data.kategori ?? '');
        }}
      />
    </View>
  );
}

/** Flutter: "dd.MM.yyyy" ya da "dd.MM.yyyy HH:mm". */
function parseDate(value: string): Date | null {
  try {
    const [datePart, timePart] = value.split(' ');
    const [day, month, year] = datePart.split('.').map((p) => parseInt(p, 10));
    let hour = 0;
    let minute = 0;
    if (timePart) [hour, minute] = timePart.split(':').map((p) => parseInt(p, 10));
    if ([day, month, year, hour, minute].some((n) => !Number.isFinite(n))) throw new Error('format');
    return new Date(year, month - 1, day, hour, minute);
  } catch (error) {
    console.warn('Date parse error:', error);
    return null;
  }
}

function FieldInput({
  field,
  value,
  onChange,
  onPick,
}: {
  field: FieldConfig;
  value: string;
  onChange: (value: string) => void;
  onPick: () => void;
}) {
  const isInteraction = field.isDate || field.isTime || field.isCompanyPicker;
  let suffix = null;
  if (field.isDate) suffix = <MaterialIcons name="calendar-today" size={20} color="#49454F" />;
  else if (field.isTime) suffix = <MaterialIcons name="access-time" size={20} color="#49454F" />;
  else if (field.isCompanyPicker)
    suffix = value ? (
      <Pressable hitSlop={8} onPress={() => onChange('')}>
        <MaterialIcons name="clear" size={20} color="#49454F" />
      </Pressable>
    ) : (
      <MaterialIcons name="business" size={20} color="rgba(73, 69, 79, 0.38)" />
    );

  return (
    <OutlinedTextField
      label={field.label}
      value={value}
      onChangeText={onChange}
      multiline={field.multiline}
      lines={4}
      keyboardType={field.isNumber || field.isPhone ? 'number-pad' : 'default'}
      readOnly={field.readOnly}
      onPress={isInteraction && !field.readOnly ? onPick : undefined}
      suffix={suffix}
    />
  );
}

function CouponTypeSelect({ value, onChange }: { value: boolean; onChange: (value: boolean) => void }) {
  const [open, setOpen] = useState(false);
  const options = [
    { value: false, label: 'İndirim Kuponu' },
    { value: true, label: 'Bilgilendirme Kuponu' },
  ];
  return (
    <View style={{ marginBottom: 12 }}>
      <OutlinedTextField
        label="Kupon Türü"
        value={value ? 'Bilgilendirme Kuponu' : 'İndirim Kuponu'}
        onPress={() => setOpen(true)}
        suffix={<MaterialIcons name="arrow-drop-down" size={24} color="#49454F" />}
      />
      <Modal visible={open} transparent animationType="fade" onRequestClose={() => setOpen(false)}>
        <Pressable style={styles.dialogBarrier} onPress={() => setOpen(false)}>
          <View style={styles.menu}>
            {options.map((option) => (
              <Pressable
                key={option.label}
                onPress={() => {
                  setOpen(false);
                  onChange(option.value);
                }}
                style={[styles.menuItem, option.value === value && { backgroundColor: 'rgba(0, 0, 0, 0.06)' }]}>
                <Text style={typography.bodyLarge}>{option.label}</Text>
              </Pressable>
            ))}
          </View>
        </Pressable>
      </Modal>
    </View>
  );
}

function TimeListPicker({
  field,
  value,
  onChange,
  onCopyToAll,
}: {
  field: FieldConfig;
  value: string;
  onChange: (value: string) => void;
  onCopyToAll: () => void;
}) {
  const [input, setInput] = useState('');
  const times = value
    .split(',')
    .filter((t) => t.trim())
    .sort();

  const addTime = (raw: string) => {
    if (!raw) return;
    // 8.30 -> 08:30, 8 -> 08:00
    let formatted = raw.replaceAll('.', ':').trim();
    if (formatted.includes(':')) {
      const parts = formatted.split(':');
      formatted = `${parts[0].padStart(2, '0')}:${parts.length > 1 ? parts[1].padStart(2, '0') : '00'}`;
    } else if (formatted.length <= 2) {
      formatted = `${formatted.padStart(2, '0')}:00`;
    }
    if (!times.includes(formatted)) onChange([...times, formatted].sort().join(','));
    setInput('');
  };

  return (
    <View style={{ marginBottom: 16 }}>
      <View style={styles.timeHeader}>
        <Text style={[styles.sectionLabel, { flex: 1, marginBottom: 0 }]}>{field.label}</Text>
        {field.key === 'saatler_hergun' && (
          <Pressable onPress={onCopyToAll} style={styles.copyButton}>
            <MaterialIcons name="copy-all" size={16} color={colors.primary} />
            <Text style={styles.copyText}>Tüm Günlere Kopyala</Text>
          </Pressable>
        )}
      </View>
      <View style={styles.timeBox}>
        {times.length === 0 ? (
          <Text style={styles.emptyTimes}>Henüz saat eklenmedi</Text>
        ) : (
          <View style={styles.chips}>
            {times.map((time) => (
              <View key={time} style={styles.chip}>
                <Text style={styles.chipText}>{time}</Text>
                <Pressable hitSlop={6} onPress={() => onChange(times.filter((t) => t !== time).join(','))}>
                  <MaterialIcons name="close" size={12} color="#49454F" />
                </Pressable>
              </View>
            ))}
          </View>
        )}
        <View style={styles.timeInputRow}>
          <TextInput
            value={input}
            onChangeText={setInput}
            placeholder="Saat gir (Örn: 08:30 veya 08)"
            placeholderTextColor={colors.textSecondary}
            keyboardType="numbers-and-punctuation"
            returnKeyType="done"
            submitBehavior="submit"
            onSubmitEditing={() => addTime(input)}
            style={styles.timeInput}
          />
          <Pressable onPress={() => addTime(input)} style={styles.addTimeButton}>
            <MaterialIcons name="add" size={24} color={colors.white} />
          </Pressable>
        </View>
        <Text style={styles.timeHint}>Enter tuşu ile hızlıca ekleyebilirsiniz</Text>
      </View>
    </View>
  );
}

type Company = { id: string; data: Record<string, unknown> };

function CompanyPicker({
  visible,
  onClose,
  onSelect,
}: {
  visible: boolean;
  onClose: () => void;
  onSelect: (company: Company) => void;
}) {
  return (
    <Modal visible={visible} transparent animationType="fade" onRequestClose={onClose}>
      <Pressable style={styles.dialogBarrier} onPress={onClose}>
        <Pressable style={styles.dialog}>
          <Text style={[typography.heading2, { fontSize: 24, fontFamily: fonts.regular }]}>Firma Seç</Text>
          <View style={styles.searchRow}>
            <MaterialIcons name="search" size={24} color="#49454F" />
            {/* Flutter'da arama kutusu süzme yapmıyor (onChanged boş); aynen korundu. */}
            <TextInput placeholder="Firma ara..." placeholderTextColor={colors.textSecondary} style={styles.searchInput} />
          </View>
          {visible && <CompanyList onSelect={onSelect} />}
        </Pressable>
      </Pressable>
    </Modal>
  );
}

function CompanyList({ onSelect }: { onSelect: (company: Company) => void }) {
  const [companies, setCompanies] = useState<Company[] | null>(null);

  useEffect(
    () =>
      onSnapshot(
        query(collection(db, 'firmalar'), orderBy('ad')),
        (snapshot) => setCompanies(snapshot.docs.map((d) => ({ id: d.id, data: d.data() as Record<string, unknown> }))),
        (error) => {
          console.warn('Firma listesi alınamadı:', error);
          setCompanies([]);
        },
      ),
    [],
  );

  if (!companies) {
    return (
      <View style={{ padding: 24, alignItems: 'center' }}>
        <ActivityIndicator size="large" color={colors.primary} />
      </View>
    );
  }
  return (
    <FlatList
      data={companies}
      keyExtractor={(c) => c.id}
      style={{ marginTop: 16 }}
      renderItem={({ item }) => (
        <Pressable onPress={() => onSelect(item)} style={styles.companyItem}>
          <Text style={typography.bodyLarge}>{typeof item.data.ad === 'string' ? item.data.ad : 'İsimsiz'}</Text>
        </Pressable>
      )}
    />
  );
}

const styles = StyleSheet.create({
  page: {
    flex: 1,
    backgroundColor: colors.white,
  },
  pageHeader: {
    height: 56,
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 4,
    borderBottomWidth: 1,
    borderBottomColor: colors.divider,
  },
  headerButton: {
    width: 48,
    height: 48,
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: 4,
  },
  footer: {
    paddingHorizontal: 20,
    paddingTop: 12,
    borderTopWidth: 1,
    borderTopColor: colors.divider,
    backgroundColor: colors.white,
  },
  sectionLabel: {
    marginBottom: 8,
    fontFamily: fonts.bold,
    fontSize: 14,
    color: colors.textPrimary,
  },
  imageRow: {
    alignItems: 'flex-start',
    paddingTop: 8,
    paddingRight: 8,
  },
  addImage: {
    width: 80,
    height: 80,
    marginRight: 8,
    alignItems: 'center',
    justifyContent: 'center',
    borderRadius: 12,
    borderWidth: 1,
    borderColor: colors.border,
    backgroundColor: colors.primarySurface,
  },
  imageWrap: {
    marginRight: 8,
  },
  localImage: {
    width: 80,
    height: 80,
    borderRadius: 12,
  },
  removeImage: {
    position: 'absolute',
    top: -8,
    right: -8,
    padding: 4,
    borderRadius: 999,
    shadowColor: '#000000',
    shadowOpacity: 0.2,
    shadowRadius: 4,
    elevation: 3,
  },
  checkboxRow: {
    minHeight: 40,
    flexDirection: 'row',
    alignItems: 'center',
  },
  checkboxLabel: {
    marginLeft: 16,
    fontFamily: fonts.regular,
    fontSize: 14,
    color: colors.textPrimary,
  },
  switchRow: {
    minHeight: 48,
    flexDirection: 'row',
    alignItems: 'center',
  },
  switchLabel: {
    flex: 1,
    fontFamily: fonts.regular,
    fontSize: 14,
    color: colors.textPrimary,
  },
  saveButton: {
    paddingVertical: 14,
    alignItems: 'center',
    justifyContent: 'center',
    borderRadius: 12,
    backgroundColor: colors.primary,
  },
  saveDisabled: {
    backgroundColor: 'rgba(29, 27, 32, 0.12)',
  },
  timeHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 8,
  },
  copyButton: {
    paddingHorizontal: 8,
    paddingVertical: 4,
    flexDirection: 'row',
    alignItems: 'center',
  },
  copyText: {
    marginLeft: 4,
    fontFamily: fonts.medium,
    fontSize: 12,
    color: colors.primary,
  },
  timeBox: {
    padding: 12,
    borderRadius: 12,
    borderWidth: 1,
    borderColor: '#E0E0E0',
    backgroundColor: '#FAFAFA',
  },
  emptyTimes: {
    paddingVertical: 8,
    fontFamily: fonts.regular,
    fontSize: 12,
    color: '#9E9E9E',
  },
  chips: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 6,
  },
  chip: {
    paddingHorizontal: 8,
    paddingVertical: 4,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    borderRadius: 8,
    borderWidth: 1,
    borderColor: '#CAC4D0',
    backgroundColor: colors.white,
  },
  chipText: {
    fontFamily: fonts.semiBold,
    fontSize: 11,
    color: colors.textPrimary,
  },
  timeInputRow: {
    marginTop: 12,
    flexDirection: 'row',
    alignItems: 'center',
  },
  timeInput: {
    flex: 1,
    paddingHorizontal: 12,
    paddingVertical: 10,
    borderRadius: 8,
    borderWidth: 1,
    borderColor: '#79747E',
    fontFamily: fonts.regular,
    fontSize: 14,
    color: colors.textPrimary,
  },
  addTimeButton: {
    width: 40,
    height: 40,
    marginLeft: 8,
    alignItems: 'center',
    justifyContent: 'center',
    borderRadius: 8,
    backgroundColor: colors.primary,
  },
  timeHint: {
    marginTop: 4,
    marginLeft: 4,
    fontFamily: fonts.regular,
    fontSize: 10,
    color: '#9E9E9E',
  },
  dialogBarrier: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    paddingHorizontal: 40,
    paddingVertical: 48,
    backgroundColor: colors.barrier,
  },
  dialog: {
    alignSelf: 'stretch',
    maxHeight: '100%',
    padding: 24,
    borderRadius: 28,
    backgroundColor: colors.white,
  },
  searchRow: {
    marginTop: 16,
    flexDirection: 'row',
    alignItems: 'center',
    borderBottomWidth: 1,
    borderBottomColor: '#79747E',
  },
  searchInput: {
    flex: 1,
    marginLeft: 12,
    paddingVertical: 12,
    fontFamily: fonts.regular,
    fontSize: 16,
    color: colors.textPrimary,
  },
  companyItem: {
    minHeight: 48,
    paddingHorizontal: 16,
    justifyContent: 'center',
  },
  menu: {
    alignSelf: 'stretch',
    paddingVertical: 8,
    borderRadius: 4,
    backgroundColor: colors.white,
    elevation: 8,
  },
  menuItem: {
    height: 48,
    paddingHorizontal: 16,
    justifyContent: 'center',
  },
});
