import { useAllPopularCompanies } from '@/features/home/home-queries';
import { GenericListScreen } from '@/screens/generic-list-screen';

export default function PopularCompaniesRoute() {
  return (
    <GenericListScreen
      title="En Çok Ziyaret Edilenler"
      useQuery={useAllPopularCompanies}
      routePrefix="companies"
      showViewCount
      cacheKey="companies_popular_cache"
    />
  );
}
