import { useAllPlaces } from '@/features/home/home-queries';
import { GenericListScreen } from '@/screens/generic-list-screen';

export default function PlacesRoute() {
  return (
    <GenericListScreen title="Gezilecek Yerler" useQuery={useAllPlaces} routePrefix="places" cacheKey="places_cache" useGrid />
  );
}
