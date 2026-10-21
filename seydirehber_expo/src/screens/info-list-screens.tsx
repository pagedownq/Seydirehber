import { MaterialIcons } from '@expo/vector-icons';
import type { ComponentProps } from 'react';
import { FlatList, StyleSheet, Text, View } from 'react-native';

import { AppBar } from '@/components/app-bar';
import { CachedImage } from '@/components/cached-image';
import { MapButton } from '@/components/map-button';
import { Shimmer } from '@/components/shimmer';
import type { FirestoreData, LiveQueryState } from '@/features/firestore/live-query';
import { useNoterler } from '@/features/home/home-queries';
import { colors, typography } from '@/theme';
import { str } from '@/utils/firestore-values';

// Flutter noterler_screen.dart karşılığı. (Pazarlar aynı kartı kullanıyordu; yeni tasarımı pazarlar-screen.tsx'te.)
type IconName = ComponentProps<typeof MaterialIcons>['name'];

export function NoterlerScreen() {
  return <InfoListScreen title="Noterler" state={useNoterler()} emptyText="Henüz noter eklenmemiş" showPhone />;
}

function InfoListScreen({
  title,
  state,
  emptyText,
  showPhone = false,
}: {
  title: string;
  state: LiveQueryState;
  emptyText: string;
  showPhone?: boolean;
}) {
  let body;
  if (state.status === 'loading') {
    body = (
      <View style={{ padding: 16, gap: 12 }}>
        {Array.from({ length: 3 }, (_, i) => (
          <Shimmer key={i} height={120} />
        ))}
      </View>
    );
  } else if (state.status === 'error') {
    body = <CenteredText text="Veriler yüklenemedi." />;
  } else if (state.docs.length === 0) {
    body = <CenteredText text={emptyText} />;
  } else {
    body = (
      <FlatList
        data={state.docs}
        keyExtractor={(item) => item.id}
        contentContainerStyle={{ padding: 16 }}
        ItemSeparatorComponent={() => <View style={{ height: 12 }} />}
        renderItem={({ item }) => <InfoCard data={item.data} showPhone={showPhone} />}
      />
    );
  }

  return (
    <View style={styles.container}>
      <AppBar title={title} />
      <View style={{ flex: 1 }}>{body}</View>
    </View>
  );
}

function CenteredText({ text }: { text: string }) {
  return (
    <View style={styles.center}>
      <Text style={typography.bodyMedium}>{text}</Text>
    </View>
  );
}

function InfoCard({ data, showPhone }: { data: FirestoreData; showPhone: boolean }) {
  const name = str(data.ad);
  const imageUrl = str(data.image_url, str(data.gorsel));
  const gunler = str(data.gunler);
  const telefon = str(data.telefon);
  const rawAdres = str(data.adres);
  const konum = str(data.konum);
  const adres = rawAdres || (konum.startsWith('http') ? '' : konum);

  return (
    <View style={styles.card}>
      {imageUrl ? <CachedImage imageUrl={imageUrl} width="100%" height={150} borderRadius={16} /> : null}
      <View style={styles.cardBody}>
        <Text style={typography.heading3}>{name}</Text>
        {gunler ? <InfoRow icon="schedule" text={gunler} /> : null}
        {showPhone && telefon ? <InfoRow icon="phone" text={telefon} /> : null}
        {adres ? <InfoRow icon="location-on" text={adres} numberOfLines={2} /> : null}
        {konum ? (
          <View style={{ marginTop: 12 }}>
            <MapButton locationUrl={konum} />
          </View>
        ) : null}
      </View>
    </View>
  );
}

function InfoRow({ icon, text, numberOfLines }: { icon: IconName; text: string; numberOfLines?: number }) {
  return (
    <View style={styles.infoRow}>
      <MaterialIcons name={icon} size={16} color={colors.primary} />
      <Text style={[typography.bodySmall, { flex: 1 }]} numberOfLines={numberOfLines}>
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
  center: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
  card: {
    borderRadius: 16,
    backgroundColor: colors.cardBackground,
    shadowColor: '#000000',
    shadowOpacity: 0.05,
    shadowRadius: 10,
    shadowOffset: { width: 0, height: 2 },
    elevation: 2,
  },
  cardBody: {
    padding: 14,
  },
  infoRow: {
    marginTop: 6,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
  },
});
