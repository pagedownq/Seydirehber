import { MaterialIcons } from '@expo/vector-icons';
import { type Href, router } from 'expo-router';
import { useState } from 'react';
import { FlatList, Keyboard, Pressable, ScrollView, StyleSheet, Text, TextInput, View } from 'react-native';

import { AppBar } from '@/components/app-bar';
import { EmptyState } from '@/components/empty-state';
import { ErrorView } from '@/components/error-view';
import { Shimmer } from '@/components/shimmer';
import type { LiveDoc } from '@/features/firestore/live-query';
import { createdAt, jobFields, timeAgo, useJobs, visibleJobs } from '@/features/jobs/jobs';
import { haptics } from '@/services/haptics';
import { colors, fonts, typography } from '@/theme';

// İş İlanları listesi (Expo'ya özgü, Flutter'da yok).
const ALL = 'Tümü';

export function JobsScreen() {
  const state = useJobs();
  const [search, setSearch] = useState('');
  const [workType, setWorkType] = useState(ALL);

  let body;
  if (state.status === 'loading') {
    body = (
      <View style={{ padding: 16, gap: 12 }}>
        {Array.from({ length: 4 }, (_, i) => (
          <Shimmer key={i} height={130} borderRadius={16} />
        ))}
      </View>
    );
  } else if (state.status === 'error' && state.docs.length === 0) {
    // Yetki hatası (ör. Firestore kuralı yayında değil) internet sorunu gibi gösterilmesin.
    const denied = (state.error as { code?: string }).code === 'firestore/permission-denied';
    body = denied ? (
      <ErrorView
        icon="lock-outline"
        title="İlanlar şu an görüntülenemiyor"
        message="Lütfen daha sonra tekrar deneyin."
        onRetry={() => useJobs.refresh()}
      />
    ) : (
      <ErrorView message="İş ilanları yüklenemedi." onRetry={() => useJobs.refresh()} />
    );
  } else {
    const jobs = visibleJobs(state.docs);
    const workTypes = [ALL, ...new Set(jobs.map((j) => jobFields(j.data).workType).filter(Boolean))];
    const query = search.trim().toLocaleLowerCase('tr-TR');
    const filtered = jobs.filter((job) => {
      const fields = jobFields(job.data);
      if (workType !== ALL && fields.workType !== workType) return false;
      if (!query) return true;
      return [fields.title, fields.employer, fields.description].some((text) =>
        text.toLocaleLowerCase('tr-TR').includes(query),
      );
    });

    body =
      jobs.length === 0 ? (
        <EmptyState
          icon="work-outline"
          title="Şu an yayında ilan yok"
          subtitle="Yeni iş ilanları eklendiğinde burada görünecek."
        />
      ) : (
        <FlatList
          data={filtered}
          keyExtractor={(item) => item.id}
          keyboardShouldPersistTaps="handled"
          contentContainerStyle={{ paddingHorizontal: 16, paddingBottom: 24 }}
          ItemSeparatorComponent={() => <View style={{ height: 12 }} />}
          ListHeaderComponent={
            <View style={{ paddingTop: 12, paddingBottom: 14 }}>
              <SearchBox value={search} onChange={setSearch} />
              {workTypes.length > 2 && (
                <ScrollView
                  horizontal
                  showsHorizontalScrollIndicator={false}
                  style={{ marginHorizontal: -16, marginTop: 12 }}
                  contentContainerStyle={{ paddingHorizontal: 16, gap: 8 }}>
                  {workTypes.map((type) => {
                    const active = type === workType;
                    return (
                      <Pressable
                        key={type}
                        onPress={() => {
                          haptics.selection();
                          setWorkType(type);
                        }}
                        style={[styles.chip, active && styles.chipActive]}>
                        <Text style={[styles.chipText, active && styles.chipTextActive]}>{type}</Text>
                      </Pressable>
                    );
                  })}
                </ScrollView>
              )}
              <Text style={styles.count}>{filtered.length} ilan</Text>
            </View>
          }
          ListEmptyComponent={
            <View style={styles.noResult}>
              <MaterialIcons name="search-off" size={40} color={colors.textLight} />
              <Text style={[typography.bodyMedium, { marginTop: 8, color: colors.textSecondary }]}>
                Aramanıza uygun ilan bulunamadı
              </Text>
            </View>
          }
          renderItem={({ item }) => <JobCard job={item} />}
        />
      );
  }

  return (
    <View style={styles.container}>
      <AppBar title="İş İlanları" />
      <View style={{ flex: 1 }}>{body}</View>
    </View>
  );
}

function SearchBox({ value, onChange }: { value: string; onChange: (value: string) => void }) {
  return (
    <View style={styles.search}>
      <MaterialIcons name="search" size={22} color={colors.primary} style={{ marginHorizontal: 12 }} />
      <TextInput
        value={value}
        onChangeText={onChange}
        placeholder="Pozisyon veya işveren ara..."
        placeholderTextColor={colors.textLight}
        style={styles.searchInput}
        returnKeyType="search"
      />
      {value.length > 0 && (
        <Pressable
          hitSlop={8}
          style={{ paddingHorizontal: 12 }}
          onPress={() => {
            onChange('');
            Keyboard.dismiss();
          }}>
          <MaterialIcons name="close" size={20} color={colors.textLight} />
        </Pressable>
      )}
    </View>
  );
}

function JobCard({ job }: { job: LiveDoc }) {
  const fields = jobFields(job.data);
  const meta = [fields.workType, fields.salary].filter(Boolean);

  return (
    <Pressable
      onPress={() => {
        haptics.selection();
        router.push(`/is-ilanlari/${job.id}` as Href);
      }}
      style={({ pressed }) => [styles.card, pressed && { opacity: 0.9 }]}>
      <View style={styles.cardTop}>
        <View style={styles.cardIcon}>
          <MaterialIcons name="work" size={22} color={colors.white} />
        </View>
        <View style={{ flex: 1, marginLeft: 12 }}>
          <Text style={styles.cardTitle} numberOfLines={2}>
            {fields.title}
          </Text>
          {fields.employer ? (
            <Text style={styles.cardEmployer} numberOfLines={1}>
              {fields.employer}
            </Text>
          ) : null}
        </View>
        <MaterialIcons name="chevron-right" size={22} color={colors.textLight} />
      </View>

      {meta.length > 0 && (
        <View style={styles.tags}>
          {fields.workType ? <Tag icon="schedule" text={fields.workType} /> : null}
          {fields.salary ? <Tag icon="payments" text={fields.salary} /> : null}
        </View>
      )}

      <View style={styles.cardFooter}>
        {fields.address ? (
          <View style={styles.footerItem}>
            <MaterialIcons name="location-on" size={14} color={colors.textLight} />
            <Text style={styles.footerText} numberOfLines={1}>
              {fields.address}
            </Text>
          </View>
        ) : (
          <View style={{ flex: 1 }} />
        )}
        <Text style={styles.footerText}>{timeAgo(createdAt(job.data))}</Text>
      </View>
    </Pressable>
  );
}

function Tag({ icon, text }: { icon: 'schedule' | 'payments'; text: string }) {
  return (
    <View style={styles.tag}>
      <MaterialIcons name={icon} size={13} color={colors.primaryDark} />
      <Text style={styles.tagText} numberOfLines={1}>
        {text}
      </Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.background,
  },
  search: {
    height: 48,
    flexDirection: 'row',
    alignItems: 'center',
    borderRadius: 14,
    borderWidth: 1,
    borderColor: colors.divider,
    backgroundColor: colors.white,
  },
  searchInput: {
    flex: 1,
    height: '100%',
    fontFamily: fonts.regular,
    fontSize: 14,
    color: colors.textPrimary,
  },
  chip: {
    paddingHorizontal: 14,
    paddingVertical: 8,
    borderRadius: 20,
    borderWidth: 1,
    borderColor: colors.border,
    backgroundColor: colors.white,
  },
  chipActive: {
    borderColor: colors.primary,
    backgroundColor: colors.primary,
  },
  chipText: {
    fontFamily: fonts.semiBold,
    fontSize: 13,
    color: colors.textSecondary,
  },
  chipTextActive: {
    color: colors.white,
  },
  count: {
    ...typography.caption,
    marginTop: 12,
    fontSize: 12,
  },
  noResult: {
    alignItems: 'center',
    paddingVertical: 40,
  },
  card: {
    padding: 16,
    borderRadius: 16,
    backgroundColor: colors.white,
    shadowColor: '#000000',
    shadowOpacity: 0.05,
    shadowRadius: 10,
    shadowOffset: { width: 0, height: 3 },
    elevation: 2,
  },
  cardTop: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  cardIcon: {
    width: 44,
    height: 44,
    alignItems: 'center',
    justifyContent: 'center',
    borderRadius: 12,
    backgroundColor: '#6D4C41',
  },
  cardTitle: {
    fontFamily: fonts.bold,
    fontSize: 15,
    lineHeight: 20,
    color: colors.textPrimary,
  },
  cardEmployer: {
    ...typography.bodySmall,
    marginTop: 2,
  },
  tags: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 6,
    marginTop: 12,
  },
  tag: {
    maxWidth: '100%',
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    paddingHorizontal: 10,
    paddingVertical: 5,
    borderRadius: 8,
    backgroundColor: colors.primarySurface,
  },
  tagText: {
    fontFamily: fonts.medium,
    fontSize: 12,
    color: colors.primaryDark,
  },
  cardFooter: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    marginTop: 12,
    paddingTop: 10,
    borderTopWidth: 1,
    borderTopColor: colors.divider,
  },
  footerItem: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
  },
  footerText: {
    ...typography.caption,
    fontSize: 12,
  },
});
