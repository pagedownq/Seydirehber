import { useLocalSearchParams } from 'expo-router';

import { PlaceDetailScreen } from '@/screens/place-detail-screen';

export default function PlaceDetailRoute() {
  const { id } = useLocalSearchParams<{ id: string }>();
  return <PlaceDetailScreen placeId={id} />;
}
