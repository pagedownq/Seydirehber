import { useLocalSearchParams } from 'expo-router';

import { EventDetailScreen } from '@/screens/event-detail-screen';

export default function EventDetailRoute() {
  const { id } = useLocalSearchParams<{ id: string }>();
  return <EventDetailScreen eventId={id} />;
}
