import { MaterialCommunityIcons, MaterialIcons } from '@expo/vector-icons';
import { ActivityIndicator, FlatList, Linking, Pressable, RefreshControl, StyleSheet, Text, View } from 'react-native';

import { AppBar, AppBarIconButton } from '@/components/app-bar';
import { contactName, contactPhone, useVefatList, type Vefat } from '@/features/vefat/vefat-query';
import { haptics } from '@/services/haptics';
import { colors, fonts, typography } from '@/theme';

// Flutter lib/features/services/screens/vefat_screen.dart karşılığı.
export function VefatScreen() {
  const { data, error, isPending, isRefetching, refetch } = useVefatList();

  let body;
  if (isPending) {
    body = (
      <View style={styles.center}>
        <ActivityIndicator size="large" color={colors.primary} />
        <Text style={[typography.bodyMedium, { marginTop: 16 }]}>Vefat ilanları yükleniyor...</Text>
      </View>
    );
  } else if (error) {
    body = (
      <View style={[styles.center, { padding: 32 }]}>
        <MaterialIcons name="error-outline" size={48} color="#F44336" />
        <Text style={[typography.bodyLarge, styles.centerText, { marginTop: 16 }]}>Veriler alınırken bir hata oluştu.</Text>
        <Text style={[typography.bodySmall, styles.centerText, { marginTop: 8 }]}>{error.message}</Text>
        <Pressable style={styles.retry} onPress={() => refetch()}>
          <Text style={typography.button}>Tekrar Dene</Text>
        </Pressable>
      </View>
    );
  } else if (!data || data.length === 0) {
    body = (
      <View style={styles.center}>
        <MaterialIcons name="info-outline" size={64} color="rgba(158, 158, 158, 0.5)" />
        <Text style={[typography.bodyMedium, { marginTop: 16, color: colors.textSecondary }]}>
          Yakın zamanda vefat ilanı bulunmamaktadır.
        </Text>
      </View>
    );
  } else {
    body = (
      <FlatList
        data={data}
        keyExtractor={(item, index) => `${item.name}-${item.date}-${index}`}
        contentContainerStyle={{ padding: 16 }}
        refreshControl={
          <RefreshControl
            refreshing={isRefetching}
            onRefresh={() => {
              refetch();
            }}
            colors={[colors.primary]}
            tintColor={colors.primary}
          />
        }
        renderItem={({ item }) => <VefatCard item={item} />}
        ListFooterComponent={<SourceFooter />}
      />
    );
  }

  return (
    <View style={styles.container}>
      <AppBar
        title="Vefat Edenler"
        titleColor={colors.textPrimary}
        centerTitle
        actions={
          <AppBarIconButton
            icon="refresh"
            onPress={() => {
              haptics.selection();
              refetch();
            }}
          />
        }
      />
      <View style={{ flex: 1 }}>{body}</View>
    </View>
  );
}

function VefatCard({ item }: { item: Vefat }) {
  const name = contactName(item);
  const phone = contactPhone(item);
  const contactColor = phone ? colors.primary : colors.textSecondary;

  return (
    <View style={styles.card}>
      <View style={styles.cardHeader}>
        <View style={{ flex: 1 }}>
          <Text style={[typography.heading3, styles.name]}>{item.name}</Text>
          {name ? (
            <Pressable
              disabled={!phone}
              style={styles.contactRow}
              onPress={async () => {
                haptics.selection();
                const url = `tel:${phone}`;
                try {
                  if (await Linking.canOpenURL(url)) await Linking.openURL(url);
                } catch {}
              }}>
              <MaterialCommunityIcons name="phone-outline" size={14} color={contactColor} />
              <Text
                style={[
                  typography.bodySmall,
                  { flexShrink: 1, color: contactColor, fontFamily: phone ? fonts.bold : fonts.medium },
                ]}>
                İletişim: {name}
                {phone ? ` (${phone})` : ''}
              </Text>
            </Pressable>
          ) : null}
        </View>
        <View style={styles.dateBadge}>
          <MaterialIcons name="calendar-today" size={12} color={colors.primary} />
          <Text style={styles.dateText}>Defin: {item.date}</Text>
        </View>
      </View>
      <Text style={styles.detail}>{item.detail}</Text>
      <View style={styles.divider} />
      <View style={styles.neighborhoodRow}>
        <MaterialCommunityIcons name="map-marker-outline" size={16} color={colors.textLight} />
        <Text style={[typography.bodySmall, { flex: 1, fontFamily: fonts.medium }]}>{item.neighborhood}</Text>
      </View>
    </View>
  );
}

function SourceFooter() {
  return (
    <View style={styles.footer}>
      <View style={styles.footerDivider} />
      <Text style={styles.footerText}>
        {'Bu veriler yasal gereği T.C. Seydişehir Belediyesi\nresmi web sitesinden anlık olarak alınmaktadır.'}
      </Text>
      <Text style={styles.footerSource}>Kaynak: www.seydisehir.bel.tr</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.background,
  },
  center: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
  centerText: {
    textAlign: 'center',
  },
  retry: {
    marginTop: 24,
    paddingHorizontal: 24,
    paddingVertical: 14,
    borderRadius: 12,
    backgroundColor: colors.primary,
  },
  card: {
    marginBottom: 16,
    padding: 20,
    borderRadius: 20,
    borderWidth: 1,
    borderColor: 'rgba(224, 224, 224, 0.5)',
    backgroundColor: colors.white,
  },
  cardHeader: {
    flexDirection: 'row',
    alignItems: 'flex-start',
  },
  name: {
    fontFamily: fonts.extraBold,
    color: '#1A3F6A',
  },
  contactRow: {
    marginTop: 6,
    paddingVertical: 2,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
  },
  dateBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    paddingHorizontal: 10,
    paddingVertical: 6,
    borderRadius: 10,
    backgroundColor: 'rgba(76, 175, 80, 0.08)',
  },
  dateText: {
    fontFamily: fonts.bold,
    fontSize: 10,
    color: colors.primary,
  },
  detail: {
    ...typography.bodyMedium,
    marginTop: 28,
    lineHeight: 21,
    color: 'rgba(27, 27, 27, 0.8)',
  },
  divider: {
    height: 1,
    marginTop: 20,
    marginBottom: 16,
    backgroundColor: colors.divider,
  },
  neighborhoodRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
  },
  footer: {
    paddingVertical: 24,
    alignItems: 'center',
  },
  footerDivider: {
    alignSelf: 'stretch',
    height: 1,
    marginBottom: 24,
    backgroundColor: colors.divider,
  },
  footerText: {
    ...typography.caption,
    lineHeight: 16.5,
    fontStyle: 'italic',
    textAlign: 'center',
  },
  footerSource: {
    ...typography.caption,
    marginTop: 8,
    fontFamily: fonts.bold,
    color: 'rgba(76, 175, 80, 0.5)',
  },
});
