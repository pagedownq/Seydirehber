import { useAllEvents } from '@/features/home/home-queries';
import { GenericListScreen } from '@/screens/generic-list-screen';

export default function EventsRoute() {
  return <GenericListScreen title="Etkinlikler" useQuery={useAllEvents} routePrefix="events" cacheKey="events_cache" useGrid />;
}
